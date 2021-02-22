--[[----------------------------------------------------------------------------

  Application Name:
  ImageAcquisition

  Summary:
  Setup image acquisition parameters for TriSpectorP

  Description:
  This sample includes a UI for viewing heightmaps and 2D sensor data from a
  TriSpectorP device, as well as controls for configuring image acquisition
  parameters.

  How to run:
  Starting this sample is possible either by running the app (F5) or
  debugging (F7+F10). Setting a breakpoint on the first row inside the 'main'
  function allows debugging step-by-step after the 'Engine.OnStarted' event.
  Image acquisition parameters can be configured in the UI on the DevicePage.
  You need to be connected to a TriSpectorP, this app does not work with the
  emulator.

  More Information:
  See tutorial: https://supportportal.sick.com/tutorial/trispectorp-image-acquisition/

------------------------------------------------------------------------------]]
local decorations = require('src.decorations') -- Shape decorations
local app = require('src.app')
local g = require('src.globals')
local ids = require('src.ids')
local serve = require('src.serve') -- Functions for Web-HMI

------------------------------------------------------------------------------
-- Callback functions
------------------------------------------------------------------------------
local function onNewImage(images, sensorData)
  if #images == 2 then
    -- Received a heightmap
    g.viewer3D:addHeightmap(images, decorations.image, 'Reflectance')
    g.viewer3D:present()

    g.imageNumber = sensorData:getFrameNumber()
    Script.notifyEvent('OnNewImageEvent', g.imageNumber) -- Notify Web HMI
  else
    -- Received a sensor image
    g.viewer2D:addImage(images[1])
    g.viewer2D:present()
  end
end

-- Start the image provider with the 2D-config to show sensor images
-- for the SensorView.
local function showSensorData()
  g.imageProvider:stop()

  -- Use the 2D-settings from the 3D-config, to show the sensor image with
  -- the same exposure settings and with the sensor region corresponding to
  -- the configured field of view.
  local cfg2D = g.imageConfig3D:get2DConfig()
  g.imageProvider:setConfig(cfg2D)
  g.imageProvider:start()
end

-- Start the image provider with the 3D-config to show heightmaps in the
-- ImageSetup view.
local function show3DData()
  g.imageProvider:stop()
  g.imageProvider:setConfig(g.imageConfig3D)
  g.imageProvider:start()
end

local function onViewer2DConnect()
  showSensorData()
end

local function onViewer3DConnect()
  show3DData()
  app.GUIUpdate()
end

-- @updateFOV(fovIconic:Shape3D)
-- Update the configuration with the FOV from the Field of View box.
local function updateFOV(fovIconic)
  local width, length, height, transform = fovIconic:getBoxParameters()

  local m = transform:getMatrix()
  local xOffset = m:getValue(0, 3)
  local zOffset = m:getValue(2, 3)

  g.imageConfig3D:setFieldOfView(width, height, xOffset, zOffset)
  g.imageConfig3D:setHeightmapLength(length)
  Script.notifyEvent('OnFOVX0', xOffset - width / 2.0)
  Script.notifyEvent('OnFOVX1', xOffset + width / 2.0)
  Script.notifyEvent('OnFOVZ0', zOffset - height / 2.0)
  Script.notifyEvent('OnFOVZ1', zOffset + height / 2.0)
  Script.notifyEvent('OnFOVLength', length)
  Config.validateConfig()
  app.createUserFOV()
end

local function onViewer3DChange(iconicID, iconic)
  if iconicID == ids.FOV then
    updateFOV(iconic)
  end
end

------------------------------------------------------------------------------
-- ImageAcquisition entry-point
------------------------------------------------------------------------------
local function main()
  serve.serveEvents()
  serve.serveFunctions()

  g.viewer2D:register('OnConnect', onViewer2DConnect)

  g.viewer3D:register('OnConnect', onViewer3DConnect)
  g.viewer3D:register('OnChange', onViewer3DChange)

  g.imageProvider:register('OnNewImage', onNewImage)
  g.imageProvider:start()

  if File.exists(g.jobPath) then
    app.loadConfig(g.jobPath)
  end
end

Script.register('Engine.OnStarted', main)
