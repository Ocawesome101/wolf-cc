local primitives = require("primitives")

local mw, mh, file = tonumber(arg[1]), tonumber(arg[2]), arg[3]
assert(mw and mh and file, "usage: "..arg[0].." WIDTH HEIGHT FILE")

local textures = {
  "bluestone",
  "bricks",
}
local map = {}

for i=0, mw - 1, 1 do
  map[i] = {}
  for j=0, mh - 1, 1 do
    map[i][j] = 0
  end
end

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
    local id = tonumber(io.read("l"))
    if (not id) or textures[id] then
      printError("texture already exists")
    end
  until id and not textures[id]
  io.write("Enter texture name: ")
  repeat
    local name = io.read("l")
  until #name > 1
  term.setGraphicsMode(2)
end

local scx, scy = 0, 0

local drawBuf = {}

local function dbFill(x,y,w,h,c)
  local s = c:rep(w)
  for i=y,y+h-1,1 do
    if drawBuf[i] then
      drawBuf[i] = drawBuf[i]:sub(0,x)..s..drawBuf[i]:sub(x+w+1)
    end
  end
end

local function drawMap(w, h)
  for i=0, math.floor(w / 8), 1 do
    for j=0, math.floor(h / 8), 1 do
      dbFill(i*8+i, j*8+j, 8, 8, string.char((map[i] and map[i][j] or 0) % 15))
    end
  end
end

primitives.load_font("5x5", 6, 6)

local function drawInterface()
  local w, h = term.getSize(2)
  for i=1, h, 1 do
    drawBuf[i] = ("\15"):rep(w)
  end
  drawMap(w, h)
  term.drawPixels(0,0,drawBuf)
  term.drawPixels(0,0,15,w,10)
  primitives.text {
    x = 2, y = 2, text = "TEXTURES"
  }
  for i=1, #textures, 1 do
    primitives.text {
      x = 2, y = i*6, text = string.format("%d: %s", i, textures[i])
    }
  end
end

term.setGraphicsMode(2)
while true do
  drawInterface()
  local sig = table.pack(os.pullEvent())
  if sig == "mouse_click" then
    local x, y = math.floor(sig[3] / 8), math.floor(sig[4] / 8)
  elseif sig == "key" then
    local key = sig[2]
    if key == keys.up then
      scy = scy - 1
    elseif key == keys.down then
      scy = scy + 1
    elseif key == keys.left then
      scx = scx + 1
    elseif key == keys.right then
      scx = scx - 1
    end
  end
end
