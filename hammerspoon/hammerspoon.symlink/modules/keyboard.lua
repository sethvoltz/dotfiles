local hyper = { "shift", "cmd", "alt", "ctrl" }
local mash = { "ctrl", "alt", "cmd" }

-- Global shortcut to reload Hammerspoon
hs.hotkey.bind(hyper, "q", hs.reload)
hs.hotkey.bind(hyper, "a", hs.toggleConsole)

-- Helpful globals
-- hs.hotkey.bind(hyper, 'n', function() hs.task.new("/usr/bin/open", nil, {os.getenv("HOME")}):start() end)
-- hs.hotkey.bind(hyper, 'z', function() mouseHighlight() end)
-- hs.hotkey.bind(hyper, 'w', function() mouseMoveCurrentApp() end)

-- Move windows around current screen
-- hs.hotkey.bind(mash, "left",   function() window:leftHalf()   end);
-- hs.hotkey.bind(mash, "right",  function() window:rightHalf()  end);
-- hs.hotkey.bind(mash, "up",     function() window:topHalf()    end);
-- hs.hotkey.bind(mash, "down",   function() window:bottomHalf() end);
-- hs.hotkey.bind(hyper, "f",     function() window:maximize()   end)

-- Move between screens
-- hs.hotkey.bind(hyper, "left",  function() hs.window.focusedWindow():moveOneScreenWest() end)
-- hs.hotkey.bind(hyper, "right", function() hs.window.focusedWindow():moveOneScreenEast() end)

-- window = {}

-- local function currentFrame()
--   return hs.window.focusedWindow():frame()
-- end

-- local function currentScreenFrame()
--   return hs.window.focusedWindow():screen():frame()
-- end

-- function window:maximize ()
--   hs.window.focusedWindow():maximize()
-- end

-- function window:move (f, window)
--   if window == nil then
--     window = hs.window.focusedWindow()
--   end
--   local oldFrame = window:frame()
--   if oldFrame ~= f then
--     window:move(hs.geometry(f.x, f.y, f.w, f.h))
--   end
-- end

-- function window:leftHalf ()
--   local s = currentScreenFrame()
--   self:move({ x = s.x, y = s.y, w = (s.w / 2), h = s.h })
-- end

-- function window:rightHalf ()
--   local s = currentScreenFrame()
--   self:move({ x = (s.w / 2), y = s.y, w = (s.w / 2), h = s.h })
-- end

-- function window:topHalf ()
--   local s = currentScreenFrame()
--   self:move({ x = 0, y = s.y, w = s.w, h = (s.h / 2) })
-- end

-- function window:bottomHalf ()
--   local s = currentScreenFrame()
--   self:move({ x = 0, y = (s.h / 2) + s.y, w = s.w, h = (s.h / 2) })
-- end

-- function mouseMoveCurrentApp()
--   hs.mouse.setAbsolutePosition(hs.geometry.rectMidPoint(currentFrame()))
--   mouseHighlight()
-- end

-- local mouseOutlineColor = hs.drawing.color.asRGB({
--   red = 1,
--   green = 1,
--   blue = 1,
--   alpha = 0.6
-- })

-- local mouseColor = hs.drawing.color.asRGB({
--   red = 1,
--   green = 0.25,
--   blue = 0,
--   alpha = 0.9
-- })

-- -- Kudos to https://git.io/v6kcO
-- -- Modified for Canvas API
-- function mouseHighlight()
--   if mouseCircle ~= nil then
--     mouseCircle:delete()
--     mouseCircle = nil
--     if mouseCircleTimer then
--       mouseCircleTimer:stop()
--     end
--   end

--   local radius = 42
--   local outerStroke = 2
--   local innerStroke = 5

--   mousepoint = hs.mouse.getAbsolutePosition()
--   mouseCircle = hs.canvas.new{
--     x = mousepoint.x - radius - 1,
--     y = mousepoint.y - radius - 1,
--     w = radius * 2 + 2,
--     h = radius * 2 + 2
--   }:appendElements(
--     {
--       action = "build",
--       type = "circle",
--       reversePath = true,
--       radius = radius,
--       padding = 0,
--     }, {
--       action = "clip",
--       type = "circle",
--       padding = 0,
--       radius = radius - outerStroke,
--     }, {
--       action = "fill",
--       type = "rectangle",
--       fillColor = mouseOutlineColor,
--     }, {
--       type = "resetClip"
--     }, {
--       action = "build",
--       type = "circle",
--       radius = radius - outerStroke,
--       reversePath = true,
--       padding = 0,
--     }, {
--       action = "clip",
--       type = "circle",
--       padding = 0,
--       radius = radius - outerStroke - innerStroke,
--     }, {
--       action = "fill",
--       type = "rectangle",
--       fillColor = mouseColor,
--     }, {
--       type = "resetClip"
--     }, {
--       action = "build",
--       type = "circle",
--       radius = radius - outerStroke - innerStroke,
--       reversePath = true,
--       padding = 0,
--     }, {
--       action = "clip",
--       type = "circle",
--       padding = 0,
--       radius = radius - (outerStroke * 2) - innerStroke,
--     }, {
--       action = "fill",
--       type = "rectangle",
--       fillColor = mouseOutlineColor,
--     }, {
--       type = "resetClip"
--     }
--   ):show()

--   mouseCircleTimer = hs.timer.doAfter(1.5, function()
--     mouseCircle:hide(0.25)

--     hs.timer.doAfter(0.6, function()
--       if mouseCircle ~= nil then
--         mouseCircle:delete()
--         mouseCircle = nil
--       end
--     end)
--   end)
-- end
