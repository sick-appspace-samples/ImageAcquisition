------------------------------------------------------------------------------
-- Implementation of methods for the Config-CROWN served by this App.
--
-- The getters and setters are used by controls in the trispectorp.msdd
-- to connect the sliders, buttons and text-fields with the values
-- used in the application.
------------------------------------------------------------------------------
local app = require('src.app')
local g = require('src.globals')
local ids = require('src.ids')
local util = require('src.util')
local Fov = require('src.fov')
local convert = util.convert
local errorinfo = require('src.errorinfo')

local module = {}

module.serveFunctions = function()
  ------------------------------------------------------------------------------
  -- Getters
  ------------------------------------------------------------------------------
  Script.serveFunction(
    'Config.getCfovLength',
    function()
      return g.imageConfig3D:getHeightmapLength()
    end
  )

  Script.serveFunction(
    'Config.getCfovXMax',
    function()
      local width, _, xOffset, _ = g.imageConfig3D:getFieldOfView()
      return xOffset + width / 2
    end
  )

  Script.serveFunction(
    'Config.getCfovXMin',
    function()
      local width, _, xOffset, _ = g.imageConfig3D:getFieldOfView()
      return xOffset - width / 2
    end
  )

  Script.serveFunction(
    'Config.getCfovZMax',
    function()
      local _, height, _, zOffset = g.imageConfig3D:getFieldOfView()
      return zOffset + height / 2
    end
  )

  Script.serveFunction(
    'Config.getCfovZMin',
    function()
      local _, height, _, zOffset = g.imageConfig3D:getFieldOfView()
      return zOffset - height / 2
    end
  )

  Script.serveFunction(
    'Config.getConfigValid',
    function()
      return g.imageConfig3D:validate()
    end
  )

  Script.serveFunction(
    'Config.getEncoderPulsesPerMm',
    function()
      return util.round(g.imageConfig3D:getEncoderTicksPerMm(), 3)
    end
  )

  Script.serveFunction(
    'Config.getExposure',
    function()
      return g.imageConfig3D:getExposureTime()
    end
  )

  Script.serveFunction(
    'Config.getFrameNumber',
    function()
      return g.imageNumber
    end
  )

  Script.serveFunction(
    'Config.getGFOV',
    function()
      return g.gfov
    end
  )

  Script.serveFunction(
    'Config.getGain',
    function()
      return g.imageConfig3D:getGain()
    end
  )

  Script.serveFunction(
    'Config.getImageTriggerDelay',
    function()
      local delay, _ = g.imageConfig3D:getImageTriggerDelay()
      return delay
    end
  )

  Script.serveFunction(
    'Config.getImageTriggerDelayUnit',
    function()
      local _,
        unit = g.imageConfig3D:getImageTriggerDelay()
      if unit == 'MS' then
        return 0
      else
        return 1
      end
    end
  )

  Script.serveFunction(
    'Config.getImageTriggerMode',
    function()
      return convert.imageTriggerMode.toValue( g.imageConfig3D:getImageTriggerMode() )
    end
  )

  Script.serveFunction(
    'Config.getLaserThreshold',
    function()
      return g.imageConfig3D:getLaserThreshold()
    end
  )

  Script.serveFunction(
    'Config.getPeakSelectionMode',
    function()
      return convert.peakSelectionMode.toValue( g.imageConfig3D:getPeakSelectionMode() )
    end
  )

  Script.serveFunction(
    'Config.getProfileDistance',
    function()
      return util.round(g.imageConfig3D:getProfileDistance(), 3)
    end
  )

  Script.serveFunction(
    'Config.getProfileTriggerMode',
    function()
      local mode = convert.profileTriggerMode.toValue( g.imageConfig3D:getProfileTriggerMode() )
      Config.setProfileTriggerMode(mode) -- fix to get the Web HMI to show the speed slider
      return mode
    end
  )

  Script.serveFunction(
    'Config.getProfileTriggerModeInverted',
    function()
      return 1 - convert.profileTriggerMode.toValue( g.imageConfig3D:getProfileTriggerMode() )
    end
  )

  Script.serveFunction(
    'Config.getSpeed',
    function()
      return g.imageConfig3D:getFreeRunningSpeed()
    end
  )

  Script.serveFunction(
    'Config.getFreeRunningSpeedLimitMax',
    function()
      local _, max = g.imageConfig3D:getFreeRunningSpeedLimits()
      return max
    end
  )

  Script.serveFunction(
    'Config.getXResolution',
    function()
      return util.round(g.imageConfig3D:getXResolution(), 3)
    end
  )

  Script.serveFunction(
    'Config.getXResolutionLimitMax',
    function()
      local _, xResMaxLimit = g.imageConfig3D:getXResolutionLimits()
      return xResMaxLimit
    end
  )

  Script.serveFunction(
    'Config.getXResolutionLimitMin',
    function()
      local xResMinLimit, _ = g.imageConfig3D:getXResolutionLimits()
      return xResMinLimit
    end
  )

  Script.serveFunction(
    'Config.isImageTriggerModeIO',
    function()
      return g.imageConfig3D:getImageTriggerMode() == 'IO_3'
    end
  )

  Script.serveFunction(
    'Config.isImageTriggerModeSoftware',
    function()
      return g.imageConfig3D:getImageTriggerMode() == 'SOFTWARE'
    end
  )

  Script.serveFunction(
    'Config.isImageTriggerModeSoftwareActive',
    function()
      return g.imageConfig3D:getProfileTriggerMode() == 'SOFTWARE'
    end
  )

  Script.serveFunction(
    'Config.validateConfig',
    function()
      local configValid = g.imageConfig3D:validate()
      Script.notifyEvent('OnValidateConfig', configValid)
      app.checkXResolutionLimits()

      -- Print maximum movement speed from acquisition
      local max = Config.getFreeRunningSpeedLimitMax()
      Script.notifyEvent('OnMaxFreerunningSpeed', util.round(max, 1))
      print('-----------------------------------------')
      print('Max speed from acq: ' .. util.round(max / 1000, 2) .. ' m/s')
      print('-----------------------------------------')

      Script.notifyEvent(
        'OnConfigError',
        errorinfo.getErrorString3D(g.imageConfig3D)
      )
      return configValid
    end
  )

  ------------------------------------------------------------------------------
  -- Setters
  ------------------------------------------------------------------------------
  Script.serveFunction(
    'Config.setConfig',
    function()
      -- Write the configuration to the device.
      -- The provider will be stopped to be able to receive the configuration.
      g.imageProvider:stop()
      local configValid = g.imageConfig3D:validate()

      if configValid then
        g.imageProvider:setConfig(g.imageConfig3D)

        g.imageProvider:start()
        Script.notifyEvent(
          'OnImageTriggerModeSoftwareActive',
          Config.getImageTriggerMode() == 3
        )
      else
        print('Invalid config')
      end
    end
  )

  Script.serveFunction(
    'Config.saveConfig',
    function()
      -- Save the configuration to a json file
      local ok = Object.save(g.imageConfig3D, g.jobPath)
      if ok then
        print('Saved configuration to ' .. g.jobPath)
      else
        print('Error: Failed saving configuration to ' .. g.jobPath)
      end
    end
  )

  Script.serveFunction(
    'Config.loadConfig',
    function()
      if not File.exists(g.jobPath) then
        print('Error: File not found: ' .. g.jobPath)
        return
      end
      app.loadConfig(g.jobPath)
    end
  )

  Script.serveFunction(
    'Config.setProfileTriggerMode',
    function(value)
      local profileTriggerMode = convert.profileTriggerMode.toString(value)
      g.imageConfig3D:setProfileTriggerMode(profileTriggerMode)
      Script.notifyEvent( 'OnSetFreerunningMode', profileTriggerMode == 'FREE_RUNNING' )
      Script.notifyEvent('OnSetEncoderMode', profileTriggerMode == 'ENCODER')
      Config.validateConfig()
    end
  )

  Script.serveFunction(
    'Config.setSpeed',
    function(Speed)
      g.imageConfig3D:setFreeRunningSpeed(Speed)
      Config.validateConfig()
    end
  )

  Script.serveFunction(
    'Config.setEncoderPulsesPerMm',
    function(encoderTicksPerMm)
      g.imageConfig3D:setEncoderTicksPerMm(encoderTicksPerMm)
      Config.validateConfig()
    end
  )

  Script.serveFunction(
    'Config.setProfileDistance',
    function(ProfileDistance)
      g.imageConfig3D:setProfileDistance(ProfileDistance)
      app.getCfovLengthMax()
      Config.validateConfig()
      app.visualize()
    end
  )

  Script.serveFunction(
    'Config.setXResolution',
    function(XResolution)
      g.imageConfig3D:setXResolution(util.round(XResolution, 3))
      app.getCfovLengthMax()
      Config.validateConfig()
    end
  )

  Script.serveFunction(
    'Config.setExposure',
    function(Exposure)
      g.imageConfig3D:setExposureTime(Exposure)
      Config.validateConfig()
    end
  )

  Script.serveFunction(
    'Config.setGain',
    function(gain)
      g.imageConfig3D:setGain(gain)
    end
  )

  Script.serveFunction(
    'Config.setLaserThreshold',
    function(LaserThreshold)
      g.imageConfig3D:setLaserThreshold(LaserThreshold)
    end
  )

  Script.serveFunction(
    'Config.setPeakSelectionMode',
    function(mode)
      local s = convert.peakSelectionMode.toString(mode)
      g.imageConfig3D:setPeakSelectionMode(s)
    end
  )

  Script.serveFunction(
    'Config.setImageTriggerMode',
    function(mode)
      local s = convert.imageTriggerMode.toString(mode)
      g.imageConfig3D:setImageTriggerMode(s)
      app.GUIUpdateImageTrigger()
      Config.validateConfig()
    end
  )

  Script.serveFunction(
    'Config.setImageTriggerDelay',
    function(delay)
      local _, unit = g.imageConfig3D:getImageTriggerDelay()
      g.imageConfig3D:setImageTriggerDelay(delay, unit)
    end
  )

  Script.serveFunction(
    'Config.setImageTriggerDelayUnit',
    function(unitIndex)
      local delay, _ = g.imageConfig3D:getImageTriggerDelay()
      local unit = convert.triggerDelayUnit.toString(unitIndex)
      g.imageConfig3D:setImageTriggerDelay(delay, unit)
    end
  )

  Script.serveFunction(
    'Config.setObjectTriggerPercentage',
    function(newPercentage)
      local line, _ = g.imageConfig3D:getObjectTriggerLine()
      g.imageConfig3D:setObjectTriggerLine(line, newPercentage)
    end
  )

  Script.serveFunction(
    'Config.setObjectTriggerPoint1X',
    function(value)
      if g.imageConfig3D:getImageTriggerMode() == 'OBJECT' then
        g.objectTriggerPoint1:setX(util.round(value, 1))
        app.setObjectTriggerLine()
      end
    end
  )

  Script.serveFunction(
    'Config.setObjectTriggerPoint2X',
    function(value)
      if g.imageConfig3D:getImageTriggerMode() == 'OBJECT' then
        g.objectTriggerPoint2:setX(util.round(value, 1))
        app.setObjectTriggerLine()
      end
    end
  )

  Script.serveFunction(
    'Config.setObjectTriggerPoint1Z',
    function(value)
      if g.imageConfig3D:getImageTriggerMode() == 'OBJECT' then
        g.objectTriggerPoint1:setZ(util.round(value, 1))
        app.setObjectTriggerLine()
      end
    end
  )

  Script.serveFunction(
    'Config.setObjectTriggerPoint2Z',
    function(value)
      if g.imageConfig3D:getImageTriggerMode() == 'OBJECT' then
        g.objectTriggerPoint2:setZ(util.round(value, 1))
        app.setObjectTriggerLine()
      end
    end
  )

  Script.serveFunction(
    'Config.setForceTrigger',
    function()
      g.imageProvider:trigger(true)
    end
  )

  Script.serveFunction(
    'Config.setCfovZMin',
    function(zMin)
      Fov.setTo(Fov.copyFrom(g.imageConfig3D, {zMin = zMin}), g.imageConfig3D)
      Config.validateConfig()
      app.createUserFOV()
      app.visualize()
    end
  )

  Script.serveFunction(
    'Config.setCfovZMax',
    function(zMax)
      Fov.setTo(Fov.copyFrom(g.imageConfig3D, {zMax = zMax}), g.imageConfig3D)
      Config.validateConfig()
      app.createUserFOV()
      app.visualize()
    end
  )

  Script.serveFunction(
    'Config.setCfovXMin',
    function(xMin)
      Fov.setTo(Fov.copyFrom(g.imageConfig3D, {xMin = xMin}), g.imageConfig3D)
      Config.validateConfig()
      app.createUserFOV()
      app.visualize()
    end
  )

  Script.serveFunction(
    'Config.setCfovXMax',
    function(xMax)
      Fov.setTo(Fov.copyFrom(g.imageConfig3D, {xMax = xMax}), g.imageConfig3D)
      Config.validateConfig()
      app.createUserFOV()
      app.visualize()
    end
  )

  Script.serveFunction(
    'Config.setCfovLength',
    function(length)
      g.imageConfig3D:setHeightmapLength(length)
      Config.validateConfig()
      app.createUserFOV()
      app.visualize()
    end
  )

  Script.serveFunction(
    'Config.setGFOV',
    function(fov)
      g.gfov = fov
      g.viewer3D:remove(ids.guaranteedFOV)
      app.createGuaranteedFOV()
      g.viewer3D:present()
    end
  )
