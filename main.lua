-- raycaster --

local w, h = term.getSize(2)

local COLL_FAR_LEFT = 0.4
local COLL_FAR_RIGHT = 0.6

local textures = {}
local texWidth, texHeight = 64, 64

local world, doors = {}, {}
local floorColor = 0x1
local ceilColor = 0x2
--[[
local function loadWorld(file, _world)
  local n, cn = 0, 0
  for line in io.lines(shell.dir().."/"..file) do
    _world[n] = {}
    for c in line:gmatch(".") do
      _world[n][cn] = tonumber("0x"..c) or 0
      cn = cn + 1
    end
    n = n + 1
    cn = 0
  end
end]]

local sprites = {}

local pressed = {}

local loadTexture
local function loadWorld(file, w, d)
  local n, cn = 0, 0
  local handle = assert(io.open(shell.dir().."/"..file, "rb"))
  local ww, wh = ("<I2I2"):unpack(handle:read(4))
  local data = handle:read("a")
  repeat
    local texID = ("<s1"):unpack(data)
    if texID and #texID > 0 then
      local id = texID:sub(1,1):byte()
      texID = texID:sub(2)
      data = data:sub(2 + #texID)
      loadTexture(id, texID)
    else
      texID = nil
    end
  until not texID
  data = data:sub(2)
  w[n] = {}
  sprites = {}
  d[n] = {}
  for byte in data:gmatch(".") do
    local door = bit32.band(byte, 0x80) ~= 0
    local sprite = bit32.band(byte, 0x40) ~= 0
    
    if door and sprite then door, sprite = false, false end
    if not d[n] then d[n] = {} end
    
    if door then
      d[n][cn] = true
    end
    if sprite then
      sprites[#sprites+1] = {cn + 0.5, n + 0.5, bit32.band(byte, 0x3F)}
    end

    if cn >= ww then
      n = n + 1
      cn = 0
      w[n] = {}
    end
    w[n][cn] = 0
    if not sprite then
      w[n][cn] = bit32.band(byte, 0x3F)
    end
  end
end

-- textures use a custom format:
-- 1 byte: length of palette section
-- for each palette entry:
-- 1 byte: color ID
-- 3 bytes: RGB value
-- then raw texture data
local lastSetPal = 2
local loadTexture = function(id, file)
  textures[id] = {}
  local tex = textures[id]
  local n = 0
  local handle = assert(io.open(shell.dir().."/textures/"..file))
  local palConv = {}
  local palLen = handle:read(1):byte()
  local r = 0
  local eq = 0
  while r < palLen do
    r = r + 4
    local colID = handle:read(1):byte()
    local rgb = string.unpack("<I3", handle:read(3))
    for i=0, lastSetPal, 1 do
      local mr, mg, mb = term.getPaletteColor(i)
      mr, mg, mb = mr * 255, mg * 255, mb * 255
      local r, g, b = bit32.band(rgb, 0xff0000), bit32.band(rgb, 0x00ff00),
        bit32.band(rgb, 0x0000ff)
      if math.floor(r/16) == math.floor(mr/16) and
         math.floor(b/16) == math.floor(mb/16) and
         math.floor(g/16) == math.floor(mg/16) then
        palConv[colID] = i
        break
      end
    end
    if not palConv[colID] then
      lastSetPal = lastSetPal + 1--2
      assert(lastSetPal < 256, "too many texture colors!")
      --term.setPaletteColor(lastSetPal - 1,
      --  bit32.band(bit32.rshift(rgb, 1), 8355711))
      term.setPaletteColor(lastSetPal, rgb)
      palConv[colID] = lastSetPal
    end
  end
  repeat
    local byte = handle:read(1)
    if byte then
      tex[n] = palConv[string.byte(byte)]
      n = n + 1
    end
  until not byte
  handle:close()
end

loadWorld("world.txt", world)
loadWorld("doors.txt", doors)

local posX, posY = 21, 11
local dirX, dirY = -1, 0
local planeX, planeY = 0, 0.66

local time, oldTime = 0, 0

term.setGraphicsMode(2)

term.setPaletteColor(0, 0x000000)
term.setPaletteColor(floorColor, 0x707070)
term.setPaletteColor(ceilColor, 0x383838)

loadTexture(1, "eagle.tex")
loadTexture(2, "redbrick.tex")
loadTexture(3, "purplestone.tex")
loadTexture(4, "greystone.tex")
loadTexture(5, "bluestone.tex")
loadTexture(6, "mossy.tex")
loadTexture(7, "wood.tex")
loadTexture(8, "colorstone.tex")
loadTexture(9, "barrel.tex")
loadTexture(10, "greenlight.tex")
loadTexture(11, "pillar.tex")
loadTexture(12, "door.tex")

local lastTimerID

local function castRay(x, invertX, invertY, drawBuf)
  local mapX = math.floor(posX)
  local mapY = math.floor(posY)

  local cameraX = 2 * x / w - 1
  local rayDirX = dirX + planeX * cameraX
  local rayDirY = dirY + planeY * cameraX
  if invertX then
    rayDirX = -rayDirX
  end
  if invertY then
    rayDirY = -rayDirY
  end
    
  local sideDistX, sideDistY

  local deltaDistX = (rayDirX == 0) and 1e30 or math.abs(1 / rayDirX)
  local deltaDistY = (rayDirY == 0) and 1e30 or math.abs(1 / rayDirY)
  local perpWallDist

  local stepX, stepY

  local hit = false
  local side

  if rayDirX < 0 then
    stepX = -1
    sideDistX = (posX - mapX) * deltaDistX
  else
    stepX = 1
    sideDistX = (mapX + 1 - posX) * deltaDistX
  end

  if rayDirY < 0 then
    stepY = -1
    sideDistY = (posY - mapY) * deltaDistY
  else
    stepY = 1
    sideDistY = (mapY + 1 - posY) * deltaDistY
  end

  while not hit do
    if sideDistX < sideDistY then
      sideDistX = sideDistX + deltaDistX
      mapX = mapX + stepX
      side = 0
    else
      sideDistY = sideDistY + deltaDistY
      mapY = mapY + stepY
      side = 1
    end
    if not (world[mapY] and world[mapY][mapX]) then
      hit = 0x0
    elseif world[mapY][mapX] ~= 0x0 then
      hit = world[mapY][mapX]
    end
  end

  if side == 0 then perpWallDist = sideDistX - deltaDistX
  else perpWallDist = sideDistY - deltaDistY end

  if drawBuf then
    local lineHeight = math.floor(h / perpWallDist)

    local drawStart = math.max(0, -lineHeight / 2 + h / 2)
    local drawEnd = math.min(h - 1, lineHeight / 2 + h / 2)

    local color = hit
    if side == 0 then
      color = color + 1
      if color > 0xf then color = 0 end
    end

    local tex = textures[hit] or {}
    if #tex < texWidth*texHeight-2 then
      for i=0, h, 1 do
        drawBuf[i] = drawBuf[i] ..
          (i >= drawStart and i <= drawEnd and string.char(color)
       or (i < drawStart and "\x02")
       or "\x01")
      end
    else
      local wallX
      if side == 0 then wallX = posY + perpWallDist * rayDirY
      else wallX = posX + perpWallDist * rayDirX end
      wallX = wallX - math.floor(wallX)
      
      local texX = math.floor(wallX * texWidth)
      if side == 0 and rayDirX > 0 then texX = texWidth - texX - 1 end
      if side == 1 and rayDirY < 0 then texX = texWidth - texX - 1 end

      local step = texHeight / lineHeight
      local texPos = (drawStart - h / 2 + lineHeight / 2) * step
      for i=0, h, 1 do
        local color = "\x01"
        if (i >= drawStart and i < drawEnd) then
          local texY = bit32.band(math.floor(texPos), (texHeight - 1))
          texPos = texPos + step
          local _color = tex[texHeight * texY + texX] or 255
          color = string.char(_color)
        elseif i < drawStart then
          color = "\x02"
        end
        drawBuf[i] = drawBuf[i] .. color
      end
    end
  end

  return perpWallDist, hit, mapX, mapY
end

local ftavg = 0
while true do
  local moveSpeed, rotSpeed

  local drawBuf = {}
  local zBuf = {}
  for i=0, h, 1 do drawBuf[i] = "" end
  for x = 0, w-1, 1 do
    zBuf[x] = castRay(x, false, false, drawBuf)
  end

  local spriteOrder = {}
  local spriteDistance = {}

  for i=1, #sprites, 1 do
    local s = sprites[i]
    spriteOrder[i] = i
    spriteDistance[i] = ((posX - s[1]) * (posX - s[1])
      + (posY - s[2]) * (posY - s[2]))
  end
  table.sort(spriteOrder, function(a,b)
    return spriteDistance[a] > spriteDistance[b]
  end)

  for i=1, #spriteOrder, 1 do
    local s = sprites[spriteOrder[i]]
    local spriteX = s[1] - posX
    local spriteY = s[2] - posY

    local invDet = 1 / (planeX * dirY - dirX * planeY)

    local transformX = invDet * (dirY * spriteX - dirX * spriteY)
    local transformY = invDet * (-planeY * spriteX + planeX * spriteY)

    local spriteScreenX = math.floor((w / 2) * (1 + transformX / transformY))

    local spriteHeight = math.abs(math.floor(h / transformY))

    local drawStartY = math.max(0, -spriteHeight / 2 + h / 2)
    local drawEndY = math.min(h - 1, spriteHeight / 2 + h / 2)

    local spriteWidth = spriteHeight --math.abs(math.floor(h / transformY))
    local drawStartX = math.max(0, -spriteWidth / 2 + spriteScreenX)
    local drawEndX = math.min(w - 1, spriteWidth / 2 + spriteScreenX)

    for stripe = math.floor(drawStartX), drawEndX, 1 do
      local texX = math.floor((stripe - (-spriteWidth / 2 + spriteScreenX)) *
        texWidth / spriteWidth) % 64

      if transformY > 0 and stripe > 0 and stripe < w
          and transformY < zBuf[stripe] then
        for y = math.floor(drawStartY), drawEndY, 1 do
          local d = y - h / 2 + spriteHeight / 2
          local texY = math.floor(((d * texHeight) / spriteHeight) % 64)
          local color = textures[s[3]][texWidth * texY + texX]
          if color ~= 0 then
            drawBuf[y] = drawBuf[y]:sub(0, stripe) ..
              string.char(color) .. drawBuf[y]:sub(stripe+2)
          end
        end
      end
    end
  end
  term.drawPixels(0, 0, drawBuf)
 
  oldTime = time
  time = os.epoch("utc")
  local frametime = (time - oldTime) / 1000
  ftavg = (ftavg + frametime) / (ftavg == 0 and 1 or 2)
  local fps = 1 / ftavg
  moveSpeed = frametime * 7
  rotSpeed = frametime * 3

  -- input handling
  if not lastTimerID then
    lastTimerID = os.startTimer(0)
  end
  local sig, code, rep = os.pullEventRaw()
  if sig == "terminate" then break end
  if sig == "timer" and code == lastTimerID then
    lastTimerID = nil
  elseif sig == "key" and not rep then
    pressed[code] = true
  elseif sig == "key_up" then
    pressed[code] = false
  end
  
  if pressed[keys.up] or pressed[keys.w] then
    local nposX = posX + dirX * moveSpeed
    local nposY = posY + dirY * moveSpeed
    local dist = math.min((castRay(math.floor(w * 0.5))),
      (castRay(math.floor(w * COLL_FAR_LEFT))),
      (castRay(math.floor(w * COLL_FAR_RIGHT))))
    if dist > 0.8 then
      posX, posY = nposX, nposY end
  end
  if pressed[keys.down] or pressed[keys.s] then
    local nposX = posX - dirX * moveSpeed
    local nposY = posY - dirY * moveSpeed
    local dist = math.min((castRay(math.floor(w * 0.5), true, true)),
      (castRay(math.floor(w * COLL_FAR_LEFT), true, true)),
      (castRay(math.floor(w * COLL_FAR_RIGHT), true, true)))
    if dist > 0.8 then
      posX, posY = nposX, nposY end
  end
  if pressed[keys.right] or pressed[keys.d] then
    local oldDirX = dirX
    dirX = dirX * math.cos(-rotSpeed) - dirY * math.sin(-rotSpeed)
    dirY = oldDirX * math.sin(-rotSpeed) + dirY * math.cos(-rotSpeed)
    local oldPlaneX = planeX
    planeX = planeX * math.cos(-rotSpeed) - planeY * math.sin(-rotSpeed)
    planeY = oldPlaneX * math.sin(-rotSpeed) + planeY * math.cos(-rotSpeed)
  end
  if pressed[keys.left] or pressed[keys.a] then
    local oldDirX = dirX
    dirX = dirX * math.cos(rotSpeed) - dirY * math.sin(rotSpeed)
    dirY = oldDirX * math.sin(rotSpeed) + dirY * math.cos(rotSpeed)
    local oldPlaneX = planeX
    planeX = planeX * math.cos(rotSpeed) - planeY * math.sin(rotSpeed)
    planeY = oldPlaneX * math.sin(rotSpeed) + planeY * math.cos(rotSpeed)
  end
  if pressed[keys.space] then
    local dist, tile, mx, my = castRay(math.floor(w * 0.5))
    if dist < 2 and doors[my][mx] == 1 then
      world[my][mx] = 0
    end
  end
end

term.setGraphicsMode(0)
print("Average FPS: " .. 1/ftavg)
