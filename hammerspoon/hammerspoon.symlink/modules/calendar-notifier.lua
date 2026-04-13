-- Calendar Meeting Notifier Module
-- Displays flashing menubar overlays with meeting names before meetings start.
-- Flashes at 60s before and again at start time, holds text until 5min after.
--
-- Requires a compiled Swift helper (bin/calendar-events) that queries EventKit
-- and writes JSON to cache/calendar-events.json via a LaunchAgent, since
-- Hammerspoon itself can't get calendar TCC permissions.
--
-- Setup:
--   cd ~/.dotfiles && ./hammerspoon/install.sh
--   ~/.hammerspoon/bin/calendar-events --request-access
--
-- Test:
--   testCalendarNotification("Meeting Name")
--   testTwoMeetings()
--   checkNow()

-- Configuration Variables
local filteredEventPatterns = {"Clockwise", "Focus Time", "Block"}
local notificationLeadTime = 60 -- seconds before meeting
local flashCount = 10 -- total number of flashes
local flashOnDuration = 0.25 -- seconds on
local displayDurationAfterStart = 300 -- seconds (5 minutes) to show after meeting starts

-- Flash colors (orange announcement style)
local flashOverlayColor = {red = 1.0, green = 0.584, blue = 0, alpha = 0.8}
local flashTextColor = {red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0}

-- Text colors for steady state (adaptive to OS appearance)
local textColorLightMode = hs.drawing.color.asRGB({ red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 })
local textColorDarkMode = hs.drawing.color.asRGB({ red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0 })
local isDarkMode = false

-- Path to the cached calendar data (written by LaunchAgent)
local cachePath = hs.configdir .. "/cache/calendar-events.json"
local cacheWarned = false -- throttle missing-cache warnings

-- State tracking
local activeOverlays = {} -- {groupId = {textOverlay, bgOverlay, removalTimer, eventIds}}
local notifiedEvents = {} -- Track events we've already notified about

-- Get dark mode setting from system
local function getDarkModeFromSystem()
  local _, darkmode = hs.osascript.applescript('tell application "System Events" to tell appearance preferences to return dark mode')
  return darkmode
end

-- Update dark mode when system changes
local function updateSystemDarkMode()
  isDarkMode = getDarkModeFromSystem()
  for _, overlayInfo in pairs(activeOverlays) do
    if overlayInfo.textOverlay and not overlayInfo.bgOverlay then
      local textColor = isDarkMode and textColorDarkMode or textColorLightMode
      for i = 1, overlayInfo.textOverlay:elementCount() do
        if overlayInfo.textOverlay[i].type == "text" then
          overlayInfo.textOverlay[i].textColor = textColor
        end
      end
    end
  end
end

-- Check if an event name should be filtered out
local function isEventFiltered(eventName)
  local lowerName = string.lower(eventName)
  for _, pattern in ipairs(filteredEventPatterns) do
    if string.find(lowerName, string.lower(pattern)) then
      return true
    end
  end
  return false
end

-- Read upcoming calendar events from cache file (written by LaunchAgent)
local function readUpcomingEvents()
  local attrs = hs.fs.attributes(cachePath)
  if not attrs then
    if not cacheWarned then
      print("Calendar notifier: cache file not found at " .. cachePath)
      print("  Run: cd ~/.dotfiles && ./hammerspoon/install.sh")
      cacheWarned = true
    end
    return {}
  end
  cacheWarned = false

  -- Skip if cache is stale (older than 2 minutes)
  local age = os.time() - attrs.modification
  if age > 120 then
    return {}
  end

  local file = io.open(cachePath, "r")
  if not file then return {} end
  local content = file:read("*a")
  file:close()

  local data = hs.json.decode(content)
  if not data or data.status ~= "ok" then
    if data and data.status == "permission_denied" then
      print("Calendar notifier: access denied. Run from terminal to grant permission:")
      print("  ~/.hammerspoon/bin/calendar-events --request-access")
    end
    return {}
  end

  return data.events or {}
end

-- Get menubar geometry
local function getMenubarGeometry()
  local mainScreen = hs.screen.mainScreen()
  local screeng = mainScreen:fullFrame()
  local menubarHeight = mainScreen:frame().y - screeng.y
  return screeng, menubarHeight
end

