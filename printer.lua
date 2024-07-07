
local printer = {}
printer.__index = printer

printer.init = function (self, lib, song, tr)
  local o = {_lib=lib, _tempo=song.tempo}
  o._song = song
  o._triplet = lib:getTripletFeel(song)
  o._keyRoot = song.key
  o._keyType = 0
  o._track = tr
  o._tuning = {}
  for i = 1, song.tracks[tr].strings do
    table.insert(o._tuning, song.tracks[tr].tuning[i])
  end

  return setmetatable(o, self)
end

printer.measure = function (self, n)
  local m = #self._song.tracks * (n-1) + self._track
  local measure = self._song.measures[m]
  local beats = measure.voice[1]  -- TODO fix
  local s, dur = {}, {}
  for i = 1, #self._tuning do s[#s+1] = {} end
  for i, bt in ipairs(beats) do
    for j = 1, #self._tuning do
      table.insert(s[j], printer:beat(bt, j))
    end
    dur[#dur+1] = self._lib:getDuration(bt)
  end
  -- to text
  local t = {}
  for i = 1, #s do
    table.insert(s[i], '|')
    t[i] = table.concat(s[i])
  end
  dur[#dur+1] = ' '
  t[#t+1] = table.concat(dur)
  return t, 3 * #beats
end

printer.beat = function (self, bt, i)
  local note = bt.notes[i]
  if not note then
    return '---'
  elseif note.ghostNote then
    return ' x '
  elseif note.fret then
    local templ = (note.fret < 10) and ' %d ' or '%d '
    return string.format(templ, note.fret)
  end
end

printer.print = function (self)
  local line = {n=0}
  for i = 1, #self._song.measureHeaders do
    local measure, n = self:measure(i)
    if line.n + n > 80 then
      for _, txt in ipairs(line) do print(txt) end
      print('')
      line = {n=0}
    end
    for i, v in ipairs(measure) do
      line[i] = line[i] and (line[i] .. v) or v
    end
    line.n = line.n + n
  end
  if line.n > 0 then
    for _, txt in ipairs(line) do print(txt) end
  end
end

local utils = require('utils')
local f = utils.read(arg[1])
local ver = utils.version(f)
local lib = require('gp'..ver)

local song = lib:readSong(f)

if not arg[2] then
  -- show info and exit
  local info = song.info
  print('Title:', info.title)
  print('Artist:', info.artist)
  print('Album:', info.album)
  if info.notice and #info.notice > 0 then
    print('\nNotices')
    for _, v in ipairs(info.notice) do
      print(' - ' .. v)
    end
  end
  print('\nTracks')
  for i, t in ipairs(song.tracks) do
    print(string.format(' %d. %s [%s]', i, t.name, lib:getInstrument(song, i)))
  end

else
  -- specific track
  local n = assert(tonumber(arg[2]), 'Expected track number')
  if n < 1 or n > #song.tracks then
    error('Expected number between 1 and '..tonumber(#song.tracks))
  end
  print('', song.info.title)
  print(string.format('%s [%s]', song.tracks[n].name, lib:getInstrument(song, n)))
  print('Tempo:', song.tempo, lib:getTripletFeel(song) and '(triplet feel)' or '')
  print('Key:', lib:getKeySignName(song.key, 0))

  local pr = printer:init(lib, song, n)
  pr:print()

end

