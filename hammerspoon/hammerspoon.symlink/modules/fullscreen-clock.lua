local indicators = {}
local indicatorColor = hs.drawing.color.asRGB({ red = 0.5, green = 0.5, blue = 0.5, alpha = 0.4 })
local dateColor = hs.drawing.color.asRGB({ red = 0.6, green = 0.6, blue = 0.6, alpha = 0.4 })
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

local monthStyle = {
  font = {
      name = "Futura Condensed Medium",
      size = 21
  },
  kerning = 3.0,
  paragraphStyle = {
      alignment = "center",
  },
  color = dateColor,
}

local dayStyle = {
  font = {
      name = "Futura Condensed ExtraBold",
      size = 27
  },
  paragraphStyle = {
      alignment = "center",
  },
  color = dateColor,
}

-- -------------------------------------------------------= Change Handlers =--=

function updateFullScreenClocks()
  clearFullScreenIndicators()

  -- Get all windows, filter fullscreen
  screens = {}
  for _, window in pairs(hs.window.allWindows()) do
    if window:isFullScreen() then
      screens[window:screen()] = 1
    end
  end

  -- iterate unique for drawFullScreenClock
  for screen, _ in pairs(screens) do
    drawFullScreenClock(screen)
    if hasFullScreenBattery() then
      drawFullScreenBattery(screen)
    end
  end
end

-- ------------------------------------------------------------= Indicators =--=

function drawFullScreenClock(screen)
  local screeng = screen:fullFrame()
  local clock = hs.styledtext.new(os.date("%H:%M"), clockStyle)
  local month = hs.styledtext.new(os.date("%b"), monthStyle):upper()
  local day = hs.styledtext.new(os.date("%d"), dayStyle)
  local width = 200
  local height = 60
  local xOffset = hasFullScreenBattery() and 25 or 5
  local yOffset = -6

  indicator = hs.canvas.new{
    x = screeng.x + screeng.w - width - xOffset,
    y = screeng.y + yOffset,
    w = width,
    h = height,
  }:appendElements(
    {
      action = "build",
      type = "text",
      text = clock
    },
    {
      action = "build",
      type = "text",
      text = month,
      frame = {
        x = width - 161 - xOffset,
        y = 10,
        w = 40,
        h = height
      }
    },
    {
      action = "build",
      type = "text",
      text = day,
      frame = {
        x = width - 162 - xOffset,
        y = 29,
        w = 40,
        h = height
      }
    }
  )
  
  indicator
    :level(hs.canvas.windowLevels.cursor)
    :behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    :show()
  
  table.insert(indicators, indicator)
end

function drawFullScreenBattery(screen)
  local screeng = screen:fullFrame()
  local strokeWidth = 1 * screen:currentMode().scale
  local width = 10
  local height = 42
  local fillHeight = math.max((height - (2 * strokeWidth)) * hs.battery.percentage() / 100.0, 1)
  local xOffset = 10
  local yOffset = 9

  local currentColor = indicatorColor
  
  if hs.battery.isCharging() then
    currentColor = chargingColor
  elseif hs.battery.isFinishingCharge() == true then
    currentColor = chargedColor
  elseif hs.battery.percentage() <= 10 then
    currentColor = dangerColor
  end

  indicator = hs.canvas.new{
    x = screeng.x + screeng.w - width - xOffset,
    y = screeng.y + yOffset,
    w = width,
    h = height
  }:appendElements(
    {
      action = "stroke",
      type = "rectangle",
      padding = 0,
      strokeColor = currentColor,
      strokeWidth = strokeWidth,
    }, {
      action = "fill",
      type = "rectangle",
      frame = {
        x = strokeWidth,
        y = height - fillHeight - strokeWidth,
        w = width - (2 * strokeWidth),
        h = fillHeight
      },
      fillColor = currentColor
    }
  )
  
  indicator
    :level(hs.canvas.windowLevels.cursor)
    :behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    :show()

  table.insert(indicators, indicator)
end

function clearFullScreenIndicators()
   for key, indicator in pairs(indicators) do
      indicator:delete()
      indicators[key] = nil
   end
end

function hasFullScreenBattery()
  return hs.battery.percentage() ~= nil
end

-- --------------------------------------------------------------= Watchers =--=

-- No need to show this on Notched Macs (need a better way)
local handle = io.popen("sysctl -n machdep.cpu.brand_string")
local result = handle:read("*a")
handle:close()
if result:match("M1 Max") == nil and result:match("M1 Pro") == nil then
  _fullScreenClockSpaceWatcher = hs.spaces.watcher.new(updateFullScreenClocks):start()
  _fullScreenClockAppWatcher   = hs.application.watcher.new(updateFullScreenClocks):start()
  _fullScreenClockTimer        = hs.timer.new(hs.timer.seconds(15), updateFullScreenClocks):start()
  updateFullScreenClocks()
end
