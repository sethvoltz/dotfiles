local window,screen=require'hs.window',require'hs.screen'
local application,spaces=require'hs.application',require'hs.spaces'
local drawing,canvas=require'hs.drawing',require'hs.canvas'
local uielement=require'hs.uielement'
local fnutils=require'hs.fnutils'
-- local serial = require("hs._asm.serial")

local lastScreenId = -1
-- local usePhysicalIndicator = false
local useVirtualIndicator = true

local currentIndicator = nil
local indicatorBottomHeight = 2
local indicatorTopColor = drawing.color.asRGB({
  red = 0.99,
  green = 0.76,
  blue = 0.25,
  alpha = 0.2
})
local indicatorBottomColor = drawing.color.asRGB({
  red = 0.99,
  green = 0.76,
  blue = 0.25,
  alpha = 0.6
})

-- ----------------------------------------------------------------------------= Event Handlers =--=

function handleMonitorMonitorChange()
  local focusedWindow = window.focusedWindow()
  if not focusedWindow then return end
  
  local screen = focusedWindow:screen()
  local screenId = screen:id()
  if useVirtualIndicator then updateVirtualScreenIndicator(screen, focusedWindow) end
  
  if screenId == lastScreenId then return end
  lastScreenId = screenId
  
  -- if usePhysicalIndicator then updatePhysicalScreenIndicator(screenId) end
  print('Display changed to ' .. screenId)
end

function handleGlobalAppEvent(name, event, app)
  if event == application.watcher.launched then
    watchApp(app)
  elseif event == application.watcher.terminated then
    -- Clean up
    local appWatcher = _monitorAppWatchers[app:pid()]
    if appWatcher then
      appWatcher.watcher:stop()
      for id, watcher in pairs(appWatcher.windows) do
        watcher:stop()
      end
      _monitorAppWatchers[app:pid()] = nil
    end
  elseif event == application.watcher.activated then
    handleMonitorMonitorChange()
  end
end

function handleAppEvent(element, event, watcher, info)
  if event == uielement.watcher.windowCreated then
    watchWindow(element)
  elseif event == uielement.watcher.focusedWindowChanged then
    if element:isWindow() or element:isApplication() then
      handleMonitorMonitorChange()
    end
  end
end

function handleWindowEvent(win, event, watcher, info)
  if event == uielement.watcher.elementDestroyed then
    watcher:stop()
    _monitorAppWatchers[info.pid].windows[info.id] = nil
  else
    handleMonitorMonitorChange()
  end
end


-- ------------------------------------------------------------------------= Virtual Indicators =--=

-- Based heavily on https://git.io/v6kZN
function updateVirtualScreenIndicator(screen, window)
  clearIndicator()

  local screeng = screen:fullFrame()
  local frame = window:frame()
  local left = frame.x
  local width = frame.w
  local menubarHeight = screen:frame().y - screeng.y - 1
  local indicatorTopHeight = menubarHeight - indicatorBottomHeight
  
  indicator = canvas.new{
    x = left,
    y = screeng.y,
    w = width,
    h = menubarHeight
  }:appendElements(
    {
      action = "fill",
      type = "rectangle",
      frame = {
        x = 0,
        y = 0,
        w = width,
        h = indicatorTopHeight
      },
      fillColor = indicatorTopColor
    },
    {
      action = "fill",
      type = "rectangle",
      frame = {
        x = 0,
        y = indicatorTopHeight,
        w = width,
        h = indicatorBottomHeight
      },
      fillColor = indicatorBottomColor
    }
  )

  indicator
    :level(canvas.windowLevels.cursor)
    :behavior(canvas.windowBehaviors.canJoinAllSpaces)
    :show()

  currentIndicator = indicator
end

function clearIndicator()
   if currentIndicator ~= nil then
      currentIndicator:delete()
      currentIndicator = nil
   end
end


-- -----------------------------------------------------------------------= Physical Indicators =--=

-- function updatePhysicalScreenIndicator(screenId)
--   local devicePath = getSerialOutputDevice()
--   if devicePath == "" then return end

--   port = serial.port(devicePath):baud(115200):open()
--   if port:isOpen() then
--     port:write("set " .. screenId .. "\n")
--     port:flushBuffer()
--     port:close()
--   end
-- end

-- function getSerialOutputDevice()
--   local command = "ioreg -c IOSerialBSDClient -r -t " ..
--     "| awk 'f;/com_silabs_driver_CP210xVCPDriver/{f=1};/IOCalloutDevice/{exit}' " ..
--     "| sed -n 's/.*\"\\(\\/dev\\/.*\\)\".*/\\1/p'"
--   local handle = io.popen(command)
--   local result = handle:read("*a")
--   handle:close()
--   -- Strip whitespace - https://www.rosettacode.org/wiki/Strip_whitespace_from_a_string/Top_and_tail#Lua
--   return result:match("^%s*(.-)%s*$")
-- end

-- ---------------------------------------------------------------------------= Watcher Helpers =--=

-- from https://gist.github.com/cmsj/591624ef07124ad80a1c
function attachExistingApps()
  local apps = application.runningApplications()
  apps = fnutils.filter(apps, function(app) return app:title() ~= "Hammerspoon" end)
  fnutils.each(apps, function(app) watchApp(app, true) end)
end

function watchApp(app, initializing)
  if _monitorAppWatchers[app:pid()] then return end
  
  local watcher = app:newWatcher(handleAppEvent)
  if not watcher.pid then return end
  
  _monitorAppWatchers[app:pid()] = {
    watcher = watcher,
    windows = {}
  }
  
  -- kind() returns -1 if the app is prohibited from GUI components
  if app:kind() == -1 then return end

  watcher:start({ uielement.watcher.focusedWindowChanged })
  
  -- Watch any windows that already exist
  for i, window in pairs(app:allWindows()) do
    watchWindow(window, initializing)
  end
end

function watchWindow(win, initializing)
  local appWindows = _monitorAppWatchers[win:application():pid()].windows

  if win:isStandard() and not appWindows[win:id()] then
    local watcher = win:newWatcher(handleWindowEvent, {
      pid = win:pid(),
      id = win:id()
    })
    appWindows[win:id()] = watcher

    watcher:start({
      uielement.watcher.elementDestroyed,
      uielement.watcher.windowResized,
      uielement.watcher.windowMoved,
      uielement.watcher.windowMinimized,
      uielement.watcher.windowUnminimized
    })
  end
end


-- ----------------------------------------------------------------------------------= Watchers =--=

_monitorAppWatchers = {}
attachExistingApps()

_monitorScreenWatcher = screen.watcher.newWithActiveScreen(handleMonitorMonitorChange):start()
_monitorSpaceWatcher  = spaces.watcher.new(handleMonitorMonitorChange):start()
_monitorAppWatcher    = application.watcher.new(handleGlobalAppEvent):start()
handleMonitorMonitorChange() -- set the initial screen

-- Run this from the Hammerspoon console to get a listing of display IDs
function listAllScreens ()
  local primaryId = screen.primaryScreen():id()
  for _, screen in pairs(screen.allScreens()) do
    local screenId = screen:id()
    print(
      "id: " .. screenId ..
      " \"" .. screen:name() .. "\"" ..
      (screenId == primaryId and " (primary)" or "")
    )
  end
end
