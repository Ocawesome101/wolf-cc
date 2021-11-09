-- texture generator --

local palette = io.read("l")

local texDat = ""
for word in palette:gmatch("[^ ]+") do
  local id, col = word:match("(%d+):(.+)")
  if col then id, col = tonumber(id), tonumber(col) end
  if not (id and col) then
    error("bad palette entry")
  end
  if id > 15 then
    error("no more than 16 colors allowed per texture")
  end
  io.stderr:write("SET COLOR " .. id .. " TO " .. col .. "\n")
  texDat = texDat .. string.pack("<I1I3", id, col)
end

texDat = string.char(#texDat) .. texDat

local datbuf = io.read("a"):gsub("\n", "")
local to_rle = ""
for c in datbuf:gmatch(".") do
  to_rle = to_rle .. string.char(tonumber("0x"..c))
end

--[[
local c, n = "", 0
for cc in to_rle:gmatch(".") do
  if cc ~= c or n >= 256 then
    if n > 0 then texDat = texDat .. c .. string.char(n-1) end
    c, n = cc, 0
  end
  n = n + 1
end
texDat = texDat .. c .. string.char(n-1)
--]]

texDat = texDat .. to_rle

io.write(texDat)
