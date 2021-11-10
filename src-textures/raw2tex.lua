-- convert gimp-exported ".data" raw images to a 'raycast' .tex file --

local palette = {}

local function addToPalette(c)
  for i=0, #palette, 1 do
    if palette[i] == c then
      return i
    end
  end
  if not palette[0] then palette[0] = c return 0
    else palette[#palette+1] = c return #palette end
end

local imgdata = ""

while true do
  local data = io.read(3)
  if not data then break end
  local rgb = string.unpack(">I3", data)
  local index = addToPalette(rgb)
  imgdata = imgdata .. string.char(index)
end

io.stderr:write("palette colors: " .. #palette .. "\n")
local paldata = string.char(#palette * 4 + 4)
for i=0, #palette, 1 do
  paldata = paldata .. string.pack("<I1I3", i, palette[i])
end

io.write(paldata .. imgdata)
