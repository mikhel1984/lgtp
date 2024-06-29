--[[  gp5.lua

GuitarPro v5 tab parser.

2024, Stanislav Mikhel ]]

local utils = require('utils')
local gp4 = require('gp4')


local gp5 = {}
-- inheritance
setmetatable(gp5, {__index = gp4})

gp5.readSong = function (self, s)
  local data = utils.data:init(s)
  local ver = data:bstring()
  self._version = string.sub(ver, 21, 24)
  -- print(self._version)
  -- expected 30 byte intro
  if data.pos < 32 then data.pos = 32 end
  local song = {}
  if string.find(ver, '^CLIPBOARD') then
    self._version = string.sub(ver, 14, 17) .. '0'
    -- print('new version', self._version)
    song.clipboard  = self:readClipboard(data)
  end
  song.info         = self:readInfo(data)
  song.lyrics       = self:readLyrics(data)
  song.masterEffect = self:readRSEMasterEffect(data)
  song.pageSetup    = self:readPageSetup(data)
  song.tempoName    = data:ibstring()
  song.tempo        = data:int()
  if self._version > '5.00' then
    song.hideTempo  = data:bool()
  end
  song.key          = data:sbyte()
  data:skip(4)
  song.midi         = self:readMidiChannels(data)
  local directions  = self:readDirections(data)
  song.reverb       = data:int()
  local measures    = data:int()
  local tracks      = data:int()
  -- print(measures, tracks)
  song.measureHeader = {}
  for i = 1, measures do
    song.measureHeader[i] = self:readMeasureHeader(data, i)
  end
  song.tracks = {}
  for i = 1, tracks do
    song.tracks[i]  = self:readTrack(data, i)
  end
  data:skip(self._version == '5.00' and 2 or 1)
  song.measures = {}
  for i = 1, measures do
    -- print('measure', i)
    song.measures[i] = self:readMeasure(data)
  end
  return song
end

gp5.readClipboard = function (self, data)
  local cb = gp4.readClipboard(self, data)
  cb.startBeat = data:int()
  cb.stopBeat  = data:int()
  cb.subBarCpy = data:int()
  return cb
end

gp5.readInfo = function (self, data)
  local info = {}
  info.title    = data:ibstring()
  info.subtitle = data:ibstring()
  info.artist   = data:ibstring()
  info.album    = data:ibstring()
  info.words    = data:ibstring()
  info.music    = data:ibstring()
  info.copyright = data:ibstring()
  info.tab      = data:ibstring()
  info.instructions = data:ibstring()
  info.notice = {}
  local cnt = data:int()
  for i = 1, cnt do
    info.notice[i] = data:ibstring()
  end
  return info
end

gp5.readRSEMasterEffect = function (self, data)
  local effect = {}
  if self._version > '5.00' then
    effect.volume = data:int()
    data:skip(4)
    effect.equalizer = {}
    for i = 1, 11 do
      effect.equalizer[i] = data:sbyte()
    end
  end
  return effect
end

gp5.readPageSetup = function (self, data)
  local setup = {}
  setup.width  = data:int()
  setup.height = data:int()
  setup.left   = data:int()
  setup.right  = data:int()
  setup.top    = data:int()
  setup.bottom = data:int()
  setup.proportion = data:int()
  setup.header = data:short()
  setup.title  = data:ibstring()
  setup.subtitle = data:ibstring()
  setup.artist = data:ibstring()
  setup.album  = data:ibstring()
  setup.words  = data:ibstring()
  setup.music  = data:ibstring()
  setup.wordsMusic = data:ibstring()
  setup.copyright1 = data:ibstring()
  setup.copyright2 = data:ibstring()
  setup.pageNum    = data:ibstring()
  return setup
end

gp5.readDirections = function (self, data)
  local signs, from = {}, {}
  signs['Coda']        = data:short()
  signs['Double Coda'] = data:short()
  signs['Segno']       = data:short()
  signs['Segno Segno'] = data:short()
  signs['Fine']        = data:short()
  from['Da Capo']      = data:short()
  from['Da Capo al Coda']        = data:short()
  from['Da Capo al Double Coda'] = data:short()
  from['Da Capo al Fine']        = data:short()
  from['Da Segno']               = data:short()
  from['Da Segno al Coda']       = data:short()
  from['Da Segno al Double Coda'] = data:short()
  from['Da Segno al Fine']       = data:short()
  from['Da Segno Segno']         = data:short()
  from['Da Segno Segno al Coda'] = data:short()
  from['Da Segno Segno al Double Coda'] = data:short()
  from['Da Segno Segno al Fine'] = data:short()
  from['Da Coda']        = data:short()
  from['Da Double Coda'] = data:short()
  return {signs=signs, fromSigns=from}
end

