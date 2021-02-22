local decorations = require('src.decorations')
local g = require('src.globals')
local ids = require('src.ids')
local util = require('src.util')

local app = {}

-- Adds the object trigger line  to the 3D viewer
local function createObjectTriggerLine()
  local line, _ = g.imageConfig3D:getObjectTriggerLine()
  g.viewer3D:addShape(line, decorations.triggerLine, ids.triggerLine)
  g.viewer3D:present()
end

app.setObjectTriggerLine = function()
  local fov = {g.imageConfig3D:getFieldOfView()}
  local p1 = util.clipPoint(g.objectTriggerPoint1, fov)
  local p2 = util.clipPoint(g.objectTriggerPoint2, fov)
  local line = Shape3D.createLineSegment(p1, p2)
  local _, percentage = g.imageConfig3D:getObjectTriggerLine() -- Reuse the percentage

  -- Workaround for percentage default value
  if percentage == 0 then
    g.imageConfig3D:setObjectTriggerLine(line, 20)
  else
    g.imageConfig3D:setObjectTriggerLine(line, percentage)
  end

  Config.validateConfig()
  createObjectTriggerLine()
end

app.GUIUpdateImageTrigger = function()
  local mode = Config.getImageTriggerMode()

  if mode == 2 then
    app.setObjectTriggerLine()
  else
    g.viewer3D:remove(ids.triggerLine)
  end

  Script.notifyEvent('OnSetTriggerModeNone', mode == 0)
  Script.notifyEvent('OnSetTriggerModeIO', mode == 1)
  Script.notifyEvent('OnSetTriggerModeObject', mode == 2)
  Script.notifyEvent('OnSetTriggerModeSoftware', mode == 3)
  Script.notifyEvent('OnImageTriggerModeSoftwareActive', mode == 3)

  g.viewer3D:present()
end

app.visualize = function()
  if Config.getImageTriggerMode() == 2 then
    createObjectTriggerLine()
  end
  g.viewer3D:present()
end

app.checkXResolutionLimits = function()
  local min,
    max = g.imageConfig3D:getXResolutionLimits()
  if min ~= g.xResMinLimit or max ~= g.xResMaxLimit then
    g.xResMinLimit = min
    g.xResMaxLimit = max
    Script.notifyEvent('OnXresMinLimit', util.round(min, 3))
    Script.notifyEvent('OnXresMaxLimit', util.round(max, 3))
  end
end

app.GUIUpdateLength = function()
  local _, max = app.getCfovLengthMax()
  Script.notifyEvent('OnFOVLengthMax', max)
  Script.notifyEvent('OnFOVLength', util.round(Config.getCfovLength(), 2))
end

-- Returns the guaranteed FOV for the device model selected in the UI drop down,
-- or for the device the app runs on.
local function getSelectedGuaranteedFOV(mode)
  if mode == 0 then
    -- Use the guaranteed FOV for the device the app runs on
    return g.imageConfig3D:getGuaranteedFieldOfView()
  elseif mode == 1 then
    return g.imageConfig3D:getGuaranteedFieldOfView('TriSpectorP 1008')
  elseif mode == 2 then
    return g.imageConfig3D:getGuaranteedFieldOfView('TriSpectorP 1030')
  elseif mode == 3 then
    return g.imageConfig3D:getGuaranteedFieldOfView('TriSpectorP 1060')
  end
end

-- Adds the guaranteed Field of View trapezoid-prism to the 3D-viewer
app.createGuaranteedFOV = function()
  if g.gfov == -1 then
    return -- Guaranteed FOV display disabled
  end

  local lowerWidth, upperWidth, height, xOffset, _ = getSelectedGuaranteedFOV(g.gfov)
  local _, length = g.imageConfig3D:getHeightmapLengthLimits()
  local width = lowerWidth / 2
  local widthTop = upperWidth / 2

  local p1 = Point.create(-width + xOffset, 0, 0)
  local p2 = Point.create(-widthTop + xOffset, 0, height)
  local p3 = Point.create(widthTop + xOffset, 0, height)
  local p4 = Point.create(width + xOffset, 0, 0)

  local pb1 = Point.create(-width + xOffset, length, 0)
  local pb2 = Point.create(-widthTop + xOffset, length, height)
  local pb3 = Point.create(widthTop + xOffset, length, height)
  local pb4 = Point.create(width + xOffset, length, 0)

  local front = Shape3D.createPolygon({p1, p2, p3, p4})
  local back = Shape3D.createPolygon({pb1, pb2, pb3, pb4})
  local left = Shape3D.createPolygon({p1, p2, pb2, pb1})
  local right = Shape3D.createPolygon({p3, p4, pb4, pb3})
  local top = Shape3D.createPolygon({p2, pb2, pb3, p3})
  local bottom = Shape3D.createPolygon({p1, pb1, pb4, p4})

  -- Add the shapes to the view. Use the front of the trapezoid as parent for all sides
  -- so the entire guaranteed field of view can be removed easily.
  for i, side in ipairs({front, back, left, right, top, bottom}) do
    local first = i == 1
    local id = util.if_else(first, ids.guaranteedFOV, nil) -- Only the front needs an explicit id
    local parent = util.if_else(first, nil, ids.guaranteedFOV) -- The rest use the front as parent
    g.viewer3D:addShape(side, decorations.guaranteedFOV, id, parent)
  end
end

-- Add the blue user-editable Field of View-box to the 3D-viewer
app.createUserFOV = function()
  local width, height, xOffset, zOffset = g.imageConfig3D:getFieldOfView()

  local minZ = zOffset - height / 2.0
  local maxZ = zOffset + height / 2.0
  decorations.image:setRange(minZ, maxZ)

  local length = g.imageConfig3D:getHeightmapLength()
  local pose = Transform.createTranslation3D(xOffset, length / 2, zOffset)
  local uFOV = Shape3D.createBox(width, length, height, pose)
  g.viewer3D:addShape(uFOV, decorations.userFOV, ids.FOV)
  g.viewer3D:installEditor(ids.FOV)
end

app.GUIUpdate = function()
  Script.notifyEvent('OnImageTrigger', Config.getImageTriggerMode())
  app.GUIUpdateImageTrigger()

  Script.notifyEvent('OnProfileTrigger', Config.getProfileTriggerMode())
  Script.notifyEvent('OnPeakSelection', Config.getPeakSelectionMode())
  Script.notifyEvent('OnEncoderPulses', Config.getEncoderPulsesPerMm())
  Script.notifyEvent('OnProfileDistance', Config.getProfileDistance())

  Script.notifyEvent('OnXResolution', Config.getXResolution())
  app.checkXResolutionLimits()

  Script.notifyEvent('OnExposure', Config.getExposure())
  Script.notifyEvent('OnLaserThreshold', Config.getLaserThreshold())
  app.GUIUpdateLength()

  app.createGuaranteedFOV()
  app.createUserFOV()
  app.visualize()
end

app.getCfovLengthMax = function()
  return g.imageConfig3D:getHeightmapLengthLimits()
end

app.loadConfig = function(path)
  local loadedConfig = Object.load(path)
  if loadedConfig == nil then
    print('Error: Failed loading configuration')
    return
  end

  g.imageConfig3D = loadedConfig
  if Config.validateConfig() then
    Config.setConfig()
  end
  app.GUIUpdate()
end

return app
