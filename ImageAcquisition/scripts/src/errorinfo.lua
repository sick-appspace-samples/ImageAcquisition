local module = {}

-- Create a table with functions for checking that the V3TConfig3D
-- parameter with the specified name is within its limits.
--
-- This requires that the there is a getter and limit-getter for the
-- name in V3TConfig3D:
--
--   * V3TConfig3D.get<Name>
--   * V3TConfig.get<Name>Limits
--
-- The prettyName is used for info messages.
local function checker(name, prettyName)
  local function get_value(cfg)
    local getter = cfg['get' .. name]
    assert(getter ~= nil)
    return getter(cfg)
  end

  local function get_limits(cfg)
    local getterLimits = cfg['get' .. name .. 'Limits']
    assert(getterLimits ~= nil)
    return getterLimits(cfg)
  end

  local function get_value_s(cfg)
    return string.format('%.1f', get_value(cfg))
  end

  local function get_limits_s(cfg)
    local lower, upper = get_limits(cfg)
    return string.format('(%.1f, %.1f)', lower, upper)
  end

  local ch = {}

  ch.ok = function(cfg)
    local value = get_value(cfg)
    local lower, upper = get_limits(cfg)
    return lower <= value and value <= upper
  end

  ch.invalid = function(cfg)
    return not ch.ok(cfg)
  end

  -- Returns a string describing the out-of-range error of the
  -- parameter this checker handles or nil if the parameter is OK.
  ch.info = function(cfg)
    if not ch.ok(cfg) then
      return prettyName .. ' ' .. get_value_s(cfg) .. ' outside limits ' .. get_limits_s(cfg)
    end
    return nil
  end

  return ch
end

local checkers = {
  checker('FreeRunningSpeed', 'Speed'),
  checker('XResolution', 'X-Resolution'),
  checker('HeightmapLength', 'Heightmap length'),
  checker('ProfileDistance', 'Profile distance'),
  -- checker("ExposureTime", "Exposure"),
}

-- Returns a string describing which parameter is outside the limits
-- for a V3TConfig3D.
--
-- Returns an empty string ("") if the config is valid.
module.getErrorString3D = function(cfg3d)
  if cfg3d:validate() then
    return ''
  end

  for _, ch in ipairs(checkers) do
    local msg = ch.info(cfg3d)
    if msg ~= nil then
      return msg
    end
  end

  return 'Error in configuration.' -- Unknown error (no specific checker added)
end

return module
