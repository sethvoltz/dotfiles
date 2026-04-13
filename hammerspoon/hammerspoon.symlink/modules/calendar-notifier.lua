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

local filteredEventPatterns = {"Clockwise", "Focus Time", "Block"}
local notificationLeadTime = 60
local flashCount = 10
local flashOnDuration = 0.25
local displayDurationAfterStart = 300

local filteredPatternsLower = {}
for _, p in ipairs(filteredEventPatterns) do
  table.insert(filteredPatternsLower, string.lower(p))
end

local flashOverlayColor = {red = 1.0, green = 0.584, blue = 0, alpha = 0.8}
local ambientOverlayColor = {red = 1.0, green = 0.584, blue = 0, alpha = 0.1}
local flashTextColor = {red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0}

local textColorLightMode = hs.drawing.color.asRGB({ red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 })
local textColorDarkMode = hs.drawing.color.asRGB({ red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0 })
local isDarkMode = false

local cachePath = hs.configdir .. "/cache/calendar-events.json"
local cacheWarned = false
local lastCacheMtime = nil
local lastCacheEvents = {}

local activeOverlays = {}
local notifiedEvents = {}

-- Stop previous instances on config reload
if _calendarCheckTimer then _calendarCheckTimer:stop() end
if _systemDarkModeWatcher then _systemDarkModeWatcher:stop() end
if _screenWatcher then _screenWatcher:stop() end

local function getDarkModeFromSystem()
  local _, darkmode = hs.osascript.applescript('tell application "System Events" to tell appearance preferences to return dark mode')
  return darkmode
end

local function setTextStyle(textOverlay, flash)
  local color = flash and flashTextColor or (isDarkMode and textColorDarkMode or textColorLightMode)
  for i = 1, textOverlay:elementCount() do
    if textOverlay[i].type == "text" then
      textOverlay[i].textColor = color
      textOverlay[i].textFont = "Helvetica Neue"
    end
  end
end

local function updateSystemDarkMode()
  isDarkMode = getDarkModeFromSystem()
  for _, info in pairs(activeOverlays) do
    if info.textOverlay and not info.flashing then
      setTextStyle(info.textOverlay, false)
    end
  end
end

local function isEventFiltered(eventName)
  local lowerName = string.lower(eventName)
  for _, pattern in ipairs(filteredPatternsLower) do
    if string.find(lowerName, pattern) then
      return true
    end
  end
  return false
end

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

  local age = os.time() - attrs.modification
  if age > 120 then return {} end

  if lastCacheMtime and attrs.modification == lastCacheMtime then
    return lastCacheEvents
  end

  local file = io.open(cachePath, "r")
  if not file then return {} end
  local content = file:read("*a")
  file:close()

  -- pcall guards against partially-written JSON from concurrent LaunchAgent writes
  local ok, data = pcall(hs.json.decode, content)
  if not ok or type(data) ~= "table" then return {} end
  if data.status ~= "ok" then
    if data.status == "permission_denied" then
      print("Calendar notifier: access denied. Run from terminal to grant permission:")
      print("  ~/.hammerspoon/bin/calendar-events --request-access")
    end
    return {}
  end

  lastCacheMtime = attrs.modification
  lastCacheEvents = data.events or {}
  return lastCacheEvents
end

local function getMenubarGeometry()
  local mainScreen = hs.screen.mainScreen()
  local screeng = mainScreen:fullFrame()
  local menubarHeight = mainScreen:frame().y - screeng.y
  return screeng, menubarHeight
end

local function createTextOverlay(meetingNames, textColor, font)
  if type(meetingNames) == "string" then meetingNames = {meetingNames} end

  local screeng, menubarHeight = getMenubarGeometry()
  local fontSize = 16
  local textWidth = 400
  local textY = (menubarHeight - fontSize - 4) / 2

  local overlay = hs.canvas.new{
    x = screeng.x, y = screeng.y,
    w = screeng.w, h = menubarHeight
  }

  local positions = {
    {x = (screeng.w / 3) - (textWidth / 2), text = meetingNames[1]},
    {x = (2 * screeng.w / 3) - (textWidth / 2), text = meetingNames[2] or meetingNames[1]}
  }
  for _, pos in ipairs(positions) do
    overlay:appendElements({
      action = "fill", type = "text",
      text = pos.text,
      textSize = fontSize, textColor = textColor,
      textAlignment = "center", textFont = font,
      frame = { x = pos.x, y = textY, w = textWidth, h = menubarHeight - textY }
    })
  end

  overlay:level(hs.canvas.windowLevels.popUpMenu)
  overlay:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  return overlay
