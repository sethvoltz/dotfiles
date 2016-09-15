local indicators = {}
local indicatorColor = hs.drawing.color.asRGB({
  red = 0.3,
  green = 0.3,
  blue = 0.3,
  alpha = 0.2
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
  end
end

-- ------------------------------------------------------------= Indicators =--=

function drawScreenClock(screen)
  local screeng = screen:fullFrame()
  local clock = hs.styledtext.new(os.date("%H:%M"), clockStyle)
  local width = 180
  local height = 60

  indicator = hs.drawing.text(hs.geometry.rect(
    screeng.x + screeng.w - width,
    screeng.y - 6,
    width,
    height
  ), clock)

  indicator:setFillColor(indicatorColor)
    :setFill(true)
    :setLevel(hs.drawing.windowLevels.overlay)
    :setStroke(false)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :show()

  table.insert(indicators, indicator)
end

function clearIndicators()
   for _, indicator in pairs(indicators) do
      indicator:delete()
   end
end

-- --------------------------------------------------------------= Watchers =--=

hs.spaces.watcher.new(updateClocks):start()
hs.application.watcher.new(updateClocks):start()
hs.timer.new(15, updateClocks):start()
updateClocks()
