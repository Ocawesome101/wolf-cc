-- raycaster --

local craftos_colors = {
  [0] = {0.94117647058824, 0.94117647058824, 0.94117647058824},
  {0.9490196078431372, 0.6980392156862745, 0.2000000000000000},
  {0.8980392156862745, 0.4980392156862745, 0.8470588235294118},
  {0.6000000000000000, 0.6980392156862745, 0.9490196078431372},
  {0.8705882352941177, 0.8705882352941177, 0.4235294117647059},
  {0.4980392156862745, 0.8000000000000000, 0.0980392156862745},
  {0.9490196078431372, 0.6980392156862745, 0.8000000000000000},
  {0.2980392156862745, 0.2980392156862745, 0.2980392156862745},
  {0.6000000000000000, 0.6000000000000000, 0.6000000000000000},
  {0.2980392156862745, 0.6000000000000000, 0.6980392156862745},
  {0.6980392156862745, 0.4000000000000000, 0.8980392156862745},
  {0.2000000000000000, 0.4000000000000000, 0.8000000000000000},
  {0.4980392156862745, 0.4000000000000000, 0.2980392156862745},
  {0.3411764705882353, 0.6509803921568628, 0.3058823529411765},
  {0.8000000000000000, 0.2980392156862745, 0.2980392156862745},
  {0.0666666666666667, 0.0666666666666667, 0.0666666666666667}
}

--[=[ fade to black ]=]
for n=0, 255, 1 do
  local cnt = false
  for i=0, 15, 1 do
    local r, g, b = term.getPaletteColor(2^i)
    if r > 0 or g > 0 or b > 0 then
      cnt = true
    end
    term.setPaletteColor(2^i, math.max(r - 0.01, 0),
      math.max(g - 0.01, 0),
      math.max(b - 0.01, 0))
  end
  if not cnt then break end
  os.sleep(0.01)
end
--]]

local w, h = term.getSize(2)

-- heads-up display: currently just health
local numbers = {
  [0] = {
    "\3\4\4\3\3",
    "\4\3\3\4\3",
    "\4\3\3\4\3",
    "\4\3\3\4\3",
    "\3\4\4\3\3"
  }, {
    "\3\3\4\3\3",
    "\3\3\4\3\3",
    "\3\3\4\3\3",
    "\3\3\4\3\3",
    "\3\3\4\3\3",
  }, {
    "\4\4\4\3\3",
    "\3\3\3\4\3",
    "\3\3\4\3\3",
    "\3\4\3\3\3",
    "\4\4\4\4\3",
  }, {
    "\4\4\4\3\3",
    "\3\3\3\4\3",
    "\3\4\4\3\3",
    "\3\3\3\4\3",
    "\4\4\4\3\3",
  }, {
    "\4\3\4\3\3",
    "\4\3\4\3\3",
    "\4\4\4\4\3",
    "\3\3\4\3\3",
    "\3\3\4\3\3",
  }, {
    "\4\4\4\4\3",
    "\4\3\3\3\3",
    "\4\4\4\3\3",
    "\3\3\3\4\3",
    "\4\4\4\3\3",
  }, {
    "\3\4\4\4\3",
    "\4\3\3\3\3",
    "\4\4\4\3\3",
    "\4\3\3\4\3",
    "\3\4\4\25\3",
  }, {
    "\4\4\4\4\3",
    "\3\3\3\4\3",
    "\3\3\4\3\3",
    "\3\4\3\3\3",
    "\4\3\3\3\3",
  }, {
    "\3\4\4\3\3",
    "\4\3\3\4\3",
    "\3\4\4\3\3",
    "\4\3\3\4\3",
    "\3\4\4\3\3",
  }, {
    "\3\4\4\3\3",
    "\4\3\3\4\3",
    "\3\4\4\4\3",
    "\3\3\3\4\3",
    "\4\4\4\3\3",
  },
  H = {
    "\3\4\3\4\3",
    "\4\3\4\3\4",
    "\4\3\3\3\4",
    "\3\4\3\4\3",
    "\3\3\4\3\3"
  },
  B = {
    "\3\3\3\3",
    "\4\4\3\3",
    "\4\3\4\3",
    "\3\4\3\4",
    "\3\3\4\4"
  },
  i = {
    "\3\4\3",
    "\3\3\3",
    "\3\4\3",
    "\3\4\3",
    "\3\4\3"
  },
  n = {
    "\3\3\3",
    "\3\3\3",
    "\4\4\3",
    "\4\3\4",
    "\4\3\4"
  },
  f = {
    "\3\3\4",
    "\3\4\3",
    "\4\4\4",
    "\3\4\3",
    "\3\4\3"
  },
}