end

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

  -- Below text so text remains readable during flash
  overlay:level(hs.canvas.windowLevels.popUpMenu - 1)
  overlay:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  return overlay
end

-- Returns the flash timer so callers can cancel mid-animation.
-- Hides (not deletes) bgOverlay when done — callers own the lifecycle.
local function flashBackground(bgOverlay, callback)
  local flashesRemaining = flashCount * 2
  local flashTimer

  local function doFlash()
    if flashesRemaining <= 0 then
      flashTimer:stop()
      bgOverlay:hide()
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
  return flashTimer
end

local function cleanupOverlayGroup(groupId)
  local info = activeOverlays[groupId]
  if not info then return end
  if info.flashTimer then info.flashTimer:stop() end
  if info.startFlashTimer then info.startFlashTimer:stop() end
  if info.removalTimer then info.removalTimer:stop() end
  if info.textOverlay then info.textOverlay:delete() end
  if info.bgOverlay then info.bgOverlay:delete() end
  activeOverlays[groupId] = nil
end

local function scheduleOverlayRemoval(groupId, meetingStartTime)
  local removalDelay = math.max(0, meetingStartTime - os.time() + displayDurationAfterStart)
  return hs.timer.doAfter(removalDelay, function()
    cleanupOverlayGroup(groupId)
  end)
end

-- Callers must stop removalTimer/startFlashTimer before calling.
local function beginFlash(groupId, onComplete)
  local info = activeOverlays[groupId]
  if not info then return end
  if info.flashTimer then info.flashTimer:stop(); info.flashTimer = nil end
  if info.bgOverlay then info.bgOverlay:delete(); info.bgOverlay = nil end
  info.flashing = true
  setTextStyle(info.textOverlay, true)
  local bg = createBgOverlay()
  info.bgOverlay = bg
  info.flashTimer = flashBackground(bg, function()
    if not activeOverlays[groupId] then return end
    info.flashing = false
    info.flashTimer = nil
    if onComplete then onComplete(info, bg) end
  end)
end

local function repositionOverlays()
  for _, info in pairs(activeOverlays) do
    if info.meetingNames and not info.flashing then
      local oldText = info.textOverlay
      info.textOverlay = createTextOverlay(info.meetingNames, flashTextColor, "Helvetica Neue")
      setTextStyle(info.textOverlay, false)
      info.textOverlay:show()
      if oldText then oldText:delete() end

      if info.bgOverlay then
        local oldBg = info.bgOverlay
        info.bgOverlay = createBgOverlay()
        info.bgOverlay[1].fillColor = ambientOverlayColor
        info.bgOverlay:show()
        oldBg:delete()
      end
    end
  end
end

