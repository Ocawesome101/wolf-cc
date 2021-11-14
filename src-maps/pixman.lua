local t = require("table-lib")
local lib = {}

function lib.yscroll(n, r)
  r = r or {}
  r.x = r.x or 0
  r.y = r.y or 0
  local w, h = term.getSize(2)
  r.w = r.w or w
  r.h = r.h or h
  local pixels = term.getPixels(r.x, r.y, r.w, r.h, true)
  if n > 0 then
    for i=1, n, 1 do
      t.removeFromTable(pixels, 1)
      pixels[#pixels+1] = string.char(r.color or 15):rep(r.w)
    end
  elseif n < 0 then
    for i=1, math.abs(n), 1 do
      t.insertIntoTable(pixels, 1, string.char(r.color or 15):rep(r.w))
      pixels[#pixels] = nil
    end
  end
  term.drawPixels(r.x, r.y, pixels)
end

function lib.xscroll(n, r)
  r = r or {}
  r.x = r.x or 0
  r.y = r.y or 0
  local w, h = term.getSize(2)
  r.w = r.w or w
  r.h = r.h or h
  local pixels = term.getPixels(r.x, r.y, r.w, r.h, true)
  local _end = string.char(r.color or 15):rep(math.abs(n))
  if n > 0 then
    for i=1, #pixels, 1 do
      pixels[i] = pixels[i]:sub(n+1) .. _end
    end
  elseif n < 0 then
    for i=1, #pixels, 1 do
      pixels[i] = _end .. pixels[i]:sub(1, n - 1)
    end
  end
  term.drawPixels(r.x, r.y, pixels)
end

return lib
