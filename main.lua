-- raycaster --

local buffer = require("buffer")

local w, h = term.getSize(2)
local buf = buffer.new(w, h)

local textures = {}

local world = {}

local function loadWorld()
  for line in io.lines("/raycast/world.txt") do
    world[#world+1] = {}
    for c in line:gmatch(".") do
      world[#world][#world[#world]+1] = tonumber("0x"..c)
    end
  end
end

loadWorld()

local posX, posY = 22, 12
local dirX, dirY = -1, 0
local planeX, planeY = 0, 0.66

local time, oldTime = 0, 0

term.setGraphicsMode(2)

local pressed = {}

while true do
  buf.clear()

  local moveSpeed, rotSpeed

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
      if world[mapY][mapX] ~= 0xf then
        hit = world[mapY][mapX]
      end
    end

    if side == 0 then perpWallDist = (sideDistX - deltaDistY)
    else perpWallDist = sideDistY - deltaDistX end

    local lineHeight = h / perpWallDist

    local drawStart = math.max(0, -lineHeight / 2 + h / 2)
    local drawEnd = math.min(h, lineHeight / 2 + h / 2)

    local color = hit
    if side == 0 then
      color = color + 1
      if color > 0xf then color = 0 end
    end

    buf.drawPixels(x, drawStart, color, 1, math.max(0, drawEnd - drawStart))

    oldTime = time
    time = os.epoch("utc")
    local frametime = (time - oldTime) / 1000
    moveSpeed = frametime * 5
    rotSpeed = frametime * 3
  end
  buf.draw(0,0)
  os.startTimer(0.01)
  local sig, code = os.pullEvent()
  if sig == "key" then
    pressed[code] = true
  elseif sig == "key_up" then
    pressed[code] = false
  end
  if pressed[keys.up] then
    local nposX = posX + dirX * moveSpeed
    local nposY = posY + dirY * moveSpeed
    if world[math.floor(posY)][math.floor(nposX)] == 0xF then posX, posY = nposX, nposY end
  elseif pressed[keys.down] then
    local nposX = posX - dirX * moveSpeed
    local nposY = posY - dirY * moveSpeed
    if world[math.floor(nposY)][math.floor(posX)] == 0xF then posX, posY = nposX, nposY end
  elseif pressed[keys.right] then
    local oldDirX = dirX
    dirX = dirX * math.cos(-rotSpeed) - dirY * math.sin(-rotSpeed)
    dirY = oldDirX * math.sin(-rotSpeed) + dirY * math.cos(-rotSpeed)
    local oldPlaneX = planeX
    planeX = planeX * math.cos(-rotSpeed) - planeY * math.sin(-rotSpeed)
    planeY = oldPlaneX * math.sin(-rotSpeed) + planeY * math.cos(-rotSpeed)
  elseif pressed[keys.left] then
    local oldDirX = dirX
    dirX = dirX * math.cos(rotSpeed) - dirY * math.sin(rotSpeed)
    dirY = oldDirX * math.sin(rotSpeed) + dirY * math.cos(rotSpeed)
    local oldPlaneX = planeX
    planeX = planeX * math.cos(rotSpeed) - planeY * math.sin(rotSpeed)
    planeY = oldPlaneX * math.sin(rotSpeed) + planeY * math.cos(rotSpeed)
  end
end
term.setGraphicsMode(0)
