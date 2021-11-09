-- raycaster --

local w, h = term.getSize(2)

local textures = {}

local world = {}

local function loadWorld()
  local n, cn = 0, 0
  for line in io.lines("/raycast/world.txt") do
    world[n] = {}
    for c in line:gmatch(".") do
      world[n][cn] = tonumber("0x"..c) or 0
      cn = cn + 1
    end
    n = n + 1
    cn = 0
  end
end

local function loadTexture(id, file)
  textures[id] = {}
  for line in io.lines("/raycast/"..file) do
  end
end

loadWorld()

local posX, posY = 20, 15
local dirX, dirY = -1, 0
local planeX, planeY = 0, 0.66

local time, oldTime = 0, 0

term.setGraphicsMode(2)

local pressed = {}

local lastTimerID

while true do
  local moveSpeed, rotSpeed

  local drawBuf = {}
  for i=0, h, 1 do drawBuf[i] = "" end
  for x = 0, w-1, 1 do
    local mapX = math.floor(posX + 0.5)
    local mapY = math.floor(posY + 0.5)

    local cameraX = 2 * x / w - 1
    local rayDirX = dirX + planeX * cameraX
    local rayDirY = dirY + planeY * cameraX
    
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
      if world[mapY][mapX] ~= 0x0 then
        hit = world[mapY][mapX]
      end
    end

    if side == 0 then perpWallDist = (sideDistX - deltaDistX)
    else perpWallDist = sideDistY - deltaDistY end

    local lineHeight = math.floor(h / perpWallDist)

    local drawStart = math.max(0, -lineHeight / 2 + h / 2)
    local drawEnd = math.min(h, lineHeight / 2 + h / 2)

    local color = hit
    if side == 0 then
      color = color + 1
      if color > 0xf then color = 0 end
    end

    --term.drawPixels(x, 0, 0xf, 1, h)
    --term.drawPixels(x, drawStart, color, 1, math.max(0, drawEnd - drawStart))
    for i=0, h, 1 do
      drawBuf[i] = drawBuf[i] ..
        (i >= drawStart and i <= drawEnd and string.char(color) or "\x0F")
    end
  end

  term.drawPixels(0, 0, drawBuf)
 
  oldTime = time
  time = os.epoch("utc")
  local frametime = (time - oldTime) / 1000
  moveSpeed = frametime * 7
  rotSpeed = frametime * 3
  if not lastTimerID then
    lastTimerID = os.startTimer(0)
  end
  local sig, code, rep = os.pullEvent()
  if sig == "timer" and code == lastTimerID then
    lastTimerID = nil
  elseif sig == "key" and not rep then
    pressed[code] = true
  elseif sig == "key_up" then
    pressed[code] = false
  end
  if pressed[keys.up] then
    local nposX = posX + dirX * moveSpeed
    local nposY = posY + dirY * moveSpeed
    if world[math.floor(posY+0.5)][math.floor(nposX+0.5)] == 0 then
      posX, posY = nposX, nposY end
  elseif pressed[keys.down] then
    local nposX = posX - dirX * moveSpeed
    local nposY = posY - dirY * moveSpeed
    if world[math.floor(nposY+0.5)][math.floor(posX+0.5)] == 0 then
      posX, posY = nposX, nposY end
  end if pressed[keys.right] then
    local oldDirX = dirX
    dirX = dirX * math.cos(-rotSpeed) - dirY * math.sin(-rotSpeed)
    dirY = oldDirX * math.sin(-rotSpeed) + dirY * math.cos(-rotSpeed)
    local oldPlaneX = planeX
    planeX = planeX * math.cos(-rotSpeed) - planeY * math.sin(-rotSpeed)
    planeY = oldPlaneX * math.sin(-rotSpeed) + planeY * math.cos(-rotSpeed)
  end if pressed[keys.left] then
    local oldDirX = dirX
    dirX = dirX * math.cos(rotSpeed) - dirY * math.sin(rotSpeed)
    dirY = oldDirX * math.sin(rotSpeed) + dirY * math.cos(rotSpeed)
    local oldPlaneX = planeX
    planeX = planeX * math.cos(rotSpeed) - planeY * math.sin(rotSpeed)
    planeY = oldPlaneX * math.sin(rotSpeed) + planeY * math.cos(rotSpeed)
  end
end
term.setGraphicsMode(0)
