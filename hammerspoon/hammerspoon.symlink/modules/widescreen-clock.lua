local widescreenIndicators = {}
local white = { red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0 }
local black = { red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 }
local clockWidth = 250

local clockStyle = {
  font = {
      size = 13
  },
  paragraphStyle = {
      alignment = "center",
  },
  expansion = 0.02,
}

local function appearanceColor()
  return hs.host.interfaceStyle() == "Dark" and white or black
end

-- The menu bar is transparent, so its text follows the wallpaper rather than
-- the appearance setting. Sample either side of the clock so it never reads
-- its own text.
local function menubarColor(screen)
  local frame = screen:fullFrame()
  local snapshot = screen:snapshot({ x = 0, y = 0, w = frame.w, h = 10 })
  if not snapshot then return appearanceColor() end

  local middle = math.floor(frame.w / 2)
  local total, samples = 0, 0
  for _, x in ipairs({ middle - clockWidth / 2 - 20, middle + clockWidth / 2 + 20 }) do
    local pixel = snapshot:colorAt({ x = x, y = 6 })
    if pixel then
      total = total + 0.299 * pixel.red + 0.587 * pixel.green + 0.114 * pixel.blue
      samples = samples + 1
    end
  end
  if samples == 0 then return appearanceColor() end

  return total / samples < 0.5 and white or black
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
  
  clockStyle.color = menubarColor(screen)
  local clock = hs.styledtext.new(os.date("%a %b %d  %H:%M"), clockStyle)
  local width = clockWidth
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

-- --------------------------------------------------------------= Watchers =--=

_wideScreenClockSpaceWatcher = hs.spaces.watcher.new(updateWideScreenClocks):start()
_wideScreenClockTimer        = hs.timer.new(hs.timer.seconds(15), updateWideScreenClocks):start()
_systemDarkModeWatcher       = hs.distributednotifications.new(updateWideScreenClocks, 'AppleInterfaceThemeChangedNotification'):start()

updateWideScreenClocks()
