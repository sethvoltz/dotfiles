local serial = require("hs._asm.serial")

local lastScreenId = -1
local usePhysicalIndicator = false
local useVirtualIndicator = true

local currentIndicator = nil
local indicatorHeight = 3 -- 0..1 = percent of menubar, >1 = pixel height
local indicatorColor = hs.drawing.color.asRGB({
  red = 0,
  green = 1.0,
  blue = 0,
  alpha = 0.3
})

-- ----------------------------------------------------------------------------= Event Handlers =--=

function handleMonitorMonitorChange()
  local focusedWindow = hs.window.focusedWindow()
  if not focusedWindow then return end

  local screen = focusedWindow:screen()
  local screenId = screen:id()
  if useVirtualIndicator then updateVirtualScreenIndicator(screen, focusedWindow) end

  if screenId == lastScreenId then return end
  lastScreenId = screenId

  if usePhysicalIndicator then updatePhysicalScreenIndicator(screenId) end
  print('Display changed to ' .. screenId)
end

function handleGlobalAppEvent(name, event, app)
  if event == hs.application.watcher.launched then
    watchApp(app)
  elseif event == hs.application.watcher.terminated then
    -- Clean up
    local appWatcher = _monitorAppWatchers[app:pid()]
    if appWatcher then
      appWatcher.watcher:stop()
      for id, watcher in pairs(appWatcher.windows) do
        watcher:stop()
      end
      _monitorAppWatchers[app:pid()] = nil
    end
  elseif event == hs.application.watcher.activated then
    handleMonitorMonitorChange()
  end
end

function handleAppEvent(element, event, watcher, info)
  if event == hs.uielement.watcher.windowCreated then
    watchWindow(element)
  elseif event == hs.uielement.watcher.focusedWindowChanged then
    if element:isWindow() or element:isApplication() then
      handleMonitorMonitorChange()
      updateVirtualScreenIndicator(element:screen(), element)
    end
  end
end

function handleWindowEvent(win, event, watcher, info)
  if event == hs.uielement.watcher.elementDestroyed then
    watcher:stop()
    _monitorAppWatchers[info.pid].windows[info.id] = nil
  end
end


-- ------------------------------------------------------------------------= Virtual Indicators =--=

-- Based heavily on https://git.io/v6kZN
function updateVirtualScreenIndicator(screen, window)
  clearIndicator()

  local screeng = screen:fullFrame()

  if indicatorHeight >= 0.0 and indicatorHeight <= 1.0 then
    height = indicatorHeight*(screen:frame().y - screeng.y)
  else
    height = indicatorHeight
  end

  if window:isFullScreen() then
    frame = window:frame()
    left = frame.x
    width = frame.w
  else
    left = screeng.x
    width = screeng.w
  end

  indicator = hs.drawing.rectangle(hs.geometry.rect(
    left,
    screeng.y,
    width,
    height
  ))

  indicator:setFillColor(indicatorColor)
    :setFill(true)
    :setLevel(hs.drawing.windowLevels.overlay)
    :setStroke(false)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
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

function updatePhysicalScreenIndicator(screenId)
  local devicePath = getSerialOutputDevice()
  if devicePath == "" then return end

  port = serial.port(devicePath):baud(115200):open()
  if port:isOpen() then
    port:write("set " .. screenId .. "\n")
    port:flushBuffer()
    port:close()
  end
end

function getSerialOutputDevice()
  local command = "ioreg -c IOSerialBSDClient -r -t " ..
    "| awk 'f;/com_silabs_driver_CP210xVCPDriver/{f=1};/IOCalloutDevice/{exit}' " ..
    "| sed -n 's/.*\"\\(\\/dev\\/.*\\)\".*/\\1/p'"
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()
  -- Strip whitespace - https://www.rosettacode.org/wiki/Strip_whitespace_from_a_string/Top_and_tail#Lua
  return result:match("^%s*(.-)%s*$")
end


-- ---------------------------------------------------------------------------= Watcher Helpers =--=

-- from https://gist.github.com/cmsj/591624ef07124ad80a1c
function attachExistingApps()
  local apps = hs.application.runningApplications()
  apps = hs.fnutils.filter(apps, function(app) return app:title() ~= "Hammerspoon" end)
  hs.fnutils.each(apps, function(app) watchApp(app, true) end)
end

function watchApp(app, initializing)
  if _monitorAppWatchers[app:pid()] then return end

  local watcher = app:newWatcher(handleAppEvent)
  if not watcher._element.pid then return end

  _monitorAppWatchers[app:pid()] = {
    watcher = watcher,
    windows = {}
  }

  watcher:start({ hs.uielement.watcher.focusedWindowChanged })

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
      hs.uielement.watcher.elementDestroyed,
      hs.uielement.watcher.windowResized,
      hs.uielement.watcher.windowMoved
    })
  end
end


-- ----------------------------------------------------------------------------------= Watchers =--=

_monitorAppWatchers = {}
attachExistingApps()

_monitorScreenWatcher = hs.screen.watcher.newWithActiveScreen(handleMonitorMonitorChange):start()
_monitorSpaceWatcher  = hs.spaces.watcher.new(handleMonitorMonitorChange):start()
_monitorAppWatcher    = hs.application.watcher.new(handleGlobalAppEvent):start()
handleMonitorMonitorChange() -- set the initial screen

-- Run this from the Hammerspoon console to get a listing of display IDs
function listAllScreens ()
  local primaryId = hs.screen.primaryScreen():id()
  for _, screen in pairs(hs.screen.allScreens()) do
    local screenId = screen:id()
    print(
      "id: " .. screenId ..
      " \"" .. screen:name() .. "\"" ..
      (screenId == primaryId and " (primary)" or "")
    )
  end
end