local weaponsText = {
  PISTOL = {
    "### ###  ## ###  ##  #  ",
    "# #  #  #    #  #  # #  ",
    "###  #   #   #  #  # #  ",
    "#    #    #  #  #  # #  ",
    "#   ### ##   #   ##  ###",
  },
  MINIGUN = {
    "#   # ### #  # ###  ### #  # #  #",
    "## ##  #  ## #  #  #    #  # ## #",
    "# # #  #  # ##  #  # ## #  # # ##",
    "#   #  #  #  #  #  #  # #  # #  #",
    "#   # ### #  # ###  ##   ##  #  #"
  },
  ROCKET = {
    "###  ##   ##  #  # ### ###",
    "# # #  # #  # # #  #    # ",
    "##  #  # #    ##   ###  # ",
    "# # #  # #  # # #  #    # ",
    "# #  ##   ##  #  # ###  # "
  }
}

local hud = {}

local COLL_FAR_LEFT = 0.4
local COLL_FAR_RIGHT = 0.6
local HUD_HEIGHT = 20
local WEAPON = "PISTOL"
local WORLD = "one"

local playerHealth = 100

h = h - HUD_HEIGHT

-- weapons[NAME] = {
-- collected (true/false)
-- fire rate (delay between each shot in milliseconds)
-- projectile type (1=fireball, 0=bullet)
-- projectile speed (0.5 .. 1.5)
-- maximum projectile damage (1..100)
-- ammo type
-- }
local weapons = {
  sequence = {"PISTOL", "MINIGUN", "ROCKET"},
  PISTOL = {true, 1000, 0, 1.2, 10, 1},
  MINIGUN = {false, 100, 0, 0.8, 3, 2},
  ROCKET = {false, 2000, 1, 0.5, 40, 3}
}

-- ammo counts
local ammo = {
  [1] = math.huge,
  [2] = 0,
  [3] = 0
}

local worlds = {
  one = {map = "maps/map01.map"}--, next = "two"}
}