gp5.readMeasureHeader = function (self, data, k)
  local measure = {}
  if k > 1 then
    data:skip(1)
  end
  local flags = data:byte()
  if flags & 0x80 ~= 0 then measure.doubleBar = true end
  if flags & 0x01 ~= 0 then
    measure.numerator = data:sbyte()
  end
  if flags & 0x02 ~= 0 then
    measure.denominator = data:sbyte()
  end
  if flags & 0x04 ~= 0 then measure.repeatBeg = true end
  if flags & 0x08 ~= 0 then
    measure.repeatNo = data:sbyte()
  end
  if flags & 0x20 ~= 0 then
    measure.marker    = self:readMarker(data)
  end
  if flags & 0x40 ~= 0 then
    measure.keyRoot   = data:sbyte()
    measure.keyType   = data:sbyte()
  end
  if flags & 0x10 ~= 0 then
    measure.alternate = data:byte()
  end
  if flags & 0x03 ~= 0 then
    measure.beam = {}
    for i = 1, 4 do
      measure.beam[i] = data:byte()
    end
  end
  if flags & 0x10 == 0 then
    data:skip(1)
  end
  measure.triplet = data:byte()
  return measure
end

gp5.readTrack = function (self, data, k)
  local track = {}
  if k == 1 or self._version == '5.00' then data:skip(1) end
  local flags1 = data:byte()
  if flags1 & 0x01 ~= 0 then track.drums = true end
  if flags1 & 0x02 ~= 0 then track.string12 = true end
  if flags1 & 0x04 ~= 0 then track.banjo = true end
  if flags1 & 0x08 ~= 0 then track.visible = true end
  if flags1 & 0x10 ~= 0 then track.solo = true end
  if flags1 & 0x20 ~= 0 then track.mute = true end
  if flags1 & 0x40 ~= 0 then track.rseUse = true end
  if flags1 & 0x80 ~= 0 then track.indicateTuning = true end
  local prev = data.pos
  track.name = data:bstring()
  data.pos = prev + 41  -- expected 40 bytes
  track.strings = data:int()
  local tuning = {}
  for i = 1, 7 do
    tuning[i] = data:int()
  end
  track.tuning = tuning
  track.midiPort = data:int()
  track.channel  = self:readChannel(data)
  track.frets    = data:int()
  track.capo     = data:int()
  track.color    = data:color()
  local settings = {}
  local flags2   = data:short()
  if flags2 & 0x0001 ~= 0 then settings.tabulature = true end
  if flags2 & 0x0002 ~= 0 then settings.notation = true end
  if flags2 & 0x0004 ~= 0 then settings.diagramsBelow = true end
  if flags2 & 0x0008 ~= 0 then settings.rhythm = true end
  if flags2 & 0x0010 ~= 0 then settings.forceHorizontal = true end
  if flags2 & 0x0020 ~= 0 then settings.forceChannels = true end
  if flags2 & 0x0040 ~= 0 then settings.diagramList = true end
  if flags2 & 0x0080 ~= 0 then settings.diagramScore = true end
  if flags2 & 0x0200 ~= 0 then settings.autoLetRing = true end
  if flags2 & 0x0400 ~= 0 then settings.autoBrush = true end
  if flags2 & 0x0800 ~= 0 then settings.extendRythmic = true end
  track.settings = settings
  local accentuation = data:byte()
  track.channelBank  = data:byte()
  track.rse          = self:readTrackRSE(data)
  track.rse.accentuation = accentuation
  return track
end

gp5.readTrackRSE = function (self, data)
  local rse = {}
  rse.humanize   = data:byte()
  data:skip(3*4 + 12)  -- ignore 3 ints and some bytes
  rse.instrument = self:readRSEInstrument(data)
  if self._version > '5.00' then
    rse.equalizer = {}
    for i = 1, 4 do
      rse.equalizer[i] = data:sbyte()
    end
    rse.effects  = self:readRSEInstrumentEffect(data)
  end
  return rse
end

gp5.readRSEInstrument = function (self, data)
  local instrument = {}
  instrument.instrument = data:int()
  data:skip(4)
  instrument.soundBank  = data:int()
  if self._version == '5.00' then
    instrument.effectNo = data:short()
    data:skip(1)
  else
    instrument.effectNo = data:int()
  end
  return instrument
end

gp5.readRSEInstrumentEffect = function (self, data)
  local eff = {}
  if self._version > '5.00' then
    eff.effect   = data:istring()
    eff.category = data:ibstring()
  end
  return eff
end

