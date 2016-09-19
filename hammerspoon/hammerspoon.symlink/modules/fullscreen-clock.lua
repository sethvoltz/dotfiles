local indicators = {}
local clockStyle = {
  font = {
      name = "Futura",
      size = 55
  },
  paragraphStyle = {
      alignment = "right",
  },
  color = hs.drawing.color.asRGB({
    red = 0.4,
    green = 0.4,
    blue = 0.4,
    alpha = 0.4
  }),
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

  indicator
    :setLevel(hs.drawing.windowLevels.overlay)
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
