
local WIDTH = 80
local printer = {}
printer.__index = printer

printer.init = function (self, lib, song, tr)
  local o = {_lib=lib, _tempo=song.tempo}
  o._song = song
  o._triplet = lib:getTripletFeel(song)
  o._keyRoot = song.key
  o._keyType = 0
  o._signNum = 0
  o._signDenom = 0
  o._track = tr
  o._tuning = {}
  o._effects = {}
  o._chords = {}
  for i = 1, song.tracks[tr].strings do
    table.insert(o._tuning, song.tracks[tr].tuning[i])
  end

  return setmetatable(o, self)
end

printer.fuse = function (marks, strings, dur)
  local t = {marks}
  for i = 1, #strings do t[#t+1] = strings[i] end
  t[#t+1] = dur
  return t, #dur  
end

printer.head = function (self)
  local t = {}
  for _, v in ipairs(self._tuning) do
    t[#t+1] = self._lib:getStringNote(v) .. '|'
  end
  return printer.fuse('    ', t, 'dur ')
end

printer.signature = function (self, i, dst)
  local num, denom = self._lib:getSignature(self._song, i)
  if num and denom then
    local t = {}
    for i = 1, #self._tuning do t[#t+1] = '   :' end
    local j = (#t > 2) and 2 or 1    
    t[j] = string.format('%2d :', num)
    t[#t-j+1] = string.format('%2d :', denom)
    self._signNum, self._signDenom = num, denom
    -- update
    table.insert(dst[1], '    ')  -- marks
    local ds = dst[2]  -- strings
    for i = 1, #t do table.insert(ds[i], t[i]) end
    table.insert(dst[3], '    ')  -- duration
  end
end

printer.repeats = function (self, i, begin, dst)
  local flag = nil
  if begin then
    flag = self._lib:getRepeatBegin(self._song, i)   
  else
    flag = self._lib:getRepeatEnd(self._song, i)
  end
  if flag then
    local t = {}
    for i = 1, #self._tuning do t[#t+1] = begin and '!  ' or '  !' end
    local j = (#t > 2) and 2 or 1
    t[j] = begin and '!* ' or ' *!'
    t[#t-j+1] = begin and '!* ' or ' *!'
    local mark = begin and '   ' or string.format(' x%d', flag)
    -- update
    table.insert(dst[1], mark)  -- marks
    local ds = dst[2]  -- strings
    for i = 1, #t do table.insert(ds[i], t[i]) end
    table.insert(dst[3], '   ')  -- duration
  end
end

printer.alternates = function (self, i, dst)
  local alt = self._lib:getAlternate(self._song, i)
  if alt then
    table.insert(dst[1], string.format('[%d', alt))
    local ds = dst[2]
    for i = 1, #ds do table.insert(ds[i], '  ') end
    table.insert(dst[3], '  ')    
  end
end

printer.chords = function (self, bt)
  local name, ch = self._lib:getChord(bt)
  if ch then
    local key = ch .. name
    local val = self._chords[key]
    local ind = ''
    if val then
      ind = val[1]    
    else
      local n = 0
      for _ in pairs(self._chords) do n = n + 1 end
      ind = string.format('𝄝%-2d', n+1)    
      self._chords[key] = {ind, name, ch, n+1}
    end
    return ind    
  end
  return '   '
end

printer.measure = function (self, n)
  local m = #self._song.tracks * (n-1) + self._track
  local measure = self._song.measures[m]
  local beats = measure.voice[1]  -- TODO fix
  local str, dur, marks = {}, {}, {}
  for i = 1, #self._tuning do str[#str+1] = {} end
  -- check signature
  self:signature(n, {marks, str, dur})
  -- check first reprease
  self:repeats(n, true, {marks, str, dur})
  -- check alternates
  self:alternates(n, {marks, str, dur})
  -- check text
  local txt, n0 = {}, #table.concat(dur)+1
  -- notes
  for i, bt in ipairs(beats) do
    for j = 1, #self._tuning do
      local note = self._lib:getNoteAndEffect(bt, j)
      table.insert(str[j], note)
      self._effects[string.sub(note, 3)] = true
    end
    -- beat duration
    dur[#dur+1] = self._lib:getDuration(bt)
    -- collect chords
    marks[#marks+1] = self:chords(bt)
    -- collect texts
    local t = self._lib:getText(bt)
    if t then txt[#txt+1] = {n0 + 3*(i-1), t} end
  end
  -- check second reprease
  self:repeats(n, false, {marks, str, dur})
  -- to text
  for i = 1, #str do
    table.insert(str[i], '|')
    str[i] = table.concat(str[i])
  end
  dur[#dur+1] = ' '
  marks[#marks+1] = ' '
  local combo, len = printer.fuse(table.concat(marks), str, table.concat(dur))
  return combo, len, txt
end

printer.listEffects = function (self)
  local map = require('src.mapping')
  local t = {}
  for k, v in pairs(map.effects) do
    if self._effects[v] then t[#t+1] = string.format('%s %s', v, k) end
  end
  return t  
end

printer.showText = function (ps)
  local prev, acc = 1, {}
  for _, p in ipairs(ps) do
    local n = p[1]-1
    for i = prev, n do acc[i] = ' ' end
    for i = 1, #p[2] do acc[i+n] = string.sub(p[2], i, i) end
    prev = n + #p[2] + 1
  end
  print()
  if #acc > 0 then 
    print(table.concat(acc))
  end
end

printer.listChords = function (self)
  local t = {}
  for _, v in pairs(self._chords) do t[#t+1] = v end
  table.sort(t, function (a, b) return b[4] > a[4] end)
  return t
end

printer.print = function (self)
  local line, total, acc = {}, 0, {}
  local newline = true
  
  for i = 1, #self._song.measureHeaders do
    local measure, n, ps = self:measure(i)
    if total + n > WIDTH then
      printer.showText(acc)
      for _, txt in ipairs(line) do print(txt) end
      line, total, acc = {}, 0, {}
      newline = true
    end
    if newline then
      -- show head      
      local head, k = self:head()
      head[1] = string.format('%3d ', i)
      total = k
      for i, v in ipairs(head) do line[i] = v end
      newline = false
    end
    -- show notes
    for i, v in ipairs(measure) do
      line[i] = line[i] and (line[i] .. v) or v
    end
    -- text line
    if #ps > 0 then
      for _, v in ipairs(ps) do
        v[1] = v[1] + total
        acc[#acc+1] = v
      end
    end
    total = total + n
  end
  if total > 0 then
    printer.showText(acc)
    for _, txt in ipairs(line) do print(txt) end
  end
  -- chords
  local chords = self:listChords()
  if #chords > 0 then
    print('\nChords')
    for _, v in ipairs(chords) do
      print(v[1], v[2], v[3])
    end
  end
  -- notations
  local efs = self:listEffects()
  if #efs > 0 then 
    print('\nNotation')
    for i = 1, #efs, 4 do
      local t = {}
      for j = 1, 4 do t[j] = efs[i+j-1] end
      print(table.concat(t, '\t '))
    end
  end
end

local utils = require('src.utils')
local f = utils.read(arg[1])
local ver = utils.version(f)
local lib = require('src.gp'..ver)

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
  print('Key:', lib:getKeySignName(song.key, 0))
  print('Tempo:', song.tempo, lib:getTripletFeel(song) and '(triplet feel)' or '')  

  local pr = printer:init(lib, song, n)
  pr:print()

end

