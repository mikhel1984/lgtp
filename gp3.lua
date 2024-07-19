--[[  gp3.lua

GuitarPro v3 tab parser.

2024, Stanislav Mikhel ]]

local utils = require('utils')
local mapping = require('mapping')


local gp3 = {}

gp3.readSong = function (self, s)
  local data = utils.data:init(s)
  local ver = data:bstring()
  self._version = string.sub(ver, 21, 24)
  -- expected 30 byte intro
  if data.pos < 32 then data.pos = 32 end
  local song = {}
  song.info    = self:readInfo(data)
  song.triplet = data:bool()
  song.tempo   = data:int()
  song.key     = data:int()
  song.midi    = self:readMidiChannels(data)
  local measures = data:int()
  local tracks   = data:int()
  song.measureHeaders = {}
  for i = 1, measures do
    song.measureHeaders[i] = self:readMeasureHeader(data)
  end
  song.tracks = {}
  for i = 1, tracks do
    song.tracks[i] = self:readTrack(data)
  end
  song.measures = {}
  for i = 1, measures do
    -- print('measure', i)
    song.measures[i] = self:readMeasure(data)
  end
  return song
end

gp3.readInfo = function (self, data)
  local info = {}
  info.title     = data:ibstring()
  info.subtitle  = data:ibstring()
  info.artist    = data:ibstring()
  info.album     = data:ibstring()
  info.words     = data:ibstring()
  info.copyright = data:ibstring()
  info.tab       = data:ibstring()
  info.instructions = data:ibstring()
  local ns       = data:int()
  info.notice = {}
  for i = 1, ns do
    info.notice[i] = data:ibstring()
  end
  return info
end

