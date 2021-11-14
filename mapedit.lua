local mw, mh, file = tonumber(arg[1]), tonumber(arg[2]), arg[3]
assert(mw and mh and file, "usage: "..arg[0].." WIDTH HEIGHT FILE")

local textures = {}
local map = {}

local function save()
  local handle = assert(io.open(file, "wb"))
  handle:write(("<I2I2"):pack(mw, mh))
  for i=1, #textures, 1 do
    handle:write(("<s1"):pack(string.char(i)..textures[i]))
  end
end

local function addTexture()
  term.setGraphicsMode(0)
  term.clear()
  term.setCursorPos(1,1)
  io.write("Enter a texture ID: ")
  repeat
    local id = tonumber(io.read())
    if (not id) or textures[id] then
      printError("texture already exists")
    end
  until id and not textures[id]
  io.write("Enter texture name: ")
  repeat
    local name = io.read()
  until name
  term.setGraphicsMode(2)
end

local bordered = {
  ""
}

local function drawMap()
end

local function drawInterface()
end
