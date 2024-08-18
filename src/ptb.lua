

local utils = require('src.utils')
--local mapping = require('src.mapping')


local ptb = {}

ptb.readSong = function (self, s)
  local data = utils.data:init(s)
  local ver = self:readVersion(data)
  print(ver)
  local song = {}
  song.info = self:readSongInfo(data)
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

local ff = utils.read(arg[1])
ptb:readSong(ff)
