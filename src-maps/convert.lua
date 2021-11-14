-- convert a specially formatted text file into a map --

local palette = io.read("l")

local function charToID(id)
  if id:match("[a-z]") then -- lowercase: tile
    
  end
  local i = id:byte() - 32
  if i >= 0 then return i end
end

local palDat = ""
for word in palette:gmatch("[^ ]+") do
  local id, name = word:match("(%d+):(.+)")
  if name then id = charToID(id) end
  if not (id and name) then
    error("bad palette entry: '" .. word .. "'")
  end
  palDat = palDat .. string.pack("<s1", string.pack("<I1c"..#name, id, name))
end

local wh = io.read("l")
local mw, mh = wh:match("(%d+),(%d+)")
mw, mh = tonumber(mw), tonumber(mh)
assert(mw and mh, "bad (width,height) pair: '" .. wh .. "'")

local mapDat = string.pack("<I2I2", mw, mh) .. palDat
for c in io.read("a"):gsub("\n", ""):gmatch(".") do
  mapDat = mapDat .. charToID(c)
end

io.write(mapDat)
