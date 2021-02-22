-- Module for creating a FOV expressed as xMin to xMax, zMin to zMax
--
-- This is more useful for the UI than width, height, xOffset,
-- zOffset.

local module = {}

-- Set the fov to the config
module.setTo = function(fov, cfg)
  local width = fov.xMax - fov.xMin
  local height = fov.zMax - fov.zMin
  local xOffset = fov.xMin + width / 2.0
  local zOffset = fov.zMax - height / 2.0
  cfg:setFieldOfView(width, height, xOffset, zOffset)
end

-- Copy the fov from the cfg
module.copyFrom = function(cfg, modifications)
  local width, height, xOffset, zOffset = cfg:getFieldOfView()
  local fov = {}

  local rx = width / 2.0
  fov.xMin = xOffset - rx
  fov.xMax = xOffset + rx

  local rz = height / 2.0
  fov.zMin = zOffset - rz
  fov.zMax = zOffset + rz

  if modifications ~= nil then
    for k, v in pairs(modifications) do
      fov[k] = v
    end
  end

  fov.setTo = module.setTo

  return fov
end

return module
