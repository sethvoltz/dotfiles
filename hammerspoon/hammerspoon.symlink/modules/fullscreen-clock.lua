local indicators = {}
local indicatorColor = hs.drawing.color.asRGB({ red = 0.4, green = 0.4, blue = 0.4, alpha = 0.4 })
local chargingColor = hs.drawing.color.asRGB({ red = 0.7, green = 0.3, blue = 0.0, alpha = 0.4 })
local chargedColor = hs.drawing.color.asRGB({ red = 0.0, green = 0.6, blue = 0.1, alpha = 0.4 })
local dangerColor = hs.drawing.color.asRGB({ red = 0.9, green = 0.1, blue = 0.1, alpha = 0.4 })

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
    if hasBattery() then
      drawScreenBattery(screen)
    end
  end
end

-- ------------------------------------------------------------= Indicators =--=

function drawScreenClock(screen)
  local screeng = screen:fullFrame()
  local clock = hs.styledtext.new(os.date("%H:%M"), clockStyle)
  local width = 180
  local height = 60
  local xOffset = hasBattery() and 25 or 5
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
  local strokeWidth = 1 * screen:currentMode().scale
  local width = 10
  local height = 42
  local fillHeight = math.max((height - (2 * strokeWidth)) * hs.battery.percentage() / 100.0, 1)
  local xOffset = 10
  local yOffset = 9

  indicatorOutline = hs.drawing.rectangle(hs.geometry.rect(
    screeng.x + screeng.w - width - xOffset,
    screeng.y + yOffset,
    width,
    height
  ))

  indicatorOutline
    :setLevel(hs.drawing.windowLevels.overlay)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :setStrokeWidth(strokeWidth)
    :setFill(false)
    :show()

  indicatorFill = hs.drawing.rectangle(hs.geometry.rect(
    screeng.x + screeng.w - width - xOffset + strokeWidth,
    screeng.y + yOffset + height - fillHeight - strokeWidth,
    width - (2 * strokeWidth),
    fillHeight
  ))

  indicatorFill
    :setLevel(hs.drawing.windowLevels.overlay)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :setStroke(false)
    :show()

  if hs.battery.isCharging() then
    indicatorOutline:setStrokeColor(chargingColor)
    indicatorFill:setFillColor(chargingColor)
  elseif hs.battery.isFinishingCharge() == true then
    indicatorOutline:setStrokeColor(chargedColor)
    indicatorFill:setFillColor(chargedColor)
  elseif hs.battery.percentage() <= 10 then
    indicatorOutline:setStrokeColor(dangerColor)
    indicatorFill:setFillColor(dangerColor)
  else
    indicatorOutline:setStrokeColor(indicatorColor)
    indicatorFill:setFillColor(indicatorColor)
  end

  table.insert(indicators, indicatorOutline)
  table.insert(indicators, indicatorFill)
end

function clearIndicators()
   for _, indicator in pairs(indicators) do
      indicator:delete()
   end
end

function hasBattery()
  return hs.battery.percentage() ~= nil
end

-- --------------------------------------------------------------= Watchers =--=

_clockSpaceWatcher = hs.spaces.watcher.new(updateClocks):start()
_clockAppWatcher   = hs.application.watcher.new(updateClocks):start()
_clockTimer        = hs.timer.new(hs.timer.seconds(15), updateClocks):start()
updateClocks()
