
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

end

