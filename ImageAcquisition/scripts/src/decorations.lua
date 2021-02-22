------------------------------------------------------------------------------
-- Decorations for web HMI shapes and images
------------------------------------------------------------------------------

-- Helper for creating decorations with different fill and line alpha values
local function shapeColor(r, g, b, aFill, aLine, lineWidth)
  local d = View.ShapeDecoration.create()
  d:setFillColor(r, g, b, aFill)
  d:setLineColor(r, g, b, aLine)
  d:setLineWidth(lineWidth)
  return d
end

local decorations = {}

decorations.guaranteedFOV = shapeColor(255, 255, 0, 25, 180, 2.0)
decorations.userFOV = shapeColor(0, 0, 255, 25, 180, 2.0)
decorations.triggerLine = shapeColor(255, 150, 180, 100, 220, 2.0)

-- A default image decoration for heightmaps
decorations.image = View.ImageDecoration.create()
decorations.image:setRange(0, 65535)

return decorations