-- Create the text overlay (persistent, shown for the full duration)
local function createTextOverlay(meetingNames, textColor, font)
  if type(meetingNames) == "string" then
    meetingNames = {meetingNames}
  end

  local screeng, menubarHeight = getMenubarGeometry()
  local fontSize = 16
  local textWidth = 400
  local textY = (menubarHeight - fontSize - 4) / 2 -- vertically center with padding for descenders

  local overlay = hs.canvas.new{
    x = screeng.x, y = screeng.y,
    w = screeng.w, h = menubarHeight
  }

  local firstX = (screeng.w / 3) - (textWidth / 2)
  local secondX = (2 * screeng.w / 3) - (textWidth / 2)

  -- First position (1/3)
  overlay:appendElements({
    action = "fill", type = "text",
    text = meetingNames[1],
    textSize = fontSize, textColor = textColor,
    textAlignment = "center", textFont = font,
    frame = { x = firstX, y = textY, w = textWidth, h = menubarHeight - textY }
  })

  -- Second position (2/3) — second meeting name, or repeat the first
  overlay:appendElements({
    action = "fill", type = "text",
    text = meetingNames[2] or meetingNames[1],
    textSize = fontSize, textColor = textColor,
    textAlignment = "center", textFont = font,
    frame = { x = secondX, y = textY, w = textWidth, h = menubarHeight - textY }
  })

  overlay:level(hs.canvas.windowLevels.popUpMenu)
  overlay:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  return overlay
end

-- Create the background overlay (flashes independently)
local function createBgOverlay()
  local screeng, menubarHeight = getMenubarGeometry()

  local overlay = hs.canvas.new{
    x = screeng.x, y = screeng.y,
    w = screeng.w, h = menubarHeight
  }

  overlay:appendElements({
    action = "fill", type = "rectangle",
    fillColor = flashOverlayColor,
    frame = { x = 0, y = 0, w = screeng.w, h = menubarHeight }
  })

  -- Background sits below text
  overlay:level(hs.canvas.windowLevels.popUpMenu - 1)
  overlay:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  return overlay
end

-- Flash the background overlay, then remove it
local function flashBackground(bgOverlay, callback)
  local flashesRemaining = flashCount * 2
  local flashTimer

  local function doFlash()
    if flashesRemaining <= 0 then
      flashTimer:stop()
      bgOverlay:delete()
      if callback then callback() end
      return
    end

    if flashesRemaining % 2 == 1 then
      bgOverlay:show()
    else
      bgOverlay:hide()
    end

    flashesRemaining = flashesRemaining - 1
  end

  bgOverlay:show()
  flashTimer = hs.timer.doEvery(flashOnDuration, doFlash)
end

-- Transition text overlay from flash colors to steady-state colors
local function transitionTextToSteadyState(textOverlay)
  local textColor = isDarkMode and textColorDarkMode or textColorLightMode
  for i = 1, textOverlay:elementCount() do
    if textOverlay[i].type == "text" then
      textOverlay[i].textColor = textColor
      textOverlay[i].textFont = "Helvetica Neue"
    end
  end
end

-- Schedule overlay removal after meeting starts
local function scheduleOverlayRemoval(groupId, meetingStartTime)
  local now = os.time()
  local removalDelay = math.max(0, meetingStartTime - now + displayDurationAfterStart)

  return hs.timer.doAfter(removalDelay, function()
    if activeOverlays[groupId] then
      activeOverlays[groupId].textOverlay:delete()
      if activeOverlays[groupId].bgOverlay then
        activeOverlays[groupId].bgOverlay:delete()
      end
      activeOverlays[groupId] = nil
    end
  end)
end

