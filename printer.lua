
local printer = {}
printer.__index = printer

printer.init = function (self, lib, song)
  local o = {lib=lib, tempo=song.tempo}
  o.triplet = lib:getTripletFeel(song)
  o.keyRoot = song.key
  o.keyType = 0

  return setmetatable(o, self)
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

end

