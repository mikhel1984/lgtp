

local utils = require('src.utils')
--local mapping = require('src.mapping')


local ptb = {}

ptb.readSong = function (self, s)
  local data = utils.data:init(s)
  local ver = self:readVersion(data)
  assert(ver == 'ptab-4', 'Unknown file format')
  print(ver)
  local song = {}
  song.info = self:readSongInfo(data)
  for k, v in pairs(song.info) do
    print(k, v)
  end
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
  local data = {}
  -- guitar section
  data.tracks = {}
  local items = self:readHeaderItems(data)
  for j = 1, items do
    data.tracks[j] = self:readTrackInfo(data)
    if j < items then
      data:skip(2)  -- read short
    end
  end
  -- chords
  data.chords = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    data.chords[j] = self:readChord(data)
    if j < items then
      data:skip(2)  -- read short
    end
  end
  -- rhythm slash
  data.rhythm = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    data.rhythm[j] = self:readRhythmSlash(data)
    if j < items then
      data:skip(2)  -- read short
    end
  end
  -- staff
  data.staff = {}
  items = self:readHeaderItems(data)
  for j = 1, items do
    data.staff[j] = self:readStaff(data, j)
    if j < items then
      data:skip(2)  -- read short
    end
  end
  
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

ptb.readRhythmSlash = function (self, data)
  data:skip(1+1+4)  -- byte, byte, int
  return {}
end

ptb.readStaff = function (self, data, st)
  data:skip(5)
  local staff = {}
  for voice = 1, 2 do
    local items = self:readHeaderItems()
    local pos = {}
    for j = 1, items do
      pos[j] = self:readPosition(data, st, voice)
      if j < items then 
        data:skip(2)  -- read short
      end
    end
    staff[voice] = pos
  end
  return staff
end

local ff = utils.read(arg[1])
ptb:readSong(ff)
