local primitives = require("primitives")

local mw, mh, file = tonumber(arg[1]), tonumber(arg[2]), arg[3]
assert(mw and mh and file, "usage: "..arg[0].." WIDTH HEIGHT FILE")
file = shell.dir() .. "/" .. file

local textures = {
  [0] = "nil",
  "greystone",
  "bluestone",
  "redbrick",
}
local map = {}

for i=0, mw - 1, 1 do
  map[i] = {}
  for j=0, mh - 1, 1 do
    map[i][j] = 0
  end
end

if fs.exists(file) then
  local n, cn = 0, 0
  local handle = assert(io.open(file, "rb"))
  local ww, wh = ("<I2I2"):unpack(handle:read(4))
  local data = handle:read("a")
  repeat
    local texID = ("<s1"):unpack(data)
    if texID and #texID > 0 then
      local id = texID:sub(1,1):byte()
      texID = texID:sub(2)
      data = data:sub(3 + #texID)
      textures[id] = texID
    else
      texID = nil
    end
  until not texID
  data = data:sub(2)
  map[n] = {}
  for byte in data:gmatch(".") do
    if cn >= ww then
      n = n + 1
      cn = 0
      map[n] = map[n] or {}
    end
    map[n][cn] = byte:byte()
    cn = cn + 1
  end
end

local function save()
  term.setGraphicsMode(0)
  term.clear()
  term.setCursorPos(1,1)
  io.write("Saving....")
  local handle = assert(io.open(file, "wb"))
  handle:write(("<I2I2"):pack(mw, mh))
  for i=1, #textures, 1 do
    handle:write(("<s1"):pack(string.char(i)..textures[i]))
  end
  handle:write("\0")
  for i=0, mw-1, 1 do
    for j=0, mh-1, 1 do
      handle:write(string.char(map[i][j]))
    end
  end
  handle:close()
  io.write("Saved!\n")
  sleep(1)
  term.setGraphicsMode(2)
end

local function addTexture()
  term.setGraphicsMode(0)
  term.clear()
  term.setCursorPos(1,1)
  io.write("Enter a texture ID: ")
  local id, last
  repeat
    id = tonumber(io.read("l"))
    if (not id) or (textures[id] and last ~= id) or id < 0 or id > 64 then
      printError("texture already exists, or bad texture ID")
      io.write("Enter a texture ID: ")
    end
    last = id
  until id and not (textures[id] and last ~= id) and id > 0 and id < 64
  io.write("Enter texture name: ")
  local name
  repeat
    name = io.read("l")
  until name and #name > 1
  textures[id] = name
  term.setGraphicsMode(2)
end

local function changeColor(id)
  term.setGraphicsMode(0)
  term.clear()
  term.setCursorPos(1,1)
  local id = id
  if not id then
    io.write("Enter a palette ID: ")
    repeat
      id = tonumber(io.read("l"))
    until id and id > 0 and id < 256
  end
  io.write("Enter a color (0x")
  term.setTextColor(colors.red)
  io.write("RR")
  term.setTextColor(colors.green)
  io.write("GG")
  term.setTextColor(colors.blue)
  io.write("BB")
  term.setTextColor(colors.white)
  io.write("): ")
  local color
  repeat
    color = tonumber(io.read("l"))
  until color and color > 0 and color < 0x1000000
  term.setGraphicsMode(2)
  term.setPaletteColor(id, color)
end

local function setFlags(x, y)
  term.setGraphicsMode(0)
  local tile = map[x][y]
  local door = bit32.band(tile, 0x80) ~= 0
  local sprite = bit32.band(tile, 0x40) ~= 0

  print(string.format("Current flags:\ndoor: %d\nsprite: %d",
    door and 1 or 0, sprite and 1 or 0))

  io.write(string.format("New flags (empty to leave unchanged) [%d%d]: ",
    door and 1 or 0, sprite and 1 or 0))
  local text = io.read(2)
  door = text:sub(1,1) == "1"
  sprite = text:sub(2,2) == "1"

  if door then
    map[x][y] = bit32.bor(tile, 0x80)
  end
  if sprite then
    map[x][y] = bit32.bor(tile, 0x40)
  end
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
        string.char(bit32.band(map[i] and map[i][j] or 15, 0x3F)))
    end
  end
end

primitives.load_font("5x5", 6, 6)

local ANIM_LEN = 250
local selTex = 1
local showTextureOverlay = false
local lastTime = 0
local function drawInterface(w, h)
  for i=0, h, 1 do
    drawBuf[i] = ("\15"):rep(w)
  end
  drawMap(w, h)
  term.drawPixels(0,0,drawBuf)
  if showTextureOverlay then
    if os.epoch("utc") - lastTime < ANIM_LEN then
      term.drawPixels(0, 0, 7,
        math.floor(96*((os.epoch("utc") - lastTime)/ANIM_LEN)), h)
      os.queueEvent("dummy")
    else
      term.drawPixels(0,0,7,96,h)
      primitives.text {
        x = 2, y = 2, text = "MENU"
      }
      for i=0, #textures, 1 do
        primitives.text {
          x = 2, y = i*6+10, text = string.format("%d: %s", i,
            textures[i]:upper()),
          color = i == selTex and 13 or 0
        }
      end
      primitives.text{x = 2, y = h - 18, text = "ADD", color = 14}
      primitives.text{x = 2, y = h - 12, text = "CHANGE COLOR", color = 14}
      primitives.text{x = 2, y = h - 6, text = "SAVE", color = 14}
    end
  elseif os.epoch("utc") - lastTime < ANIM_LEN then
    term.drawPixels(0, 0, 7,
      math.floor(96 * (ANIM_LEN - (os.epoch("utc") - lastTime))/ANIM_LEN), h)
    os.queueEvent("dummy")
  else
    term.drawPixels(2, 2, 13, 9, 9)
    primitives.text {
      x = 4, y = 4, text = "=", color = 0
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
    if showTextureOverlay and ax <= 96 then
      if ay > (h - 6) then
        save()
      elseif ay > (h - 12) then
        changeColor()
      elseif ay > (h - 18) then
        addTexture()
      else
        local sel = math.floor((ay - 10) / 6)
        if sel >= 0 and textures[sel] then
          selTex = sel
        else
          showTextureOverlay = false
          lastTime = os.epoch("utc")
        end
      end
    elseif ax < 10 and ay < 10 then
      showTextureOverlay = true
      lastTime = os.epoch("utc")
    else
      local x, y = math.floor((ax-scx) / (tileSize+1)),
        math.floor((ay-scy) / (tileSize+1))
      if map[x] and map[x][y] then
        if sig[2] == 2 then
          setFlags(x, y)
        else
          map[x][y] = selTex
        end
      end
    end
  elseif sig[1] == "mouse_drag" and (sig[3] >= 96 or not showTextureOverlay)then
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
      scy = scy + 4
    elseif key == keys.down then
      scy = scy - 4
    elseif key == keys.left then
      scx = scx + 4
    elseif key == keys.right then
      scx = scx - 4
    end
  end
end
