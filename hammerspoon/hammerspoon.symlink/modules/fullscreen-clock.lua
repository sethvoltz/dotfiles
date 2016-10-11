local indicators = {}
local indicatorColor = hs.drawing.color.asRGB({
  red = 0.4,
  green = 0.4,
  blue = 0.4,
  alpha = 0.4
})
local clockStyle = {
  font = {
      name = "Futura",
      size = 55
  },
  paragraphStyle = {
      alignment = "right",
  },
  color = indicatorColor,
}

-- -------------------------------------------------------= Change Handlers =--=

function updateClocks()
  clearIndicators()

  -- Get all windows, filter fullscreen
  screens = {}
  for _, window in pairs(hs.window.allWindows()) do
    if window:isFullScreen() then
      screens[window:screen()] = 1
    end
  end

  -- iterate unique for drawScreenClock
  for screen, _ in pairs(screens) do
    drawScreenClock(screen)
    drawScreenBattery(screen)
  end
end

-- ------------------------------------------------------------= Indicators =--=

function drawScreenClock(screen)
  local screeng = screen:fullFrame()
  local clock = hs.styledtext.new(os.date("%H:%M"), clockStyle)
  local width = 180
  local height = 60
  local xOffset = 25
  local yOffset = -6

  indicator = hs.drawing.text(hs.geometry.rect(
    screeng.x + screeng.w - width - xOffset,
    screeng.y + yOffset,
    width,
    height
  ), clock)

  indicator
    :setLevel(hs.drawing.windowLevels.overlay)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :show()

  table.insert(indicators, indicator)
end

function drawScreenBattery(screen)
  local screeng = screen:fullFrame()
  local width = 10
  local height = 42
  local fillHeight = height * hs.battery.percentage() / 100.0
  local xOffset = 10
  local yOffset = 9
  local strokeWidth = 1 * screen:currentMode().scale

  indicatorOutline = hs.drawing.rectangle(hs.geometry.rect(
    screeng.x + screeng.w - width - xOffset,
    screeng.y + yOffset,
    width,
    height
  ))

  indicatorOutline
    :setLevel(hs.drawing.windowLevels.overlay)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :setStrokeColor(indicatorColor)
    :setStrokeWidth(strokeWidth)
    :setFill(false)
    :show()

  indicatorFill = hs.drawing.rectangle(hs.geometry.rect(
    screeng.x + screeng.w - width - xOffset + strokeWidth,
    screeng.y + yOffset + strokeWidth + (height - fillHeight),
    width - (2 * strokeWidth),
    fillHeight - (2 * strokeWidth)
  ))

  indicatorFill
    :setLevel(hs.drawing.windowLevels.overlay)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :setFillColor(indicatorColor)
    :setStroke(false)
    :show()

  table.insert(indicators, indicatorOutline)
  table.insert(indicators, indicatorFill)
end

function clearIndicators()
   for _, indicator in pairs(indicators) do
      indicator:delete()
   end
end

-- --------------------------------------------------------------= Watchers =--=

_clockSpaceWatcher = hs.spaces.watcher.new(updateClocks):start()
_clockAppWatcher   = hs.application.watcher.new(updateClocks):start()
_clockTimer        = hs.timer.new(hs.timer.seconds(15), updateClocks):start()
updateClocks()
