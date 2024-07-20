--[[  utils.lua

Binary data parsers and additional methods.

2024, Stanislav Mikhel ]]

local unpack = string.unpack
local sformat = string.format


local data = {}
data.__index = data

data.init = function (self, str)
  local o = {pos = 1, file = str}
  return setmetatable(o, self)
end

-- unsigned byte
data.byte = function (self, v)
  v, self.pos = unpack('B', self.file, self.pos)
  return v
end

-- signed byte
data.sbyte = function (self, v)
  v, self.pos = unpack('b', self.file, self.pos)
  return v
end

-- short (2 bytes, little endian)
data.short = function (self, v)
  v, self.pos = unpack('<i2', self.file, self.pos)
  return v
end

-- int (4 bytes, little endian)
data.int = function (self, v)
  v, self.pos = unpack('<i4', self.file, self.pos)
  return v
end

-- float (expected 4 bytes)
data.float = function (self, v)
  v, self.pos = unpack('f', self.file, self.pos)
  return v
end

-- double (expected 8 bytes)
data.double = function (self, v)
  v, self.pos = unpack('d', self.file, self.pos)
  return v
end

-- boolean
data.bool = function (self, v)
  v, self.pos = unpack('B', self.file, self.pos)
  return v > 0
end

-- [byte][string]
data.bstring = function (self)
  local v, pos = unpack('B', self.file, self.pos)
  v, self.pos = unpack(sformat('c%d', v), self.file, pos)
  return v
end

-- [int][string]
data.istring = function (self)
  local v, pos = unpack('<I4', self.file, self.pos)
  v, self.pos = unpack(sformat('c%d', v), self.file, pos)
  return v
end

-- [int][byte][string]
data.ibstring = function (self)
  local a, b, pos = unpack('<I4B', self.file, self.pos)
  local txt = unpack(sformat('c%d', b), self.file, pos)
  self.pos = pos + a - 1
  return txt
end

-- marker color
data.color = function (self)
  local r, g, b, pos = unpack('BBB', self.file, self.pos)
  self.pos = pos + 1
  return {r, g, b}
end

-- ignore n bytes
data.skip = function (self, n)
  self.pos = self.pos + n
end

local utils = {data=data}

-- Read file, return binary text
utils.read = function (name)
  local f = assert(io.open(name, 'rb'))
  local s = f:read('a')
  f:close()
  return s
end

-- Get GTP version
utils.version = function (s)
  if #s < 31 then return nil end
  local txt = unpack('c30', s, 2)
  if string.find(txt, '^CLIPBOARD') then
    return string.match(txt, 'CLIPBOARD GP (%d)')
  else
    return string.match(txt, 'FICHIER GUITAR PRO v(%d)')
  end
end

return utils