local function generateHUD()
  for i=0, HUD_HEIGHT, 1 do
    hud[i] = string.rep("\3", w)
  end
  local n = "H"..tostring(math.max(0,playerHealth))
  local i = 0
  for c in n:gmatch(".") do
    local char = numbers[tonumber(c)or c]
    local offset = i * 10
    for n=1,5,1 do
      local row = char[n]:gsub("(.)","%1%1")
      if playerHealth < 25 then
        row = row:gsub("\4", "\5")
      end
      hud[n*2] = hud[n*2]:sub(0,5+offset)..row..hud[n*2]:sub(15+offset)
    end
    i=i+1
  end
  i=i+3
  for n=1, 5, 1 do
    local row = weaponsText[WEAPON][n]
      :gsub("(.)","%1%1")
      :gsub(" ","\3")
      :gsub("#","\4")
    hud[n*2]=hud[n*2]:sub(0,5+i*10)..row..hud[n*2]:sub(#row+5+i*10)
  end
  i=i+10
  n = math.max(0, ammo[weapons[WEAPON][6]])
  if n == math.huge then n = "inf" else n = tostring(n) end
  n = "B" .. n
  for c in n:gmatch(".") do
    local char = numbers[tonumber(c) or c]
    local offset = i * 10
    for n = 1, 5, 1 do
      local row = char[n]:gsub("(.)", "%1%1")
      if ammo[weapons[WEAPON][6]] < 2 then
        row = row:gsub("\4", "\5")
      end
      hud[n*2] = hud[n*2]:sub(0, 5+offset)..row..hud[n*2]:sub(15+offset)
    end
    i=i+1
  end
  local o=math.floor(w/2)
  for i=0, HUD_HEIGHT, 1 do
    hud[i]=hud[i]:sub(0,o).."\4"..hud[i]:sub(o+1)
  end
  term.drawPixels(0, h+1, hud)
end
generateHUD()

local items
items = {
  ammobasic = function()
    ammo[2] = ammo[2] + 100
    generateHUD()
  end,
  ammorocket = function()
    ammo[3] = ammo[3] + 3
    generateHUD()
  end,
  itemminigun = function()
    items.ammobasic()
    weapons.MINIGUN[1] = true
  end,
  itemrocket = function()
    items.ammorocket()
    weapons.ROCKET[1] = true
  end
}

local textures = {[0] = {4}}
local texids = {}
local texWidth, texHeight = 64, 64

local world, doors, interpDoors = {}, {}, {}
local floorColor = 0x1
local ceilColor = 0x2

local sprites = {}

local pressed = {}

local loadTexture
local function loadWorld(file, w, d)
  interpDoors = {}
  local n, cn = 0, 0
  local handle = assert(io.open(shell.dir().."/"..file, "rb"))
  local ww, wh = ("<I2I2"):unpack(handle:read(4))
  local data = handle:read("a")
  repeat
    local texID = ("<s1"):unpack(data)
    if texID and #texID > 0 then
      local id = texID:sub(1,1):byte()
      texID = texID:sub(2)
      data = data:sub(3 + #texID)
      texids[id] = texID
      loadTexture(id, texID..".tex")
    else
      texID = nil
    end
  until not texID
  data = data:sub(2)
  w[n] = {}
  sprites = {}
  d[n] = {}
  for byte in data:gmatch(".") do
    byte = byte:byte()
    local door = bit32.band(byte, 0x80) ~= 0
    local sprite = bit32.band(byte, 0x40) ~= 0
    local value = bit32.band(byte, 0x3F)
    
    if door and sprite then door, sprite = false, false end
    if not d[n] then d[n] = {} end
    
    if cn >= ww then
      n = n + 1
      cn = 0
      w[n] = w[n] or {}
    end
    w[n][cn] = 0
    if door then
      d[n][cn] = {0, texids[value] == "door" and 0.5 or 0}
    end
    if sprite then
      sprites[#sprites+1] = {cn + 0.5, n + 0.5, bit32.band(byte, 0x3F)}
    else
      w[n][cn] = bit32.band(byte, 0x3F)
    end
    cn = cn + 1
  end
end

-- textures use a custom format:
-- 1 byte: length of palette section
-- for each palette entry:
-- 1 byte: color ID
-- 3 bytes: RGB value
-- then raw texture data
local lastSetPal = 5
local totalSetColors = 5
loadTexture = function(id, file)
  textures[id] = {}
  local tex = textures[id]
  local n = 0
  local handle = assert(io.open(shell.dir().."/textures/"..file))
  local palConv = {}
  local palLen = ("<I2"):unpack(handle:read(2))
  local r = 0
  local eq = 0
  while r < palLen do
    r = r + 4
    totalSetColors = totalSetColors + 1
    local colID = handle:read(1):byte()
    local rgb = string.unpack("<I3", handle:read(3))
    for i=0, lastSetPal, 1 do
      local mr, mg, mb = term.getPaletteColor(i)
      mr, mg, mb = mr * 255, mg * 255, mb * 255
      local r, g, b = bit32.band(rgb, 0xff0000), bit32.band(rgb, 0x00ff00),
        bit32.band(rgb, 0x0000ff)
      r = bit32.rshift(r, 16)
      g = bit32.rshift(g, 8)
      if math.floor(r/16) == math.floor(mr/16) and
         math.floor(b/16) == math.floor(mb/16) and
         math.floor(g/16) == math.floor(mg/16) then
        palConv[colID] = i
        break
      end
    end
    if not palConv[colID] then
      lastSetPal = lastSetPal + 1
      assert(lastSetPal < 256, "too many texture colors! ("..totalSetColors.." in total)")
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

local posX, posY = 3, 3
local dirX, dirY = 0, 1
local planeX, planeY = 0.6, 0

local time, oldTime = 0, 0

term.setGraphicsMode(2)

term.setPaletteColor(0, 0x000000)
term.setPaletteColor(floorColor, 0x707070)
term.setPaletteColor(ceilColor, 0x383838)
term.setPaletteColor(3, 0x003366) -- HUD color
term.setPaletteColor(4, 0xFFFFFF)
term.setPaletteColor(5, 0xFF0000)

loadTexture(0, "bullet.tex")
loadTexture(512, "projectile.tex")

loadWorld(worlds[WORLD].map, world, doors)

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

  local pmX, pmY, door
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
    pmX, pmY = mapX, mapY
    if not (world[mapY] and world[mapY][mapX]) then
      hit = 0x0
    elseif doors[mapY] and doors[mapY][mapX] and doors[mapY][mapX][1] < 64
        and (world[mapY] and world[mapY][mapX]) ~= 0 then
      local dst = doors[mapY][mapX][1]
      local ddst = doors[mapY][mapX][2]
      -- calculations taken from https://gist.github.com/Powersaurus/ea9a1d57fb30ea166e7e48762dca0dde
      local trueDeltaX = math.sqrt(1+(rayDirY*rayDirY)/(rayDirX*rayDirX))
      local trueDeltaY = math.sqrt(1+(rayDirX*rayDirX)/(rayDirY*rayDirY))
      
      local mapX2, mapY2 = mapX, mapY
      if posX < mapX2 then mapX2 = mapX2 - 1 end
      if posY > mapY2 then mapY2 = mapY2 + 1 end

      if side == 0 then
        local rayMult = ((mapX2 - posX)+1)/rayDirX
        local rye = posY + rayDirY * rayMult
        local trueStepY = math.sqrt(trueDeltaX*trueDeltaX-1)
        local halfStepY = rye + (stepY*trueStepY)*ddst
        if math.floor(halfStepY) == mapY and halfStepY - mapY > dst then
          hit = world[mapY][mapX]
          pmX = pmX + stepX*ddst
          door = dst
        end
      else
        local rayMult = (mapY2 - posY)/rayDirY
        local rxe = posX + rayDirX * rayMult
        local trueStepX = math.sqrt(trueDeltaY*trueDeltaY-1)
        local halfStepX = rxe + (stepX*trueStepX)*ddst
        if math.floor(halfStepX) == mapX and halfStepX - mapX > dst then
          hit = world[mapY][mapX]
          pmY = pmY + stepY*ddst
          door = dst
        end
      end
    elseif world[mapY][mapX] ~= 0x0 then
      hit = world[mapY][mapX]
    end
  end

  if not door then
    door = 0
    if side == 0 then perpWallDist = sideDistX - deltaDistX
    else perpWallDist = sideDistY - deltaDistY end
  else
    if side == 0 then
      perpWallDist = (pmX - posX + (1 - stepX) / 2) / rayDirX
    else
      perpWallDist = (pmY - posY + (1 - stepY) / 2) / rayDirY
    end
  end

  if drawBuf then
    local lineHeight = math.floor(h / perpWallDist * 1.1)

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
      wallX = wallX - door
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

  return perpWallDist, hit, math.floor(mapX), math.floor(mapY), sideDistX,
    sideDistY
end

local paletteCache = {}

local function fadeToBlack()
  for i=0, 255, 1 do
    paletteCache[i] = {term.getPaletteColor(i)}
  end

  for i=0, 255, 1 do
    local cnt = false
    for i=0, 255, 1 do
      local r, g, b = term.getPaletteColor(i)
      cnt = cnt or (r ~= 0 or g ~= 0 or b ~= 0)
      r = math.max(0, r - 0.01)
      g = math.max(0, g - 0.01)
      b = math.max(0, b - 0.01)
      term.setPaletteColor(i, r, g, b)
    end
    if not cnt then break end
    os.sleep(0.01)
  end
end

local function fadeFromBlack()
  for i=0, 255, 1 do
    local cnt = false
    for i=0, 255, 1 do
      local tr, tg, tb = table.unpack(paletteCache[i])
      local r, g, b = term.getPaletteColor(i)
      cnt = cnt or (r < tr or g < tg or b < tb)
      r = math.min(tr, r + 0.01)
      g = math.min(tg, g + 0.01)
      b = math.min(tb, b + 0.01)
      term.setPaletteColor(i, r, g, b)
    end
    if not cnt then break end
    os.sleep(0.01)
  end
end

local function lerp(b, e, d, t)
  return b + (e-b) * (math.min(d,t)/d)
end

local function tickEnemy(sid, moveSpeed)
-- [[
  local spr = sprites[sid]
  local opx, opy, oPx, oPy, odx, ody = posX, posY, planeX, planeY, dirX, dirY
  spr[4] = spr[4] or 1
  spr[5] = spr[5] or 1
  spr[6] = spr[6] or os.epoch("utc")
  spr[7] = spr[7] or spr[6]
  spr[8] = spr[8] or spr[1]
  spr[9] = spr[9] or spr[2]
  spr[10] = spr[10] or spr[1]
  spr[11] = spr[11] or spr[2]
  spr.h = spr.h or 100
  if os.epoch("utc") - spr[6] > 200 then
    spr[6] = os.epoch("utc")
    local np1 = spr[1] + moveSpeed * spr[4]
    local np2 = spr[2] + moveSpeed * spr[5]
    local px, py = math.floor(np1), math.floor(np2)
  
    if world[py] and world[py][px] ~= 0 then
      spr[4] = math.random(-10, 10) / 10
      spr[5] = math.random(-10, 10) / 10
    else
      spr[10] = spr[1]
      spr[11] = spr[2]
      spr[8] = np1
      spr[9] = np2
    end
    if os.epoch("utc") - spr[7] > 1000 then
      spr[7] = os.epoch("utc")
      --local a, b = (posX - spr[1])^2, (posY - spr[2])^2
      local a, b = spr[1] - posX, spr[2] - posY
      local angle = math.tan(a / b)
      local dX, dY = 1 * math.sin(math.rad(angle)),
        1 * math.cos(math.rad(angle))
      local signX, signY = 1, 1
      if math.abs(dX) ~= dX then signX = -1 end
      if math.abs(dY) ~= dY then signY = -1 end
      table.insert(sprites, {spr[1], spr[2], 512, -dX, -dY,
        [7] = math.random(10, 30)})
    end
  else
    spr[1] = lerp(spr[10], spr[8], 200, os.epoch("utc")-spr[6])
    spr[2] = lerp(spr[11], spr[9], 200, os.epoch("utc")-spr[6])
  end
  
  posX, posY, planeX, planeY, dirX, dirY = opx, opy, oPx, oPy, odx, ody
--]]
end

local function doorIsOpen(x, y)
  return doors[y] and doors[y][x] and doors[y][x][1] >= 0.4
end

local function tickProjectile(sid, moveSpeed, stab)
  stab = stab or sprites
  local spr = stab[sid]
  spr[4] = spr[4] or 0
  spr[5] = spr[5] or 0
  spr[1] = spr[1] + moveSpeed * spr[4]
  spr[2] = spr[2] + moveSpeed * spr[5]
  spr[7] = spr[7] or weapons[WEAPON][5] or 30
  local ax, ay = math.floor(spr[1]), math.floor(spr[2])
  if ax == math.floor(posX) and ay == math.floor(posY) and not spr[6] then
    playerHealth = playerHealth - spr[7]
    generateHUD()
    table.remove(stab, sid)
    return playerHealth <= 0
  elseif world[ay] and world[ay][ax] ~= 0 and not doorIsOpen(ax, ay) then
    table.remove(stab, sid)
  elseif spr[6] then
    for i=1, #stab, 1 do
      if stab[i] and i ~= sid then
        local sx, sy = math.floor(stab[i][1]), math.floor(stab[i][2])
        if ax == sx and ay == sy and texids[stab[i][3]] == "enemy" then
          stab[i].h = stab[i].h - spr[7]
          if stab[i].h <= 0 then
            table.remove(stab, i)
            table.remove(stab, sid)
          end
        end
      end
    end
  end
end

-- main loop
local ftavg = 0
local lastUpdate = os.epoch("utc")
local updateTarget = 50
local nextShot = 0
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
    return (spriteDistance[a] or 0) > (spriteDistance[b] or 0)
  end)

  for i=1, #spriteOrder, 1 do
    local s = sprites[spriteOrder[i]]
    local spriteX = s[1] - posX
    local spriteY = s[2] - posY

    local invDet = 1 / (planeX * dirY - dirX * planeY)

    local transformX = invDet * (dirY * spriteX - dirX * spriteY)
    local transformY = invDet * (-planeY * spriteX + planeX * spriteY)

    local spriteScreenX = math.floor((w / 2) * (1 + transformX / transformY))
  
    local spriteHeight = math.abs(math.floor(h / transformY * 1.1))

    local drawStartY = math.max(0, -spriteHeight / 2 + h / 2)
    local drawEndY = math.min(h - 1, spriteHeight / 2 + h / 2)
  
    local spriteWidth = spriteHeight --math.abs(math.floor(h / transformY))
    local drawStartX = math.max(0, -spriteWidth / 2 + spriteScreenX)
    local drawEndX = math.min(w - 1, spriteWidth / 2 + spriteScreenX)
  
    local dof = h / 2 + spriteHeight / 2
    local sof = (-spriteWidth / 2 + spriteScreenX)
    local twdsw = texWidth / spriteWidth
    for stripe = math.floor(drawStartX), drawEndX, 1 do
      local texX = math.floor((stripe - sof) * twdsw) % 64

      if transformY > 0 and stripe > 0 and stripe < w
          and transformY < zBuf[stripe] then
        for y = math.ceil(drawStartY), drawEndY, 1 do
          local d = y - dof
          local texY = math.floor(((d * texHeight) / spriteHeight)) % 64
          local texidx = texWidth * texY + texX
          local color = textures[s[3]][texidx] or 0
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
  moveSpeed = math.max(updateTarget/1000, frametime) * 7
  rotSpeed = math.max(updateTarget/1000, frametime) * 3

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
    if code == keys.one then
      WEAPON = weapons.sequence[1]
      generateHUD()
    elseif code == keys.two then
      if weapons[weapons.sequence[2]][1] then
        WEAPON = weapons.sequence[2]
      end
      generateHUD()
    elseif code == keys.three then
      if weapons[weapons.sequence[3]][1] then
        WEAPON = weapons.sequence[3]
      end
      generateHUD()
    end
  elseif sig == "key_up" then
    pressed[code] = false
  end
  
  if os.epoch("utc") - lastUpdate >= updateTarget - 5 then
    lastUpdate = os.epoch("utc")
    -- bang bang shoot shoot bullet bullet gun
    if pressed[keys.leftAlt] or pressed[keys.rightAlt] then
      if os.epoch("utc") >= nextShot and ammo[weapons[WEAPON][6]] > 0 then
        nextShot = os.epoch("utc") + weapons[WEAPON][2]
        ammo[weapons[WEAPON][6]] = ammo[weapons[WEAPON][6]] - 1
        sprites[#sprites+1] = {posX, posY, weapons[WEAPON][3]*512,
          dirX*weapons[WEAPON][4], dirY*weapons[WEAPON][4], true}
        generateHUD()
      end
    end

    -- reduce movement speed slightly when strafing
    if (pressed[keys.up] or pressed[keys.w] or pressed[keys.s] or
       pressed[keys.down]) and (pressed[keys.a] or pressed[keys.d]) then
      moveSpeed = moveSpeed * 0.75
    end

    -- forward/backward movement
    if pressed[keys.up] or pressed[keys.w] then
      local nposX = posX + dirX * moveSpeed
      local nposY = posY + dirY * moveSpeed
      local oldX, oldY = posX, posY
      local offX, offY = 0.3, 0.3
      if math.abs(dirX) ~= dirX then offX = -0.3 end
      if math.abs(dirY) ~= dirY then offY = -0.3 end
      local r_oY = math.floor(oldY+offY)
      local r_oX = math.floor(oldX+offX)
      local r_nY = math.floor(nposY+offY)
      local r_nX = math.floor(nposX+offX)
      if world[r_oY][r_nX] == 0 or doorIsOpen(r_nX, r_oY) then
        posX = nposX
      end
      if world[r_nY][r_oX] == 0 or doorIsOpen(r_oX, r_nY) then
        posY = nposY
      end
      if world[r_nY][r_nX] == 0 or doorIsOpen(r_nX, r_nY) then
        posX = nposX
      end
    end

    if pressed[keys.down] or pressed[keys.s] then
      local nposX = posX - dirX * moveSpeed
      local nposY = posY - dirY * moveSpeed
      local oldX, oldY = posX, posY
      local offX, offY = -0.3, -0.3
      if math.abs(dirX) ~= dirX then offX = 0.3 end
      if math.abs(dirY) ~= dirY then offY = 0.3 end
      local r_oY = math.floor(oldY+offY)
      local r_oX = math.floor(oldX+offX)
      local r_nY = math.floor(nposY+offY)
      local r_nX = math.floor(nposX+offX)
      if world[r_oY][r_nX] == 0 or doorIsOpen(r_nX, r_oY) then
        posX = nposX
      end
      if world[r_nY][r_oX] == 0 or doorIsOpen(r_oX, r_nY) then
        posY = nposY
      end
      if world[r_nY][r_nX] == 0 or doorIsOpen(r_nX, r_nY) then
        posX = nposX
      end
    end

    -- strafing
    if pressed[keys.a] then
      local tmpDirX = planeX--dirX * math.cos(-90) - dirY * math.sin(-90)
      local tmpDirY = planeY--dirY * math.sin(-90) + dirY * math.cos(-90)
      local nposX = posX - tmpDirX * moveSpeed
      local nposY = posY - tmpDirY * moveSpeed
      local oldX, oldY = posX, posY
      local offX, offY = -0.3, -0.3
      if math.abs(tmpDirX) ~= tmpDirX then offX = 0.3 end
      if math.abs(tmpDirY) ~= tmpDirY then offY = 0.3 end
      local r_oY = math.floor(oldY+offY)
      local r_oX = math.floor(oldX+offX)
      local r_nY = math.floor(nposY+offY)
      local r_nX = math.floor(nposX+offX)
      if world[r_oY][r_nX] == 0 or doorIsOpen(r_nX, r_oY) then
        posX = nposX
      end
      if world[r_nY][r_oX] == 0 or doorIsOpen(r_oX, r_nY) then
        posY = nposY
      end
      if world[r_nY][r_nX] == 0 or doorIsOpen(r_nX, r_nY) then
        posX = nposX
      end
    end

    if pressed[keys.d] then
      local tmpDirX = planeX--dirX * math.cos(-90) - dirY * math.sin(-90)
      local tmpDirY = planeY--dirY * math.sin(-90) + dirY * math.cos(-90)
      local nposX = posX + tmpDirX * moveSpeed
      local nposY = posY + tmpDirY * moveSpeed
      local oldX, oldY = posX, posY
      local offX, offY = 0.3, 0.3
      if math.abs(tmpDirX) ~= tmpDirX then offX = -0.3 end
      if math.abs(tmpDirY) ~= tmpDirY then offY = -0.3 end
      local r_oY = math.floor(oldY+offY)
      local r_oX = math.floor(oldX+offX)
      local r_nY = math.floor(nposY+offY)
      local r_nX = math.floor(nposX+offX)
      if world[r_oY][r_nX] == 0 or doorIsOpen(r_nX, r_oY) then
        posX = nposX
      end
      if world[r_nY][r_oX] == 0 or doorIsOpen(r_oX, r_nY) then
        posY = nposY
      end
      if world[r_nY][r_nX] == 0 or doorIsOpen(r_nX, r_nY) then
        posX = nposX
      end
    end

    -- turning
    if pressed[keys.right] then
      local oldDirX = dirX
      dirX = dirX * math.cos(-rotSpeed) - dirY * math.sin(-rotSpeed)
      dirY = oldDirX * math.sin(-rotSpeed) + dirY * math.cos(-rotSpeed)
      local oldPlaneX = planeX
      planeX = planeX * math.cos(-rotSpeed) - planeY * math.sin(-rotSpeed)
      planeY = oldPlaneX * math.sin(-rotSpeed) + planeY * math.cos(-rotSpeed)
    end
    if pressed[keys.left] then
      local oldDirX = dirX
      dirX = dirX * math.cos(rotSpeed) - dirY * math.sin(rotSpeed)
      dirY = oldDirX * math.sin(rotSpeed) + dirY * math.cos(rotSpeed)
      local oldPlaneX = planeX
      planeX = planeX * math.cos(rotSpeed) - planeY * math.sin(rotSpeed)
      planeY = oldPlaneX * math.sin(rotSpeed) + planeY * math.cos(rotSpeed)
    end
    if pressed[keys.space] then
      local dist, tile, mx, my = castRay(math.floor(w * 0.5))
      if dist < 2 and doors[my] and doors[my][mx] then
        interpDoors[#interpDoors+1] = {my, mx, os.epoch("utc")}
      elseif dist < 2 and texids[tile] == "elevator" then
        if not worlds[WORLD].next then break end
        fadeToBlack()
        WORLD = worlds[WORLD].nextw
        world = {}
        doors = {}
        loadWorld(worlds[WORLD].map, world, doors)
        fadeFromBlack()
      end
    end

    -- update doors
    for i=#interpDoors, 1, -1 do
      local y, x = table.unpack(interpDoors[i])
      if os.epoch("utc") - interpDoors[i][3] >= 5000 then
        if doors[y][x][1] <= 0 then
          if doors[y][x][3] and doors[y][x][2] > 0 then
            doors[y][x][2] = doors[y][x][2] - 0.1 * moveSpeed
          else
            doors[y][x][1] = 0
            table.remove(interpDoors, i)
          end
        else
          doors[y][x][1] = doors[y][x][1] - 0.1 * moveSpeed
        end
      elseif doors[y][x][2] < 0.5 then
        doors[y][x][3] = true
        doors[y][x][2] = doors[y][x][2] + 0.1 * moveSpeed
      elseif doors[y][x][1] < 1 then
        doors[y][x][1] = doors[y][x][1] + 0.1 * moveSpeed
      end
    end

    -- update projectiles
    for i=1, #sprites, 1 do
      if sprites[i] and sprites[i][3] == 512 then
        tickProjectile(i, moveSpeed*1.5)
      elseif sprites[i] and sprites[i][3] == 0 then -- hidden projectile
        tickProjectile(i, moveSpeed*2)
      end
    end

    -- update enemies
    for i=1, #sprites, 1 do
      if texids[sprites[i][3]] == "enemy" then
        tickEnemy(i, moveSpeed)
      end
    end

    -- tick items
    for i=1, #sprites, 1 do
      if sprites[i] and items[texids[sprites[i][3]]] then
        local s = sprites[i]
        local sx, sy = math.floor(s[1]), math.floor(s[2])
        local px, py = math.floor(posX), math.floor(posY)
        if px == sx and py == sy then
          items[texids[s[3]]]()
          table.remove(sprites, i)
        end
      end
    end

    if playerHealth < 0 then break end
  end
end

-- fade to black
for i=0, 255, 1 do
  local cnt = false
  for i=0, 255, 1 do
    local r, g, b = term.getPaletteColor(i)
    cnt = cnt or (r ~= 0 or g ~= 0 or b ~= 0)
    r = math.max(0, r - 0.01)
    g = math.max(0, g - 0.01)
    b = math.max(0, b - 0.01)
    term.setPaletteColor(i, r, g, b)
  end
  if not cnt then break end
  os.sleep(0.01)
end

term.setGraphicsMode(0)
for i=0, 15, 1 do
  term.setPaletteColor(2^i, table.unpack(craftos_colors[i]))
end
--term.clear()
--term.setCursorPos(1,1)
if playerHealth <= 0 then
  printError("You Died!")
end
print("Average FPS: " .. 1/ftavg)
print("Thank you for playing.")

