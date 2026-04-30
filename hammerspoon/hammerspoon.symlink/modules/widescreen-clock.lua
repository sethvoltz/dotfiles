local widescreenIndicators = {}
local screenColors = {}
local white = { red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0 }
local black = { red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 }

local clockStyle = {
  font = {
      size = 13
  },
  paragraphStyle = {
      alignment = "center",
  },
  expansion = 0.02,
}

local function sampleMenubarColor(screen)
  local snapshot = screen:snapshot()
  if not snapshot then return black end

  local frame = screen:fullFrame()
  local pixel = snapshot:colorAt({ x = math.floor(frame.w / 2), y = 6 })
  if not pixel then return black end

  local luminance = 0.299 * pixel.red + 0.587 * pixel.green + 0.114 * pixel.blue
  return luminance < 0.5 and white or black
end

local function refreshMenubarColors()
  for _, screen in pairs(hs.screen.allScreens()) do
    screenColors[screen:id()] = sampleMenubarColor(screen)
  end
end

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
  
  clockStyle.color = screenColors[screen:id()] or black
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

local function refreshAndRedraw()
  refreshMenubarColors()
  updateWideScreenClocks()
end

-- --------------------------------------------------------------= Watchers =--=

_wideScreenClockSpaceWatcher = hs.spaces.watcher.new(refreshAndRedraw):start()
_wideScreenClockTimer        = hs.timer.new(hs.timer.seconds(15), updateWideScreenClocks):start()
_systemDarkModeWatcher       = hs.distributednotifications.new(refreshAndRedraw, 'AppleInterfaceThemeChangedNotification'):start()

refreshAndRedraw()
