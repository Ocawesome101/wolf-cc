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
  local id
  repeat
    id = tonumber(io.read("l"))
    if (not id) or textures[id] then
      printError("texture already exists")
      io.write("Enter a texture ID: ")
    end
  until id and not textures[id]
  io.write("Enter texture name: ")
  local name
  repeat
    name = io.read("l")
  until name and #name > 1
  textures[id] = name
  term.setGraphicsMode(2)
end

local scx, scy = 0, 0

local tileSize = 4

local drawBuf = {}

local function dbFill(x,y,w,h,c)
  local s = c:rep(w)
  for i=y,y+h-1,1 do
    if drawBuf[i] then
      local oglen = #drawBuf[i]
      x=math.max(0,x)
      drawBuf[i] = drawBuf[i]:sub(0,x)..s..drawBuf[i]:sub(x+w+1)
      drawBuf[i] = drawBuf[i]:sub(1, oglen)
    end
  end
end

local function drawMap(w, h)
  for i=0, mw, 1 do
    for j=0, mh, 1 do
      dbFill(i*tileSize+i+scx, j*tileSize+j+scy, tileSize, tileSize,
        string.char((map[i] and map[i][j] or 15) % 16))
    end
  end
end

primitives.load_font("5x5", 6, 6)

local selTex = 1
local showTextureOverlay = false
local function drawInterface(w, h)
  for i=0, h, 1 do
    drawBuf[i] = ("\15"):rep(w)
  end
  drawMap(w, h)
  term.drawPixels(0,0,drawBuf)
  if showTextureOverlay then
    term.drawPixels(0,0,15,96,h)
    primitives.text {
      x = 2, y = 2, text = "TEXTURES"
    }
    for i=1, #textures, 1 do
      primitives.text {
        x = 2, y = i*6+4, text = string.format("%d: %s", i,
          textures[i]:upper()),
        color = i == selTex and 13 or 0
      }
    end
    primitives.text{x = 2, y = h - 6, text = "Add", color = 14}
  else
    term.drawPixels(2, 2, 13, 9, 9)
    primitives.text {
      x = 4, y = 4, text = "T", color = 0
    }
  end
end

term.setGraphicsMode(2)
while true do
  local w, h = term.getSize(2)
  drawInterface(w, h)
  local sig = table.pack(os.pullEvent())
  if sig[1] == "mouse_click" then
    local ax, ay = sig[3], sig[4]
    if showTextureOverlay then
      if ax > 96 then
        showTextureOverlay = false
      elseif ay > (h - 6) then
        addTexture()
      else
        local sel = math.floor(ay / 6) - 1
        if sel > 0 and textures[sel] then
          selTex = sel
        end
      end
    elseif ax < 10 and ay < 10 then
      showTextureOverlay = true
    else
      local x, y = math.floor((ax-scx) / (tileSize+1)),
        math.floor((ay-scy) / (tileSize+1))
      if map[x] and map[x][y] then
        map[x][y] = selTex
      end
    end
  elseif sig[1] == "mouse_drag" and not showTextureOverlay then
    local ax, ay = sig[3], sig[4]
    local x, y = math.floor((ax-scx) / (tileSize+1)),
      math.floor((ay-scy) / (tileSize+1))
    if map[x] and map[x][y] then
      map[x][y] = selTex
    end
  elseif sig[1] == "mouse_scroll" and not showTextureOverlay then
    tileSize = math.max(2, math.min(64, tileSize + sig[2]))
  elseif sig[1] == "key" then
    local key = sig[2]
    if key == keys.up then
      scy = scy - 2
    elseif key == keys.down then
      scy = scy + 2
    elseif key == keys.left then
      scx = scx - 2
    elseif key == keys.right then
      scx = scx + 2
    end
  end
end
