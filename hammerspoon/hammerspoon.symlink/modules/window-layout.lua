local planner = require("window-layout.planner")

-- Lives outside the repo: layouts name apps and monitor setups.
local CONFIG_DIR = os.getenv("HOME") .. "/.config/window-layout"
local CONFIG_FILE = CONFIG_DIR .. "/layouts.lua"

-- Used only while Rectangle has never saved a gap of its own.
local DEFAULT_GAP = 8

-- Docking emits several screen-change events as displays settle.
local SETTLE_SECONDS = 3
local BATCH_SECONDS = 0.05

-- Editors save in several writes; one reload per save.
local SAVE_SETTLE_SECONDS = 0.2

-- Some apps restore their own saved frame just after a window opens. Until this passes, a new
-- window that has moved is re-placed, not treated as moved by hand.
local RECHECK_SECONDS = 0.5

local HAND_MOVE_TOLERANCE = 4
local SETTINGS_KEY = "windowLayout.assigned"
local BOOT_KEY = "windowLayout.bootTime"
local BUILTIN_NAME_PATTERNS = { "Built%-in", "Color LCD", "Liquid Retina" }

local hyper = { "shift", "cmd", "alt", "ctrl" }

local config, profile, gap = nil, nil, DEFAULT_GAP

-- Where each window was left after this module last placed it, by window id. A window whose
-- frame no longer matches was moved by hand and is left alone until a forced layout.
local assigned = {}
local fresh = {}
local appWatchers = {}
local closeWatchers = {}
local batchTimer, settleTimer, saveTimer = nil, nil, nil

local function notify(text)
  print("window-layout: " .. text)
  hs.notify.new({ title = "window-layout", informativeText = text }):send()
end

local function readGap()
  local output, ok = hs.execute("/usr/bin/defaults export com.knollsoft.Rectangle -")
  local prefs = ok and hs.plist.readString(output) or nil
  return tonumber(prefs and prefs.gapSize) or DEFAULT_GAP
end

local function loadConfig()
  if not hs.fs.attributes(CONFIG_FILE) then return nil end

  local ok, raw = pcall(dofile, CONFIG_FILE)
  if not ok then
    notify(tostring(raw))
    return nil
  end
  if type(raw) ~= "table" then
    notify("layouts.lua must return a table")
    return nil
  end

  local compiled, errors = planner.compile(raw)
  if not compiled then
    notify(table.concat(errors, "\n"))
    return nil
  end
  return compiled
end

local function bootTime()
  return hs.execute("/usr/sbin/sysctl -n kern.boottime"):match("sec = (%d+)")
end

local function saveAssigned()
  local stored = {}
  for id, frame in pairs(assigned) do stored[tostring(id)] = frame end
  hs.settings.set(SETTINGS_KEY, stored)
end

-- Window ids are reused after a reboot, so a record from an earlier boot is dropped. Checked
-- against the boot time rather than live windows, which would query every app at load.
local function restoreAssigned()
  local boot = bootTime()
  if hs.settings.get(BOOT_KEY) ~= boot then
    hs.settings.set(BOOT_KEY, boot)
    hs.settings.set(SETTINGS_KEY, {})
    return
  end
  for key, frame in pairs(hs.settings.get(SETTINGS_KEY) or {}) do
    assigned[tonumber(key)] = frame
  end
end

local function isBuiltin(screen)
  local name = screen:name() or ""
  for _, pattern in ipairs(BUILTIN_NAME_PATTERNS) do
    if name:match(pattern) then return true end
  end
  return false
end

local function currentScreens()
  local screens = {}
  for _, screen in ipairs(hs.screen.allScreens()) do
    local frame = screen:frame()
    screens[#screens + 1] = {
      name = screen:name(),
      builtin = isBuiltin(screen),
      frame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h },
    }
  end
  return screens
end

local function toList(rect)
  return { rect.x, rect.y, rect.w, rect.h }
end

-- hs.application:path() raises, rather than returning nil, for some processes that have a bundle
-- id but no bundle URL.
local appFiles = {}
local function appFile(app)
  local pid = app:pid()
  if appFiles[pid] == nil then
    local ok, path = pcall(app.path, app)
    appFiles[pid] = ok and path and path:match("([^/]+%.app)$") or false
  end
  return appFiles[pid] or nil
