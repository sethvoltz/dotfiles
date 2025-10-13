local widescreenIndicators = {}
local textColorLightMode = hs.drawing.color.asRGB({ red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 })
local textColorDarkMode = hs.drawing.color.asRGB({ red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0 })
local isDarkMode = false

local clockStyle = {
  font = {
      size = 13
  },
  paragraphStyle = {
      alignment = "center",
  },
  expansion = 0.02,
}

-- -------------------------------------------------------= Change Handlers =--=

function updateWideScreenClocks()
  clearWideScreenIndicators()

  for _, screen in pairs(hs.screen.allScreens()) do
    drawWideScreenClock(screen)
  end
end

-- ------------------------------------------------------------= Indicators =--=

function drawWideScreenClock(screen)
  local screeng = screen:fullFrame()
  local menubarHeight = screen:frame().y - screeng.y - 1

  local screenRatio = screeng.w / screeng.h
  if screenRatio < 2.5 then return end

  local currentScreenSpace = hs.spaces.activeSpaceOnScreen(screen)
  if currentScreenSpace == nil then return end
  if hs.spaces.spaceType(currentScreenSpace) == "fullscreen" then return end

  local fontInfo = hs.styledtext.fontInfo(clockStyle.font)
  local clockOffset = math.floor(menubarHeight - fontInfo.capHeight) / 2 - (fontInfo.ascender - fontInfo.capHeight)
  
  local clock = hs.styledtext.new(os.date("%a %b %d  %H:%M"), clockStyle)
  local width = 250
  local height = menubarHeight

  wideIndicator = hs.canvas.new{
    x = (screeng.x + screeng.w) / 2 - width / 2,
    y = screeng.y,
    w = width,
    h = height,
  }:appendElements(
    {
      action = "build",
      type = "text",
      text = clock,
      frame = {
        x = 0,
        y = clockOffset,
        w = width,
        h = height - clockOffset
      }
    }
  )
  
  wideIndicator
    :level(hs.canvas.windowLevels.cursor)
    :behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    :show()
  
  table.insert(widescreenIndicators, wideIndicator)
end

function clearWideScreenIndicators()
  for key, wideIndicator in pairs(widescreenIndicators) do
    wideIndicator:delete()
    widescreenIndicators[key] = nil
  end
end

local function getDarkModeFromSystem()
	local _, darkmode = hs.osascript.applescript("tell application \"System Events\" to tell appearance preferences to return dark mode")
  return darkmode
end

function updateSystemDarkMode(name, object, userInfo)
  local newDarkMode = getDarkModeFromSystem()
  if newDarkMode ~= isDarkMode then
    isDarkMode = newDarkMode
    clockStyle.color = isDarkMode and textColorDarkMode or textColorLightMode
    updateWideScreenClocks()
  end
end

-- --------------------------------------------------------------= Watchers =--=

_wideScreenClockSpaceWatcher = hs.spaces.watcher.new(updateWideScreenClocks):start()
_wideScreenClockTimer        = hs.timer.new(hs.timer.seconds(15), updateWideScreenClocks):start()
_systemDarkModeWatcher       = hs.distributednotifications.new(updateSystemDarkMode, 'AppleInterfaceThemeChangedNotification'):start()

updateSystemDarkMode()
updateWideScreenClocks()