local function checkForUpcomingMeetings()
  local events = readUpcomingEvents()
  local now = os.time()
  local upcomingMeetings = {}

  -- Build set of current event IDs for stale entry cleanup
  local currentEventIds = {}
  for _, event in ipairs(events) do
    if event.id then currentEventIds[event.id] = true end
  end

  for _, event in ipairs(events) do
    if event.title and not event.isAllDay and not isEventFiltered(event.title) then
      local eventId = event.id
      local timeUntilStart = event.startDate - now
      local phase = notifiedEvents[eventId] or "none"

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

  -- Group meetings starting within 5 minutes of each other
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

  for _, group in ipairs(groupedMeetings) do
    local meetingNames = {}
    local groupId = "group-" .. os.time() .. "-" .. math.random(1000)

    for i = 1, math.min(#group, 2) do
      table.insert(meetingNames, group[i].title)
    end

    if #meetingNames > 0 then
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

      -- Clean up unrelated overlays to prevent visual overlap
      if not existingGroupId then
        for gid, _ in pairs(activeOverlays) do
          if not gid:match("^test%-") then cleanupOverlayGroup(gid) end
        end
      end

      if existingGroupId then
        local info = activeOverlays[existingGroupId]
        if info.removalTimer then info.removalTimer:stop(); info.removalTimer = nil end
        if info.startFlashTimer then info.startFlashTimer:stop(); info.startFlashTimer = nil end
        beginFlash(existingGroupId, function(info, bg)
          bg:delete(); info.bgOverlay = nil
          setTextStyle(info.textOverlay, false)
          info.removalTimer = scheduleOverlayRemoval(existingGroupId, group[1].startDate)
        end)
      else
        local textOverlay = createTextOverlay(meetingNames, flashTextColor, "Helvetica Neue")
        local bgOverlay = createBgOverlay()
        local meetingStartTime = group[1].startDate

        activeOverlays[groupId] = {
          textOverlay = textOverlay,
          bgOverlay = bgOverlay,
          flashing = true,
          meetingNames = meetingNames,
          startTime = meetingStartTime,
          eventIds = {}
        }

        for _, meeting in ipairs(group) do
          table.insert(activeOverlays[groupId].eventIds, meeting.eventId)
        end

        textOverlay:show()

        if group[1].timeUntilStart > 0 then
          -- Lead notification: flash → ambient bg → precise start-time flash
          beginFlash(groupId, function(info, bg)
            bg[1].fillColor = ambientOverlayColor
            bg:show()
            setTextStyle(info.textOverlay, false)

            local delay = math.max(0, meetingStartTime - os.time())
            info.startFlashTimer = hs.timer.doAfter(delay, function()
              if not activeOverlays[groupId] then return end
              activeOverlays[groupId].startFlashTimer = nil
              beginFlash(groupId, function(info2, bg2)
                bg2:delete(); info2.bgOverlay = nil
                setTextStyle(info2.textOverlay, false)
                info2.removalTimer = scheduleOverlayRemoval(groupId, meetingStartTime)
              end)
            end)

            for _, meeting in ipairs(group) do
              notifiedEvents[meeting.eventId] = "start"
            end
          end)
        else
          -- Start-time notification: flash → steady state
          beginFlash(groupId, function(info, bg)
            bg:delete(); info.bgOverlay = nil
            setTextStyle(info.textOverlay, false)
            info.removalTimer = scheduleOverlayRemoval(groupId, meetingStartTime)
          end)
        end
      end
    end
  end

  -- Clean up stale notified events
  for eventId, phase in pairs(notifiedEvents) do
    if not currentEventIds[eventId] then
      notifiedEvents[eventId] = nil
    elseif phase == "start" then
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

function testCalendarNotification(meetingNames)
  meetingNames = meetingNames or "Test Meeting"
  local names = type(meetingNames) == "string" and {meetingNames} or meetingNames

  -- Clean up any previous test overlay
  for gid, _ in pairs(activeOverlays) do
    if gid:match("^test%-") then cleanupOverlayGroup(gid) end
  end

  local eventId = "test-" .. os.time()

  activeOverlays[eventId] = {
    textOverlay = createTextOverlay(names, flashTextColor, "Helvetica Neue"),
    bgOverlay = createBgOverlay(),
    flashing = true,
    meetingNames = names,
    startTime = os.time()
  }

  activeOverlays[eventId].textOverlay:show()
  beginFlash(eventId, function(info, bg)
    bg:delete(); info.bgOverlay = nil
    setTextStyle(info.textOverlay, false)
    info.removalTimer = hs.timer.doAfter(60, function()
      cleanupOverlayGroup(eventId)
    end)
  end)

  print("Test notification triggered for:", type(meetingNames) == "table" and table.concat(meetingNames, ", ") or meetingNames)
end

function testTwoMeetings()
  testCalendarNotification({"Team Standup", "1:1 with Manager"})
end

function checkNow()
  print("Forcing immediate calendar check...")
  checkForUpcomingMeetings()
end

_calendarCheckTimer = hs.timer.new(30, checkForUpcomingMeetings):start()
_systemDarkModeWatcher = hs.distributednotifications.new(updateSystemDarkMode, 'AppleInterfaceThemeChangedNotification'):start()
_screenWatcher = hs.screen.watcher.new(repositionOverlays):start()

updateSystemDarkMode()
checkForUpcomingMeetings()

print("Calendar notifier loaded - test with: testCalendarNotification('Meeting Name') or checkNow()")
