

local utils = require('src.utils')
local mapping = require('src.mapping')


local ptb = {}

ptb.readSong = function (self, s)
  local data = utils.data:init(s)
  local ver = self:readVersion(data)
  assert(ver == 'ptab-4', 'Unknown file format')
  local song = {}
  song.info = self:readSongInfo(data)
  song.track1 = self:readDataInstruments(data)
  song.track2 = self:readDataInstruments(data)
  return song
end

ptb.readVersion = function (self, data)
  local header = data:nstring(4)
  local ver = tostring(data:ptshort())
  return header..'-'..ver
end

ptb.readSongInfo = function (self, data)
  local songInfo = {}
  songInfo.classification = data:byte()
  if songInfo.classification == 0 then
    data:skip(1)
    songInfo.name = data:ptstring()
    songInfo.interpreter = data:ptstring()
    songInfo.releaseType = data:byte()
    if songInfo.releaseType == 0 then
      songInfo.albumType = data:byte()
      songInfo.album = data:ptstring()
      songInfo.albumYear = data:ptshort()
      songInfo.liveRecording = data:bool()
    elseif songInfo.releaseType == 1 then
      songInfo.album = data:ptstring()
      songInfo.liveRecording = data:bool()
    elseif songInfo.releaseType == 2 then
      songInfo.album = data:ptstring()
      songInfo.albumDay = data:ptshort()
      songInfo.albumMonth = data:ptshort()
      songInfo.albumYear = data:ptshort()
    end
    if data:byte() == 0 then
      songInfo.author = data:ptstring()
      songInfo.lyricist = data:ptstring()
    end
    songInfo.arrenger = data:ptstring()
    songInfo.guitarTranscriber = data:ptstring()
    songInfo.bassTranscriber = data:ptstring()
    songInfo.copyright = data:ptstring()
    songInfo.lyrics = data:ptstring()
    songInfo.guitarInstructions = data:ptstring()
    songInfo.bassInstructions = data:ptstring()
  elseif songInfo.classification == 1 then
    songInfo.name = data:ptstring()
    songInfo.album = data:ptstring()
    songInfo.style = data:ptshort()
    songInfo.level = data:byte()
    songInfo.author = data:ptstring()
    songInfo.instructions = data:ptstring()
    songInfo.copyright = data:ptstring()
  end
  return songInfo
end

ptb.readDataInstruments = function (self, data)
  local inst = {}

  -- guitar section
  inst.tracks = {}
  local items = self:readHeaderItems(data)
  for j = 1, items do
    inst.tracks[j] = self:readTrackInfo(data)
    if j < items then data:skip(2) end
  end

  -- chords
  inst.chords = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    inst.chords[j] = self:readChord(data)
    if j < items then data:skip(2) end
  end

  -- floating text
  inst.floatingText = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    inst.floatingText[j] = self:readFloatingText(data)
    if j < items then data:skip(2) end
  end

  -- guitarIn section
  inst.guitarIn = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    inst.guitarIn[j] = self:readGuitarIn(data)
    if j < items then data:skip(2) end
  end

  -- tempo marker
  inst.tempoMarker = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    inst.tempoMarker[j] = self:readTempoMarker(data)
    if j < items then data:skip(2) end
  end

  -- dynamic section
  inst.dynamic = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    inst.dynamic[j] = self:readDynamic(data)
    if j < items then data:skip(2) end
  end

  -- section symbol
  inst.sectionSymbol = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    inst.sectionSymbol[j] = self:readSectionSymbol(data)
    if j < items then data:skip(2) end
  end

  -- section
  inst.section = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    inst.section[j] = self:readSection(data)
    if j < items then data:skip(2) end
  end

  return inst
end

ptb.readHeaderItems = function (self, data)
  local items, str = data:ptshort(), nil
  if items ~= 0 then
    local header = data:ptshort()
    if header == 0xffff then
      if data:ptshort() ~= 1 then
        return -1, str
      end
      local n = data:ptshort()
      str = data:nstring(n)
    end
  end
  return items, str
end

ptb.readTrackInfo = function (self, data)
  print('track info')
  local info = {}
  info.number = data:byte()
  info.name = data:ptstring()
  info.instrument = data:byte()
  info.volume = data:byte()
  info.balance = data:byte()
  info.reverb = data:byte()
  info.chorus = data:byte()
  info.tremolo = data:byte()
  info.phaser = data:byte()
  info.capo = data:byte()
  info.tuningName = data:ptstring()
  info.offset = data:byte()
  -- strings
  local strings = {}
  local len = data:byte()
  for i = 1, len do
    strings[i] = data:byte()
  end
  info.strings = strings
  return info