gp3.readMidiChannels = function (self, data)
  local channel = {}
  for i = 1, 4 do     -- 4 ports
    for j = 1, 16 do  -- 16 channels in each port
      local ch = {}
      ch.instrument = data:int()
      ch.volume     = data:byte()
      ch.balance    = data:byte()
      ch.chorus     = data:byte()
      ch.revebr     = data:byte()
      ch.phaser     = data:byte()
      ch.tremolo    = data:byte()
      data:skip(2)  -- blank bytes
      channel[#channel+1] = ch
    end
  end
  return channel
end

gp3.readMeasureHeader = function (self, data)
  local flags = data:byte()
  local measure = {}
  if flags & 0x01 ~= 0 then measure.numerator = data:sbyte() end
  if flags & 0x02 ~= 0 then measure.denominator = data:sbyte() end
  if flags & 0x04 ~= 0 then measure.repeatBeg = true end
  if flags & 0x08 ~= 0 then measure.repeatNo  = data:sbyte() end
  if flags & 0x10 ~= 0 then measure.alternate = data:byte() end
  if flags & 0x20 ~= 0 then measure.marker    = self:readMarker(data) end
  if flags & 0x40 ~= 0 then
    measure.keyRoot = data:byte()
    measure.keyType = data:byte()
  end
  if flags & 0x80 ~= 0 then measure.doubleBar = true end
  return measure
end

gp3.readMarker = function (self, data)
  local marker = {}
  marker.name  = data:ibstring()
  marker.color = data:color()
  return marker
end

gp3.readTrack = function (self, data)
  local track = {}
  local flags = data:byte()
  if flags & 0x01 ~= 0 then track.drums = true end
  if flags & 0x02 ~= 0 then track.string12 = true end
  if flags & 0x04 ~= 0 then track.banjo = true end
  local prev = data.pos
  track.name = data:bstring()
  data.pos   = prev + 41  -- expected 40 bytes string
  track.strings = data:int()
  local tuning = {}
  for i = 1, 7 do
    tuning[i] = data:int()
  end
  track.tuning = tuning
  track.midiPort = data:int()
  track.channel = self:readChannel(data)
  track.frets   = data:int()
  track.capo    = data:int()
  track.color   = data:color()
  return track
end

gp3.readChannel = function (self, data)
  local i1 = data:int()
  local i2 = data:int()
  return {i1, i2}
end

gp3.readVoice = function (self, data)
  local n = data:int()
  local beats = {}
  for i = 1, n do
    -- print('beat', i)
    beats[i] = self:readBeat(data)
  end
  return beats
end

gp3.readMeasure = function (self, data)
  local measure = {voice={}}
  measure.voice[1] = self:readVoice(data)
  return measure
end

gp3.readBeat = function (self, data)
  local flags = data:byte()
  local beat = {}
  if flags & 0x40 ~= 0 then
    local tmp = data:byte()
    if tmp == 0 then
      beat.empty = true
    elseif tmp == 0x02 then
      beat.rest = true
    end
  end
  if flags & 0x01 ~= 0 then beat.dotted = true end
  beat.duration = data:sbyte()
  if flags & 0x20 ~= 0 then beat.tuplet  = data:int() end
  if flags & 0x02 ~= 0 then beat.chord   = self:readChord(data) end
  if flags & 0x04 ~= 0 then beat.text    = data:ibstring() end
  if flags & 0x08 ~= 0 then beat.effects = self:readBeatEffects(data) end
  if flags & 0x10 ~= 0 then beat.mixTableChange = self:readMixTable(data) end
  beat.notes = self:readNotes(data)
  return beat
end

gp3.readChord = function (self, data)
  local flag = data:byte()
  if flag == 0 then
    return self:readOldChord(data)
  else
    return self:readNewChord(data)
  end
end

gp3.readOldChord = function (self, data)
  local chord = {new=false}
  chord.name  = data:ibstring()
  chord.first = data:int()
  local str = {}
  if chord.first > 0 then
    for i = 1, 6 do
      str[i] = data:int()
    end
  end
  chord.string = str
  return chord
end

gp3.readNewChord = function (self, data)
  local chord = {new=true}
  chord.sharp = data:bool()
  data:skip(3)  -- blank bytes
  chord.root  = data:int()
  chord.type  = data:int()
  chord.extention = data:int()
  chord.bass  = data:int()
  chord.tonality = data:int()
  chord.add   = data:bool()
  local prev = data.pos
  chord.name  = data:bstring()
  data.pos = prev + 23  -- 22 bytes length
  chord.alt5  = data:int()
  chord.alt9  = data:int()
  chord.alt11 = data:int()
  chord.first = data:int()
  local str = {}
  for i = 1, 6 do
    str[i] = data:int()
  end
  chord.string = str
  -- barre
  local bar = {frets={}, start={}, ends={}}
  bar.len = data:int()
  for i = 1, 2 do
    bar.frets[i] = data:int()
  end
  for i = 1, 2 do
    bar.start[i] = data:int()
  end
  for i = 1, 2 do
    bar.ends[i]  = data:int()
  end
  -- rest
  chord.omission = {}
  for i = 1, 7 do
    chord.omission[i] = data:bool()
  end
  data:skip(1)
  return chord
end

gp3.readBeatEffects = function (self, data)
  local efs = data:byte()
  local effects = {flags1=efs}
  if efs & 0x20 ~= 0 then
    local tmp = data:byte()
    if tmp == 0 then
      effects.tremoloBar = self:readTremoloBar(data)
    else
      effects.slap = tmp
      data:skip(4)  -- int
    end
  end
  if efs & 0x40 ~= 0 then
    local up   = data:sbyte()
    local down = data:sbyte()
    effects.beatStroke = {up, down}
  end
  return effects
end

gp3.readTremoloBar = function (self, data)
  local v = data:int()
  return {dip=v}
end

gp3.readMixTable = function (self, data)
  local val = self:readMixTableValues(data)
  return self:readMixTableDurations(data, val)
end

gp3.readMixTableValues = function (self, data)
  local val, tmp = {}, 0
  tmp = data:sbyte()
  if tmp >= 0 then val.instrument = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.volume = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.balance = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.chorus = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.revebr = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.phaser = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.tremolo = tmp end
  tmp = data:int()
  if tmp >= 0 then val.tempo = tmp end
  return val
end

gp3.readMixTableDurations = function (self, data, t)
  if t.volume  then t.volumeDur  = data:sbyte() end
  if t.balance then t.balanceDur = data:sbyte() end
  if t.chorus  then t.chorusDur  = data:sbyte() end
  if t.revebr  then t.reverbDur  = data:sbyte() end
  if t.phaser  then t.phaserDur  = data:sbyte() end
  if t.tremolo then t.tremoloDur = data:sbyte() end
  if t.tempo   then t.tempoDur   = data:sbyte() end
  return t
end

gp3.readNotes = function (self, data)
  local flags = data:byte()
  local notes = {}
  for i = 1, 7 do
    if flags & (1 << (7-i)) ~= 0 then
      -- strings in inverse order
      notes[i] = self:readNote(data)
    end
  end
  return notes
end

gp3.readNote = function (self, data)
  local flags= data:byte()
  local note = {}
  if flags & 0x04 ~= 0 then note.ghostNote = true end
  if flags & 0x20 ~= 0 then note.type = data:byte() end
  if flags & 0x01 ~= 0 then
    note.duration = data:sbyte()
    note.tuplet   = data:sbyte()
  end
  if flags & 0x10 ~= 0 then note.velocity = data:sbyte() end
  if flags & 0x20 ~= 0 then
    note.fret = data:sbyte()
  end
  if flags & 0x80 ~= 0 then
    local left  = data:sbyte()
    local right = data:sbyte()
    note.effectFinger = {left, right}
  end
  if flags & 0x08 ~=0 then note.effect = self:readNoteEffect(data) end
  return note
end

gp3.readNoteEffect = function (self, data)
  local flags = data:byte()
  local effects = {}
  if flags & 0x02 ~= 0 then effects.hammer = true end
  if flags & 0x08 ~= 0 then effects.letRing = true end
  if flags & 0x01 ~= 0 then effects.bend   = self:readBend(data) end
  if flags & 0x10 ~= 0 then effects.grace  = self:readGrace(data) end
  if flags & 0x04 ~= 0 then effects.slides = self:readSlides(data) end
  return effects
end

gp3.readBend = function (self, data)
  local bend = {}
  bend.type  = data:sbyte()
  bend.value = data:int()
  local points = data:int()
  for i = 1, points do
    local pt = {}
    pt.position = data:int()
    pt.value    = data:int()
    pt.vibrato  = data:bool()
    bend[i] = pt
  end
  return bend
end

gp3.readGrace = function (self, data)
  local grace = {}
  grace.fret     = data:sbyte()
  grace.velocity = data:byte()
  grace.duration = data:byte()
  grace.transition = data:sbyte()
  return grace
end

gp3.readSlides = function (self, data) return {} end

--========================================

gp3.getInstrument = function (self, song, n)
  local track = song.tracks[n]
  local index = track.channel[1]
  local instrument = song.midi[index].instrument
  return mapping.instruments[instrument] or ''
end

gp3.getTripletFeel = function (self, song)
  return song.triplet
end

gp3.getKeySignName = function (self, root, tp)
  tp = tp + 1  -- [0,1] to [1,2]
  return mapping.keySignature[tp][root] .. (tp == 1 and ' major' or ' minor')
end

gp3.getDuration = function (self, beat)
  local dur = nil
  if beat.duration > 2 and not beat.dotted then
    -- use ' to define duration
    dur = mapping.duration[-beat.duration]
  else  -- use numbers
    dur = (mapping.duration[beat.duration] or '  ') .. (beat.dotted and '.' or ' ')
  end
  -- mark tuplets
  if beat.tuplet and string.find(dur, '|') then
    return string.gsub(dur, '|', string.format('%x', beat.tuplet))  
  end
  return dur
end

gp3.getStringNote = function (self, v)
  local note = v % 12
  return mapping.string[note+1] .. tostring(v // 12)
end

gp3.getSignature = function (self, song, m)
  local head = song.measureHeaders[m]
  return head.numerator, head.denominator
end

gp3.getNoteAndEffect = function (self, bt, i)
  local note = bt.notes[i]
  if not note then 
    return '---'
  elseif note.type == 3 then
    return ' x ' 
  end
  local effect = ' '
  if note.ghostNote then effect = ')'
  elseif bt.effects then
    local ect = bt.effects.flags1
    if     ect & 0x04 ~= 0 then effect = '*'  -- natural harmonic
    elseif ect & 0x08 ~= 0 then effect = 'A'  -- artifitial harmonic
    elseif ect & 0x01 ~= 0 then effect = '~'  -- vibrato
    elseif ect & 0x10 ~= 0 then effect = '<'  -- fade in
    elseif bt.effects.slap then
      local key = {'T', 'S', 'P'}     -- tapping, slap, pop
      effect = key[bt.effects.slap]
    end
  elseif note.effect then
    local ect = note.effect
    if     ect.letRing then effect = 'L'  -- let ring
    elseif ect.hammer  then effect = 'h'  -- hammer
    elseif ect.bend    then effect = '^'  -- bend
    elseif ect.slides  then effect = '/'  -- slide
    end
  end
  return string.format('%2d%s', note.fret, effect)
end

return gp3

--local bin = utils.read(arg[1])
--gp3:readSong(bin)