end

-- Serve events for usage in web HMI
module.serveEvents = function()
  Script.serveEvent( 'Config.OnImageTriggerModeSoftwareActive', 'OnImageTriggerModeSoftwareActive' )
  Script.serveEvent('Config.OnNewImageEvent', 'OnNewImageEvent')
  Script.serveEvent('Config.OnSetEncoderMode', 'OnSetEncoderMode')
  Script.serveEvent('Config.OnSetFreerunningMode', 'OnSetFreerunningMode')
  Script.serveEvent('Config.OnSetTriggerModeIO', 'OnSetTriggerModeIO')
  Script.serveEvent('Config.OnSetTriggerModeNone', 'OnSetTriggerModeNone')
  Script.serveEvent('Config.OnSetTriggerModeObject', 'OnSetTriggerModeObject')
  Script.serveEvent( 'Config.OnSetTriggerModeSoftware', 'OnSetTriggerModeSoftware' )
  Script.serveEvent('Config.OnValidateConfig', 'OnValidateConfig')
  Script.serveEvent('Config.OnXresMaxLimit', 'OnXresMaxLimit')
  Script.serveEvent('Config.OnXresMinLimit', 'OnXresMinLimit')
  Script.serveEvent('Config.OnProfileTrigger', 'OnProfileTrigger')
  Script.serveEvent('Config.OnPeakSelection', 'OnPeakSelection')
  Script.serveEvent('Config.OnImageTrigger', 'OnImageTrigger')
  Script.serveEvent('Config.OnEncoderPulses', 'OnEncoderPulses')
  Script.serveEvent('Config.OnFOVLength', 'OnFOVLength')
  Script.serveEvent('Config.OnFOVLengthMax', 'OnFOVLengthMax')
  Script.serveEvent('Config.OnProfileDistance', 'OnProfileDistance')
  Script.serveEvent('Config.OnXResolution', 'OnXResolution')
  Script.serveEvent('Config.OnExposure', 'OnExposure')
  Script.serveEvent('Config.OnLaserThreshold', 'OnLaserThreshold')
  Script.serveEvent('Config.OnMaxFreerunningSpeed', 'OnMaxFreerunningSpeed')
  Script.serveEvent('Config.OnFOVX0', 'OnFOVX0')
  Script.serveEvent('Config.OnFOVX1', 'OnFOVX1')
  Script.serveEvent('Config.OnFOVZ0', 'OnFOVZ0')
  Script.serveEvent('Config.OnFOVZ1', 'OnFOVZ1')
  Script.serveEvent('Config.OnConfigError', 'OnConfigError')
end

return module