end

ptb.readChord = function (self, data)
  print('read chord')
  local chord = {}
  chord.key = data:ptshort()
  data:skip(1)
  chord.modification = data:ptshort()
  data:skip(2)
  chord.frets = {}
  local len = data:byte()
  for i = 1, len do
    chord.frets[i] = data:byte()
  end
  return chord
end

ptb.readFloatingText = function (self, data)
  print('read floating text')
  local txt = {}
  txt.string = data:ptstring()
  txt.left = data:int()
  txt.top = data:int()
  txt.right = data:int()
  txt.bottom = data:int()
  data:skip(1)
  txt.font = self:readFontSetting(data)
  return txt
end

ptb.readFontSetting = function (self, data)
  local font = {}
  font.name = data:ptstring()
  font.size = data:int()
  font.weight = data:int()
  font.italic = data:bool()
  font.underline = data:bool()
  font.strikeout = data:bool()
  font.color = data:int()
  return font
end

ptb.readGuitarIn = function (self, data)
  print('read guitar in')
  local g = {}
  g.section = data:ptshort()
  g.staff = data:byte()
  g.position = data:byte()
  data:skip(1)
  g.info = data:byte()
  return g
end

ptb.readTempoMarker = function (self, data)
  print('read tempo marker')
  local marker = {}
  marker.section = data:ptshort()
  marker.position = data:byte()
  marker.tempo = data:ptshort()
  local d = data:ptshort()
  marker.description = data:ptstring()
  if d & 0x01 ~= 0 then
    marker.tripletFeel = 8
  elseif d & 0x02 ~= 0 then
    marker.tripletFeel = 16
  end
  return marker
end

ptb.readDynamic = function (self, data)
  data:skip(2+2+2)
end

ptb.readSectionSymbol = function (self, data)
  print 'read section symbol'
  local sym = {}
  sym.section = data:ptshort()
  sym.position = data:byte()
  local d = data:int()
  sym.endNumber = (d >> 16)
  return sym
end

ptb.readSection = function (self, data)
  print 'read section'
  local section = {}
  section.left = data:int()
  section.top = data:int()
  section.right = data:int()
  section.bottom = data:int()

  local lastBar = data:byte()
  data:skip(4)
  section.barLine = self:readBarLine(data)

  -- direction
  local count = self:readHeaderItems(data)
  section.direction = {}
  for j = 1, count do
    section.direction[j] = self:readDirection(data)
    if j < count then data:skip(2) end
  end

  -- chord text
  section.chordText = {}
  count = self:readHeaderItems(data)
  for j = 1, count do
    section.chordText[j] = self:readChordText(data)
    if j < count then data:skip(2) end
  end

  -- thythm slash
  section.rhythmSlash = {}
  count = self:readHeaderItems(data)
  for j = 1, count do
    section.rhythmSlash[j] = self:readRhythmSlash(data)
    if j < count then data:skip(2) end
  end

  -- staff
  section.staffs = {}
  count = self:readHeaderItems(data)
  for j = 1, count do
    section.staffs[j] = self:readStaff(data)
    if j < count then data:skip(2) end
  end

  -- music bar
  section.barLine = {}
  count = self:readHeaderItems(data)
  for j = 1, count do
    section.barLine[j] = self:readBarLine(data)
    if j < count then data:skip(2) end
  end

  section.repeatClose = (lastBar >> 5 == 4) and (lastBar - 128) or 0
  return section
end

ptb.readBarLine = function (self, data)
  local bar = {}
  bar.position = data:byte()
  local tp = data:byte()

  bar.repeatStart = (tp >> 5 == 3)
  bar.repeatClose = (tp >> 5 == 4) and (tp - 128) or 0
  bar.keySignature = data:byte()
  bar.timeSignature = self:readTimeSignature(data)
  bar.rehearsalSign = self:readRehearsalSign(data)
  return bar
end

ptb.readTimeSignature = function (self, data)
  local sign = {}
  local d = data:int()
  sign.pulses = data:byte()
  local d24 = d >> 24
  sign.numerator = (d24 - (d24 % 8))/8 + 1
  sign.denominator = 2^(d24 % 8)
  return sign
end

ptb.readRehearsalSign = function (self, data)
  local t = {}
  t[1] = data:byte()
  t[2] = data:ptstring()
  return t
