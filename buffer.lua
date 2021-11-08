-- screen buffers for CraftOS-PC graphics mode --

local lib = {}

function lib.new(w, h)
  local lines = {}
  for i=0, h, 1 do
    lines[i] = ("\15"):rep(w)
  end
  return {
    clear = function()
      for i=1, h, 1 do
        lines[i] = ("\15"):rep(w)
      end
    end,
    drawPixels = function(_x,_y,color,_w,_h)
      local ln = string.char(color):rep(_w)
      for y=math.max(0,_y),math.min(h,_y+_h),1 do
        lines[y] = lines[y]:sub(0,_x-1)..ln..lines[y]:sub(_x+_w)
      end
    end,
    draw = function(x,y)
      term.drawPixels(x,y,lines)
    end
  }
end

return lib
