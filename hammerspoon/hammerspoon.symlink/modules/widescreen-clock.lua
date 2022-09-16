local widescreenIndicators = {}
local indicatorColor = hs.drawing.color.asRGB({ red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0 })

local clockStyle = {
  font = {
      size = 13
  },
  paragraphStyle = {
      alignment = "center",
  },
  expansion = 0.02,
  color = indicatorColor,
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

-- --------------------------------------------------------------= Watchers =--=

_wideScreenClockSpaceWatcher = hs.spaces.watcher.new(updateWideScreenClocks):start()
_wideScreenClockTimer        = hs.timer.new(hs.timer.seconds(15), updateWideScreenClocks):start()
updateWideScreenClocks()