-- Check for upcoming meetings
local function checkForUpcomingMeetings()
  local events = readUpcomingEvents()
  local now = os.time()
  local upcomingMeetings = {}

  for _, event in ipairs(events) do
    if event.title and not event.isAllDay and not isEventFiltered(event.title) then
      local eventId = event.id
      local timeUntilStart = event.startDate - now
      local phase = notifiedEvents[eventId] or "none"

      -- Flash at lead time (60s before) and again at start time (0s)
      local shouldNotify = false
      if timeUntilStart > 0 and timeUntilStart <= notificationLeadTime and phase == "none" then
        shouldNotify = true
        notifiedEvents[eventId] = "lead"
      elseif timeUntilStart <= 0 and timeUntilStart > -30 and phase == "lead" then
        shouldNotify = true
        notifiedEvents[eventId] = "start"
      end

      if shouldNotify then
        table.insert(upcomingMeetings, {
          eventId = eventId,
          title = event.title,
          startDate = event.startDate,
          timeUntilStart = timeUntilStart
        })
      end
    end
  end

  -- Group meetings by start time (within 5 minutes of each other)
  local groupedMeetings = {}
  for _, meeting in ipairs(upcomingMeetings) do
    local grouped = false
    for _, group in ipairs(groupedMeetings) do
      if math.abs(meeting.timeUntilStart - group[1].timeUntilStart) <= 300 then
        table.insert(group, meeting)
        grouped = true
        break
      end
    end
    if not grouped then
      table.insert(groupedMeetings, {meeting})
    end
  end

  -- Create notifications for each group
  for _, group in ipairs(groupedMeetings) do
    local meetingNames = {}
    local groupId = "group-" .. os.time() .. "-" .. math.random(1000)

    for i = 1, math.min(#group, 2) do
      table.insert(meetingNames, group[i].title)
    end

    if #meetingNames > 0 then
      -- Check if there's already an active overlay for these events
      local existingGroupId = nil
      for gid, info in pairs(activeOverlays) do
        if info.eventIds then
          for _, eid in ipairs(info.eventIds) do
            if eid == group[1].eventId then
              existingGroupId = gid
              break
            end
          end
        end
        if existingGroupId then break end
      end

      if existingGroupId then
        -- Re-flash the background on an existing text overlay
        local info = activeOverlays[existingGroupId]
        if info.removalTimer then info.removalTimer:stop() end

        -- Switch text back to flash style
        for i = 1, info.textOverlay:elementCount() do
          if info.textOverlay[i].type == "text" then
            info.textOverlay[i].textColor = flashTextColor
            info.textOverlay[i].textFont = "Helvetica Neue"
          end
        end

        local bgOverlay = createBgOverlay()
        info.bgOverlay = bgOverlay
        flashBackground(bgOverlay, function()
          if activeOverlays[existingGroupId] then
            activeOverlays[existingGroupId].bgOverlay = nil
            transitionTextToSteadyState(info.textOverlay)
            activeOverlays[existingGroupId].removalTimer = scheduleOverlayRemoval(existingGroupId, group[1].startDate)
          end
        end)
      else
        -- New notification
        local textOverlay = createTextOverlay(meetingNames, flashTextColor, "Helvetica Neue")
        local bgOverlay = createBgOverlay()

        activeOverlays[groupId] = {
          textOverlay = textOverlay,
          bgOverlay = bgOverlay,
          startTime = group[1].startDate,
          eventIds = {}
        }

        for _, meeting in ipairs(group) do
          table.insert(activeOverlays[groupId].eventIds, meeting.eventId)
        end

        textOverlay:show()
        flashBackground(bgOverlay, function()
          if activeOverlays[groupId] then
            activeOverlays[groupId].bgOverlay = nil
            transitionTextToSteadyState(textOverlay)
            activeOverlays[groupId].removalTimer = scheduleOverlayRemoval(groupId, group[1].startDate)
          end
        end)
      end
    end
  end

  -- Clean up old notified events that have no active overlay and are past start
  for eventId, phase in pairs(notifiedEvents) do
    if phase == "start" then
      local hasOverlay = false
      for _, info in pairs(activeOverlays) do
        if info.eventIds then
          for _, eid in ipairs(info.eventIds) do
            if eid == eventId then hasOverlay = true; break end
          end
        end
        if hasOverlay then break end
      end
      if not hasOverlay then
        notifiedEvents[eventId] = nil
      end
    end
  end
end

-- Test function for manual triggering (single flash, hold text for 60s)
function testCalendarNotification(meetingNames)
  meetingNames = meetingNames or "Test Meeting"

  local textOverlay = createTextOverlay(meetingNames, flashTextColor, "Helvetica Neue")
  local bgOverlay = createBgOverlay()
  local eventId = "test-" .. os.time()

  activeOverlays[eventId] = {
    textOverlay = textOverlay,
    bgOverlay = bgOverlay,
    startTime = os.time()
  }

  -- One round of flash animation, then hold text for 60s total
  textOverlay:show()
  flashBackground(bgOverlay, function()
    if activeOverlays[eventId] then
      activeOverlays[eventId].bgOverlay = nil
      transitionTextToSteadyState(textOverlay)
      activeOverlays[eventId].removalTimer = hs.timer.doAfter(60, function()
        if activeOverlays[eventId] then
          activeOverlays[eventId].textOverlay:delete()
          activeOverlays[eventId] = nil
        end
      end)
    end
  end)

  print("Test notification triggered for:", type(meetingNames) == "table" and table.concat(meetingNames, ", ") or meetingNames)
end

-- Test function for two meetings at once
function testTwoMeetings()
  testCalendarNotification({"Team Standup", "1:1 with Manager"})
end

-- Force an immediate calendar check
function checkNow()
  print("Forcing immediate calendar check...")
  checkForUpcomingMeetings()
end

-- Start watchers
_calendarCheckTimer = hs.timer.new(30, checkForUpcomingMeetings):start()
_systemDarkModeWatcher = hs.distributednotifications.new(updateSystemDarkMode, 'AppleInterfaceThemeChangedNotification'):start()

-- Initialize
updateSystemDarkMode()
checkForUpcomingMeetings()

print("Calendar notifier loaded - test with: testCalendarNotification('Meeting Name') or checkNow()")