end

ptb.readDirection = function (self, data)
  local dir = {}
  dir.position = data:byte()
  local count = data:byte()
  dir.val = {}
  for i = 1, count do
    local d = data:ptshort()
    dir.val[i] = {d >> 8, (d & 0xc0) >> 6, d & 0x1f}
  end
  return dir
end

ptb.readChordText = function (self, data)
  data:skip(1+2+1+2+1)
end

ptb.readRhythmSlash = function (self, data)
  data:skip(1+1+4)  
end

ptb.readStaff = function (self, data)
  data:skip(5)
  local staff = {}
  for voice = 1, 2 do
    local items = self:readHeaderItems(data)
    local pos = {}
    for j = 1, items do
      pos[j] = self:readPosition(data)
      if j < items then data:skip(2) end
    end
    staff[voice] = pos
  end
  return staff
end

ptb.readPosition = function (self, data)
  local beat = {staff=staff, voice=voice}
  local position = data:byte()
  local beaming = data:byte()
  beaming = (beaming < 128) and beaming or (beaming - 128)
  data:skip(1)
  local data1 = data:byte()
  data:skip(1)
  local data3 = data:byte()
  beat.duration = data:byte()

  local multiBarRest = 1
  local complexCount = data:byte()
  for i = 1, complexCount do
    local count = data:ptshort()
    data:skip(1)
    local tp = data:byte()
    if tp & 0x08 ~= 0 then multiBarRest = count end
  end

  local itemCount = self:readHeaderItems(data)
  beat.note = {}
  for i = 1, itemCount do
    beat.note[i] = self:readNote(data)
    if i < itemCount then data:skip(2) end
  end

  beat.multiBarRest = (0 == itemCount) and multiBarRest or 1
  beat.vibrato = (data1 & 0x08 ~= 0) or (data1 & 0x10 ~= 0) 
  beat.grace = (data3 & 0x01 ~= 0)
  beat.dotted = (data1 & 0x01 ~= 0)
  beat.doubleDotted = (data1 & 0x02 ~= 0)
  beat.arpeggioUp = (data1 & 0x20 ~= 0)
  beat.arpeggioDown = (data1 & 0x40 ~= 0)
  beat.enters = (beaming - (beaming % 8))/8 + 1
  beat.times = beaming % 8 + 1
  return beat
end

ptb.readNote = function (self, data)
  local note = {}
  local pos = data:byte()
  local simp = data:ptshort()
  local count = data:byte()
  note.add = {}
  for i = 1, count do
    data:skip(2)
    local d3 = data:byte()
    local d4 = data:byte()
    note.add[i] = {}
    note.add[i].bend = (101 == d4) and (d3/16 + 1) or 0
    note.add[i].slide = (100 == d4)
  end
  note.value = pos & 0x1f
  note.string = ((pos & 0xe0) >> 5) + 1
  note.tied = (simp & 0x01) ~= 0
  note.dead = (simp & 0x02) ~= 0
  return note
end

--=======================================

ptb.getSongInfo = function (self, song)
  local info = {}
  info.title = song.info.name
  info.artist = song.info.author
  info.album = song.info.album
  info.tempo = song.track1.tempoMarker[1] and song.track1.tempoMarker[1].tempo
    or song.track2.tempoMarker[1] and song.track2.tempoMarker[2].tempo
    or 120
  info.notice = {}
  if song.info.guitarInstructions then 
    table.insert(info.notice, song.info.guitarInstructions)
  end
  if song.info.bassInstructions then
    table.insert(info.notice, song.info.bassInstructions)
  end
  if song.info.instructions then
    table.insert(song.info.instructions)
  end
  return info
end

ptb.getTracks = function (self, song)
  local res = {}
  for _, v in ipairs(song.track1.tracks) do
    res[#res+1] = {
      name = v.name,
      instrument = mapping.instruments[v.instrument] 
    }
  end
  for _, v in ipairs(song.track2.tracks) do
    res[#res+1] = {
      name = v.name,
      instrument = mapping.instruments[v.instrument] 
    }
  end
  return res
end

ptb.getKeySignName = function (self, song) return "" end

ptb.getTripletFeel = function (self, song)
  return song.track1.tempoMarker[1] and song.track1.tempoMarker[1].tripletFeel
    or song.track2.tempoMarker[1] and song.track2.tempoMarker[1].tripletFeel
end

return ptb