gp5.readMeasure = function (self, data)
  local measure = {voice={}}
  for i = 1, 2 do
    -- print('voice', i)
    measure.voice[i] = self:readVoice(data)
  end
  measure.lineBreak = (data.pos < #data.file) and data:byte() or 0
  return measure
end

gp5.readBeat = function (self, data)
  local beat = gp4.readBeat(self, data)
  local flags= data:short()
  if     flags & 0x0010 ~= 0 then beat.octave = 'ottava'
  elseif flags & 0x0020 ~= 0 then beat.octave = 'ottavaBassa'
  elseif flags & 0x0040 ~= 0 then beat.octave = 'quindecesima'
  elseif flags & 0x0100 ~= 0 then beat.octave = 'quindecesimaBassa'
  end
  local display = {}
  if flags & 0x0001 ~= 0 then display.breakBeam = true end
  if flags & 0x0004 ~= 0 then display.forceBeam = true end
  if flags & 0x2000 ~= 0 then display.forceBracket = true end
  if flags & 0x1000 ~= 0 then display.breakSecondaryTuplet = true end
  if     flags & 0x0002 ~= 0 then display.beamDirection = 'down'
  elseif flags & 0x0008 ~= 0 then display.beamDirection = 'up'
  end
  if     flags & 0x0400 ~= 0 then display.tupletBracket = 'start'
  elseif flags & 0x0800 ~= 0 then display.tupletBracket = 'end'
  end
  if flags & 0x0800 ~= 0 then
    display.breakSecondary = data:byte()
  end
  beat.display = display
  return beat
end

gp5.readMixTable = function (self, data)
  local tbl     = gp4.readMixTable(self, data)
  tbl.wahEffect = data:sbyte()
  tbl.effects   = self:readRSEInstrumentEffect(data)
  return tbl
end

gp5.readMixTableValues = function (self, data)
  local val = {}
  local tmp = data:sbyte()
  local rse = self:readRSEInstrument(data)
  if tmp >= 0 then
    val.instrument = tmp
    val.rse = rse
  end
  if self._version == '5.00' then data:skip(1) end
  tmp = data:sbyte()
  if tmp >= 0 then val.volume = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.balance = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.chorus = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.reverb = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.phaser = tmp end
  tmp = data:sbyte()
  if tmp >= 0 then val.tremolo = tmp end
  rse = data:ibstring()  -- reuse
  tmp = data:int()
  if tmp >= 0 then
    val.tempo = tmp
    val.temoName = rse
  end
  return val
end

gp5.readMixTableDurations = function (self, data, t)
  if t.volume  then t.volumeDur  = data:sbyte() end
  if t.balance then t.balanceDur = data:sbyte() end
  if t.chorus  then t.chorusDur  = data:sbyte() end
  if t.reverb  then t.reverbDur  = data:sbyte() end
  if t.phaser  then t.phaserDur  = data:sbyte() end
  if t.tremolo then t.tremoloDur = data:sbyte() end
  if t.tempo then
    t.tempoDur   = data:sbyte()
    if self._version > '5.00' then
      t.hideTemo = data:bool()
    end
  end
  return t
end

gp5.readMixTableFlags = function (self, data, t)
  local tbl = gp4.readMixTableFlags(self, data, t)
  if tbl.flags & 0x40 ~= 0 then tbl.useRSE = true end
  if tbl.flags & 0x80 ~= 0 then tbl.showWah = true end
  return tbl
end

gp5.readNote = function (self, data)
  local flags = data:byte()
  local effect, note = {}, {}
  if flags & 0x02 ~= 0 then effect.heavyAccentuatedNote = true end
  if flags & 0x04 ~= 0 then note.ghostNote = true end
  if flags & 0x40 ~= 0 then effect.accentuatedNote = true end
  note.effect2 = effect
  if flags & 0x20 ~= 0 then note.type     = data:byte() end
  if flags & 0x10 ~= 0 then note.velocity = data:sbyte() end
  if flags & 0x20 ~= 0 then
    note.fret = data:sbyte()
    -- print(note.fret)
  end
  if flags & 0x80 ~= 0 then
    local left  = data:sbyte()
    local right = data:sbyte()
    note.effectFinger = {left, right}
  end
  if flags & 0x01 ~= 0 then
    note.durationPercent = data:double()
  end
  local flags2  = data:byte()
  if flags2 & 0x02 ~= 0 then note.swapAccidentals = true end
  if flags & 0x08 ~= 0 then
    note.effect = self:readNoteEffect(data)
  end
  return note
end

gp5.readGrace = function (self, data)
  local grace = {}
  grace.fret       = data:byte()
  grace.velocity   = data:byte()
  grace.transition = data:byte()
  grace.duration   = 1 << (7 - data:byte())
  local flags = data:byte()
  if flags & 0x01 ~= 0 then grace.isDead = true end
  if flags & 0x02 ~= 0 then grace.isOnBeat = true end
end

gp5.readSlides = function (self, data)
  local slides = {}
  local tp = data:byte()
  if tp & 0x01 ~= 0 then slides[#slides+1] = 1 end
  if tp & 0x02 ~= 0 then slides[#slides+1] = 2 end
  if tp & 0x04 ~= 0 then slides[#slides+1] = 3 end
  if tp & 0x08 ~= 0 then slides[#slides+1] = 4 end
  if tp & 0x10 ~= 0 then slides[#slides+1] = -1 end
  if tp & 0x20 ~= 0 then slides[#slides+1] = -2 end
  return slides
end

gp5.readHarmonic = function (self, data)
  local harmonic = {}
  harmonic.type = data:sbyte()
  if harmonic.type == 2 then
    harmonic.semitone   = data:byte()
    harmonic.accidental = data:sbyte()
    harmonic.octave     = data:byte()
  elseif harmonic.type == 3 then
    harmonic.fret       = data:byte()
  end
  return harmonic
end

return gp5

-- local bin = utils.read(arg[1])
-- gp5:readSong(bin)
