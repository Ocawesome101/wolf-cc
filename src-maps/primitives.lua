-- graphical primitives --

local RC_RADIUS = 4

local pixman = require("pixman")

local lib = {}

local ts = setmetatable({}, {__index = function(t, k)
  return function(_, ...)
    if not term[k] then error("bad term call " .. k) end
    return term[k](...)
  end
end})

function lib.rect(r, s)
  s = s or ts
  s:drawPixels(r.x, r.y, r.color, r.w, r.h)
end

-- copied from groups.csail.mit.edu
local function circlePoints(cx, cy, x, y, px, fill, s)
  local ln, lnx
  if fill then
    ln = {string.rep(string.char(px), y*2+1)}
    lnx = {string.rep(string.char(px), x*2+1)}
  end
  if x == 0 then
    s:setPixel(cx, cy + y, px)
    s:setPixel(cx, cy - y, px)
    if fill then
      s:drawPixels(cx - y, cy, ln)
    else
      s:setPixel(cx + y, cy, px)
      s:setPixel(cx - y, cy, px)
    end
  elseif x == y then
    if fill then
      s:drawPixels(cx - x, cy + y, ln)
      s:drawPixels(cx - x, cy - y, ln)
    else
      s:setPixel(cx + x, cy + y, px)
      s:setPixel(cx - x, cy + y, px)
      s:setPixel(cx + x, cy - y, px)
      s:setPixel(cx - x, cy - y, px)
    end
  elseif x < y then
    if fill then
      s:drawPixels(cx - x, cy + y, lnx)
      s:drawPixels(cx - x, cy - y, lnx)
      s:drawPixels(cx - y, cy + x, ln)
      s:drawPixels(cx - y, cy - x, ln)
    else
      s:setPixel(cx + x, cy + y, px)
      s:setPixel(cx - x, cy + y, px)
      s:setPixel(cx + x, cy - y, px)
      s:setPixel(cx - x, cy - y, px)
      s:setPixel(cx + y, cy + x, px)
      s:setPixel(cx - y, cy + x, px)
      s:setPixel(cx + y, cy - x, px)
      s:setPixel(cx - y, cy - x, px)
    end
  end
end

local function drawCircle(xcenter, ycenter, radius, color, fill, s)
  local x, y = 0, radius
  local p = (5 - radius*4)/4
  
  circlePoints(xcenter, ycenter, x, y, color, fill, s)
  while x < y do
    x = x + 1
    if p < 0 then
      p = p + 2*x+1
    else
      y = y - 1
      p = p + 2*(x-y)+1
    end
    circlePoints(xcenter, ycenter, x, y, color, fill, s)
  end
end

function lib.circle(c, s)
  drawCircle(c.x + c.r, c.y + c.r, c.r, c.color, c.fill, s or ts)
end

local fonts = {}

-- NEW HEXFONT LOADER

function lib.load_font(as, cw, ch)
  local file = shell.dir().."/fonts/"..as..".hex"
  local font = {}
  font.width = cw
  font.height = ch
  for line in io.lines(file) do
    local ch, dat = line:match("(%x+):(%x+)")
    if ch and dat then
      ch = tonumber("0x"..ch)
      ch = utf8.char(ch)
      font[ch] = {}
      for bp in dat:gmatch("%x%x") do
        font[ch][#font[ch]+1] = tonumber("0x"..bp)
      end
    end
  end
  fonts[as] = font
end

function lib.glyph(x, y, char, color, font, s)
  s = s or ts
  local data = fonts[font][char]
  if not data then
    error("bad glyph " .. char)
  end
  for i, byte in ipairs(data) do
    for N = 7, 0, -1 do
      if bit32.band(byte, 2^N) ~= 0 then
        s:setPixel(x + (7-N), y + i - 1, color)
      end
    end
  end
end

function lib.text(t, r, s)
  s = s or ts
  local w, h = s:getSize(2)
  local x, y = t.x, t.y
  local font = t.font or next(fonts)
  local fdat = fonts[font]
  for _, c in utf8.codes(t.text) do
    c = utf8.char(c)
    lib.glyph(x, y, c, t.color or 0, font, s)
    x = x + fdat.width
    if x + fdat.width > w then
      x = t.wrapTo or 0
      y = y + fdat.height
      if y + fdat.height > h then
        pixman.yscroll(fdat.height, r, s)
        y = y - fdat.height
      end
    end
  end
end

function lib.rounded_rect(r, s)
  local radius = r.radius or RC_RADIUS
  local r1 = {x = r.x + radius, y = r.y, w = r.w - radius * 2, h = r.h,
    color = r.color}
  local r2 = {x = r.x, y = r.y + radius, w = r.w, h = r.h - radius * 2,
    color = r.color}
  lib.rect(r1, s)
  lib.rect(r2, s)
  local points = {
    {r.x, r.y},
    {r.x, r.y + r.h - (radius * 2) - 1},
    {r.x + r.w - (radius * 2) - 1, r.y},
    {r.x + r.w - (radius * 2) - 1, r.y + r.h - (radius * 2) - 1},
  }
  for i=1, #points, 1 do
    lib.circle({x = points[i][1], y = points[i][2], r = radius,
      color = r.color, fill = true}, s)
  end
end

return lib
