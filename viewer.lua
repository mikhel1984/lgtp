#!/usr/local/bin/lua
--[[  viewer.lua

Parse gtp files, print result in console.

Usage:
  ./viewer.lua file_name             # show content
  ./viewer.lua file_name track_name  # show tab

2024, Stanilav Mikhel]]

local WIDTH = 80  -- 'page' width

local viewer = {}
viewer.__index = viewer

viewer.init = function (self, lib, song, tr)
  local o = {_lib=lib, _tempo=song.tempo}
  o._song = song
  o._single = lib._version < '5.00'
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

viewer.fuse = function (marks, strings, dur)
  local t = {marks}
  for i = 1, #strings do t[#t+1] = strings[i] end
  for i = 1, #dur do t[#t+1] = dur[i] end
  return t, #marks
end

viewer.head = function (self)
  local t = {}
  for _, v in ipairs(self._tuning) do
    t[#t+1] = self._lib:getStringNote(v) .. '|'
  end
  if self._single then
    return viewer.fuse('    ', t, {'dur '})
  else
    return viewer.fuse('    ', t, {'dur ', 'dur2'})
  end
end

viewer.signature = function (self, i, dst)
  local num, denom = self._lib:getSignature(self._song, i)
  if num or denom then
    num = num or self._signNum
    denom = denom or self._signDenom
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
    local dur = dst[3]  -- duration
    for i = 1, #dur do table.insert(dur[i], '    ') end
  end
end

viewer.repeats = function (self, i, begin, dst)
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
    local dur = dst[3]  -- duration
    for i = 1, #dur do table.insert(dur[i], '   ') end
  end
end

viewer.alternates = function (self, i, dst)
  local alt = self._lib:getAlternate(self._song, i)
  if alt then
    table.insert(dst[1], string.format('[%d', alt))
    local ds = dst[2]
    for i = 1, #ds do table.insert(ds[i], '  ') end
    local dur = dst[3]  -- duration
    for i = 1, #dur do table.insert(dur[i], '  ') end
  end
end

viewer.chords = function (self, bt)
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

viewer.alignDurations = function (self, durs)
  local acc = {}
  for i, v in ipairs(durs) do
    local sum = 0
    for j, t in ipairs(v) do
      -- t = {num, denom}
      local x = (100.0*t[1]) / t[2]
      sum = sum + x
      if j < #v then
        acc[#acc+1] = {sum, i, j+1}  -- time, voice, beat
      end
    end
  end
  table.sort(acc, function (a, b) return b[1] > a[1] end)
  local res = {{1, 1}}
  for i = 1, #acc do
    local curr, prev = acc[i], acc[i-1]
    if not prev or curr[1]-prev[1] > 0.1 then  -- new bit
      res[#res+1] = {[curr[2]] = curr[3]}
    else                           -- same bit
      res[#res][curr[2]] = curr[3]
    end
  end
  return res
end

viewer.voices = function (self, beats, n, dst)
  -- dst: {marks, strings, duration, text, times}
  local str, dur, marks, txt = {}, {}, {}, {}
  local time = {}
  for i = 1, n do str[i] = {} end
  for i, bt in ipairs(beats) do
    -- strings
    for j = 1, n do
      local note = self._lib:getNoteAndEffect(bt, j)
      table.insert(str[j], note)
      self._effects[string.sub(note, 3)] = true
    end
    -- beat duration
    dur[i], time[i] = self._lib:getDuration(bt)
    -- chords
    marks[i] = self:chords(bt)
    -- text
    txt[i] = self._lib:getText(bt)
  end
  table.move(marks, 1, #marks, #dst[1]+1, dst[1])
  table.move(dur, 1, #dur, #dst[3]+1, dst[3])
  table.move(txt, 1, #beats, #dst[4]+1, dst[4])
  table.move(time, 1, #time, #dst[5]+1, dst[5])
  for i, s in ipairs(str) do table.move(s, 1, #s, #dst[2][i]+1, dst[2][i]) end
  return #beats
end

viewer.multiVoices = function (self, measure, n, dst)
  local lstStr, lstDur, lstMarks = {{}, {}}, {{}, {}}, {{}, {}}
  local lstText, lstTime = {{}, {}}, {{}, {}}
  -- collect data
  for i = 1, 2 do
    for j = 1, n do lstStr[i][j] = {} end
    self:voices(measure.voice[i], n,
      {lstMarks[i], lstStr[i], lstDur[i], lstText[i], lstTime[i]})
  end
  -- align
  local seq = viewer:alignDurations(lstTime)
  -- new
  local marks, str, dur, txt = {}, {}, {{}, {}}, {}
  for i = 1, n do str[i] = {} end
  for i, grp in ipairs(seq) do
    local b1, b2 = grp[1], grp[2]
    -- marks
    marks[i] = lstMarks[1][b1] or lstMarks[2][b2]
    -- durations
    dur[1][i] = lstDur[1][b1] or '   '
    dur[2][i] = lstDur[2][b2] or '   '
    -- strings
    for j = 1, n do
      local s1 = lstStr[1][j][b1]
      local s2 = lstStr[2][j][b2]
      str[j][i] = (s1 and s2 and (s1 == '---' and s2 or s1)) or s1 or s2
    end
    -- text
    txt[i] = lstText[1][b1] or lstText[2][b2]
  end
  table.move(marks, 1, #marks, #dst[1]+1, dst[1])
  table.move(txt, 1, #seq, #dst[4]+1, dst[4])
  for i, s in ipairs(str) do table.move(s, 1, #s, #dst[2][i]+1, dst[2][i]) end
  for i, d in ipairs(dur) do table.move(d, 1, #d, #dst[3][i]+1, dst[3][i]) end
  return #seq
end

viewer.splitConcat = function (self, dst)
  -- marks
  table.insert(dst[1], ' ')
  local marks = table.concat(dst[1])
  -- strings
  local str = dst[2]
  for i = 1, #str do
    table.insert(str[i], '|')
    str[i] = table.concat(str[i])
  end
  -- durations
  local dur = dst[3]  -- duration
  for i = 1, #dur do
    table.insert(dur[i], ' ')
    dur[i] = table.concat(dur[i])
  end
  return marks, str, dur
end

viewer.compressText = function (self, txt, n, n0)
  local res = {}
  for i = 1, n do
    if txt[i] then
      res[#res+1] = {n0 + 3*(i-1), txt[i]}
    end
  end
  return res
end

viewer.measure = function (self, n)
  local m = #self._song.tracks * (n-1) + self._track
  local measure = self._song.measures[m]
  local str, marks = {}, {}
  local dur = self._single and {{}} or {{}, {}}
  for i = 1, #self._tuning do str[i] = {} end
  -- check signature
  self:signature(n, {marks, str, dur})
  -- check first reprease
  self:repeats(n, true, {marks, str, dur})
  -- check alternates
  self:alternates(n, {marks, str, dur})
  -- save texts
  local txt, n0, nf = {}, #table.concat(marks)+1, 0
  if self._single then
    nf = self:voices(measure.voice[1], #self._tuning, {marks, str, dur[1], txt, {}})
  else
    nf = self:multiVoices(measure, #self._tuning, {marks, str, dur, txt})
  end
    -- check second reprease
  self:repeats(n, false, {marks, str, dur})
  -- to text
  marks, str, dur = self:splitConcat({marks, str, dur})
  local combo, len = viewer.fuse(marks, str, dur)
  return combo, len, self:compressText(txt, nf, n0)
end

viewer.listEffects = function (self)
  local map = require('src.mapping')
  local t = {}
  for k, v in pairs(map.effects) do
    if self._effects[v] then t[#t+1] = string.format('%s %s', v, k) end
  end
  return t
end

viewer.showText = function (ps)
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

viewer.listChords = function (self)
  local t = {}
  for _, v in pairs(self._chords) do t[#t+1] = v end
  table.sort(t, function (a, b) return b[4] > a[4] end)
  return t
end

viewer.print = function (self)
  local line, total, acc = {}, 0, {}
  local newline = true

  for i = 1, #self._song.measureHeaders do
    local measure, n, ps = self:measure(i)
    if total + n > WIDTH then
      viewer.showText(acc)
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
    viewer.showText(acc)
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

  local pr = viewer:init(lib, song, n)
  pr:print()

end