end

local function isRuled(layout, app)
  local bundleID = app:bundleID()
  if not bundleID or app:kind() == -1 then return false end
  if layout.byApp[bundleID] or layout.byApp[appFile(app) or ""] then return true end
  return #layout.wildcard > 0 and app:kind() == 1
end

local function ruledApplications(layout)
  local apps = {}
  for _, app in ipairs(hs.application.runningApplications()) do
    if isRuled(layout, app) then apps[#apps + 1] = app end
  end
  return apps
end

-- Some apps present modal dialogs as standard windows. Sent to a slot, a window that cannot be
-- resized only moves, and lands in the slot's top-left corner at its own size. Cached per window,
-- except when the check fails, so a transient error does not exclude a real window for good.
local fitsSlot = {}
local function canFillSlot(window, id)
  if fitsSlot[id] == nil then
    local ax = hs.axuielement.windowElement(window)
    local resizable = ax and ax:isAttributeSettable("AXSize")
    if resizable == nil then return true end
    fitsSlot[id] = resizable and ax:attributeValue("AXModal") ~= true
  end
  return fitsSlot[id]
end

-- A hidden app's windows cannot be moved, so they wait for the app to be unhidden.
local function placeableWindows(apps)
  local windows = {}
  for _, app in ipairs(apps) do
    if not app:isHidden() then
      local bundleID, file = app:bundleID(), appFile(app)
      for _, window in ipairs(app:allWindows()) do
        local id = window:id()
        if id and window:isStandard() and not window:isMinimized() and not window:isFullScreen()
          and canFillSlot(window, id) then
          windows[#windows + 1] = {
            id = id,
            app = bundleID,
            appFile = file,
            title = config.needsTitles and window:title() or nil,
            frame = toList(window:frame()),
            window = window,
          }
        end
      end
    end
  end
  return windows
end

local function handMoved(windows)
  local pinned = {}
  for _, entry in ipairs(windows) do
    local last = assigned[entry.id]
    if last and not fresh[entry.id] and planner.movedByHand(last, entry.frame, HAND_MOVE_TOLERANCE) then
      pinned[entry.id] = true
    end
  end
  return pinned
end

-- A move across a screen edge can land short (see hs.window.setFrameCorrectness); retry settles it.
-- Returns where the window ended up, which is not the target for a window that refused the move.
local function place(window, target)
  local rect = hs.geometry.rect(target[1], target[2], target[3], target[4])
  window:setFrame(rect, 0)
  local landed = toList(window:frame())
  if planner.movedByHand(target, landed, 1) then
    window:setFrame(rect, 0)
    landed = toList(window:frame())
  end
  return landed
end

local relayout
local scheduleRelayout

local function watchClose(entry)
  if closeWatchers[entry.id] then return end
  local id = entry.id
  local watcher = entry.window:newWatcher(function(_, _, self)
    self:stop()
    closeWatchers[id] = nil
    assigned[id] = nil
    fitsSlot[id] = nil
    scheduleRelayout()
  end)
  if watcher then closeWatchers[id] = watcher:start({ hs.uielement.watcher.elementDestroyed }) end
end

local function recheck(ids)
  for _, id in ipairs(ids) do fresh[id] = true end
  hs.timer.doAfter(RECHECK_SECONDS, function()
    relayout(false)
    for _, id in ipairs(ids) do fresh[id] = nil end
  end)
end

local function windowCreated(element)
  local ok, id = pcall(function() return element:id() end)
  if ok and id then recheck({ id }) end
  scheduleRelayout()
end

local function watchApplication(app)
  local pid = app:pid()
  if appWatchers[pid] then return end
  local watcher = app:newWatcher(windowCreated)
  if watcher then appWatchers[pid] = watcher:start({ hs.uielement.watcher.windowCreated }) end
end

-- Registering a watcher messages the app, and an app slow to answer stalls it, so only apps that
-- joined or left the layout are touched.
local function syncApplicationWatchers()
  local wanted = {}
  if config and profile then
    for _, app in ipairs(ruledApplications(config.layouts[profile])) do
      wanted[app:pid()] = true
      watchApplication(app)
    end
  end
  for pid, watcher in pairs(appWatchers) do
    if not wanted[pid] then
      watcher:stop()
      appWatchers[pid] = nil
    end
  end
end

relayout = function(force)
  if not config then return end

  local screens = currentScreens()
  local detected = planner.detect(config, screens)
  local changed = detected ~= profile
  if changed and profile then force = true end
  profile = detected
  if changed and profile then hs.alert.show("Layout: " .. profile) end
  if changed then syncApplicationWatchers() end
  if not profile then return end

  -- Forgetting every record on a forced layout means a window skipped this pass, such as one
  -- that was hidden, is placed when it next appears rather than read as moved by hand.
  if force then assigned = {} end

  local windows = placeableWindows(ruledApplications(config.layouts[profile]))
  local pinned = force and {} or handMoved(windows)
  local plan = planner.plan(config, profile, screens, windows, pinned, gap)

  for _, entry in ipairs(windows) do
    local target = plan[entry.id]
    if target then
      local moved = planner.movedByHand(target, entry.frame, 1)
      assigned[entry.id] = moved and place(entry.window, target) or entry.frame
      watchClose(entry)
    end
  end
  saveAssigned()
end

scheduleRelayout = function()
  if batchTimer then batchTimer:stop() end
  batchTimer = hs.timer.doAfter(BATCH_SECONDS, function() relayout(false) end)
end

local function applicationEvent(_, event, app)
  if not (config and profile) then return end

  if event == hs.application.watcher.launched and isRuled(config.layouts[profile], app) then
    watchApplication(app)
    local ids = {}
    for _, window in ipairs(app:allWindows()) do
      local id = window:id()
      if id then ids[#ids + 1] = id end
    end
    recheck(ids)
    scheduleRelayout()
  elseif event == hs.application.watcher.unhidden and isRuled(config.layouts[profile], app) then
    scheduleRelayout()
  elseif event == hs.application.watcher.terminated then
    appFiles[app:pid()] = nil
    local watcher = appWatchers[app:pid()]
    if watcher then
      watcher:stop()
      appWatchers[app:pid()] = nil
      scheduleRelayout()
    end
  end
end

local function screensChanged()
  if settleTimer then settleTimer:stop() end
  settleTimer = hs.timer.doAfter(SETTLE_SECONDS, function() relayout(true) end)
end

-- An alert is drawn only once control returns to the run loop, so the layout waits a tick for it.
local function forceLayout()
  if profile then hs.alert.show("Layout: " .. profile) end
  hs.timer.doAfter(0, function()
    config = loadConfig()
    syncApplicationWatchers()
    relayout(true)
  end)
end

local function configSaved()
  if saveTimer then saveTimer:stop() end
  saveTimer = hs.timer.doAfter(SAVE_SETTLE_SECONDS, forceLayout)
end

hs.hotkey.bind(hyper, "p", function()
  gap = readGap()
  forceLayout()
end)

-- ---------------------------------------------------------------------------------= Watchers =--=

config = loadConfig()
gap = readGap()
restoreAssigned()
relayout(false)

_windowLayoutScreenWatcher = hs.screen.watcher.new(screensChanged):start()
_windowLayoutAppWatcher = hs.application.watcher.new(applicationEvent):start()
_windowLayoutConfigWatcher = hs.pathwatcher.new(CONFIG_DIR, configSaved):start()

-- Run this from the Hammerspoon console to see what the layout would do
function listWindowLayout()
  if not config then
    print("no config at " .. CONFIG_FILE)
    return
  end

  local screens = currentScreens()
  local detected = planner.detect(config, screens)
  print(string.format("profile: %s   gap: %d", tostring(detected), gap))
  if not detected then return end

  local windows = placeableWindows(ruledApplications(config.layouts[detected]))
  local pinned = handMoved(windows)
  local plan = planner.plan(config, detected, screens, windows, pinned, gap)
  for _, entry in ipairs(windows) do
    local target = plan[entry.id]
    local status = pinned[entry.id] and "moved by hand"
      or not target and "no slot"
      or planner.movedByHand(target, entry.frame, 1) and string.format("-> %d,%d %dx%d", table.unpack(target))
      or "in place"
    print(string.format("  %-28s %-24s %s", entry.app, (entry.window:title() or ""):sub(1, 24), status))
  end
end
