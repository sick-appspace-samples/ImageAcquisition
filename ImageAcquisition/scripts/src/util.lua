------------------------------------------------------------------------------
-- Utility functions
------------------------------------------------------------------------------
local util = {}

-- Naive rounding
function util.round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Returns the first parameter (a) if cond is true, otherwise the second (b).
function util.if_else(cond, a, b)
  if cond then
    return a
  else
    return b
  end
end

-- Return the point clipped to the left and right sides of the given field of view.
function util.clipPoint(srcPoint, fov)
  local width, _, xOffset, _ = table.unpack(fov)
  local point = srcPoint:clone()

  local leftX = xOffset - width / 2
  if point:getX() < leftX then
    point:setX(math.ceil(leftX * 10) / 10)
  end

  local rightX = xOffset + width / 2
  if point:getX() > rightX then
    point:setX(math.floor(rightX * 10) / 10)
  end
  return point
end

-- Create a table that maps the values used in the UI for drop downs
-- to the names used by the V3TConfig3D-CROWN (and such).
local function createConverter(strList)
  local converter = {}

  converter.toString = function(value)
    local index = value + 1 -- The UI values are zero-based
    return strList[index]
  end

  converter.toValue = function(str)
    for i, s in ipairs(strList) do
      if s == str then
        return i - 1
      end
    end
    print('Error: Missing index for ' .. str)
  end

  return converter
end

-- "Namespace" for converters
util.convert = {}
util.convert.imageTriggerMode = createConverter({'NONE', 'IO_3', 'OBJECT', 'SOFTWARE'})
util.convert.peakSelectionMode = createConverter({'STRONGEST', 'TOP_MOST', 'BOTTOM_MOST'})
util.convert.profileTriggerMode = createConverter({'FREE_RUNNING', 'ENCODER'})
util.convert.triggerDelayUnit = createConverter({'MS', 'MM'})

return util
