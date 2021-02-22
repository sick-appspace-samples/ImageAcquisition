------------------------------------------------------------------------------
-- Global variables stored in the table.
------------------------------------------------------------------------------
local ids = require('src.ids')

local g = {}

-- The 2D-viewer, showing sensor images, uses an ID defined in the SensorView
-- page in trispectorp.msdd to discern it from the 3D-viewer for events.
g.viewer2D = View.create(ids.viewer2D)

-- The 3D viewer (showing the heightmap and FOV boxes etc)
g.viewer3D = View.create()

-- The configuration for sensor image acquisition. Used with the g.imageProvider
-- when viewing the SensorView page.
g.imageConfig2D = Image.Provider.Camera.V3TConfig2D.create()

-- The configuration for heightmap acquisition. Used with the g.imageProvider
-- when viewing the ImageSetup page.
g.imageConfig3D = Image.Provider.Camera.V3TConfig3D.create()

-- Provider of acquired sensor images and heightmaps.
-- Configured with either g.imageConfig2D or g.imageConfig3D.
g.imageProvider = Image.Provider.Camera.create()

-- Last received image number
g.imageNumber = 0

g.xResMinLimit = 0.2
g.xResMaxLimit = 5

-- Guaranteed field of view selection (drop down)
g.gfov = 0

-- End-points for the object trigger line
g.objectTriggerPoint1 = Point.create(-50, 0, 10)
g.objectTriggerPoint2 = Point.create(50, 0, 10)

-- Path to the file used for saving and loading the g.imageConfig3D
g.jobPath = 'public/Image3DConfig.json'

return g
