-- Pure placement logic: no hs.* calls, so it runs under plain Lua for tests.
local M = {}

M.REGIONS = {
  ["full"]             = { 0,   0,   1,   1 },
  ["left half"]        = { 0,   0,   0.5, 1 },
  ["right half"]       = { 0.5, 0,   0.5, 1 },
  ["top half"]         = { 0,   0,   1,   0.5 },
  ["bottom half"]      = { 0,   0.5, 1,   0.5 },
  ["first third"]      = { 0,   0,   1/3, 1 },
  ["middle third"]     = { 1/3, 0,   1/3, 1 },
  ["last third"]       = { 2/3, 0,   1/3, 1 },
  ["first two thirds"] = { 0,   0,   2/3, 1 },
  ["last two thirds"]  = { 1/3, 0,   2/3, 1 },
}

local RULE_KEYS = { apps = true, title = true, screen = true, at = true, split = true, max = true, skip = true }
local WHEN_KEYS = { externals = true, minAspect = true, name = true }

local function asList(value)
  if type(value) == "table" then return value end
  return { value }
end

-- Returns a compiled config, or nil plus every problem found, so one save
-- surfaces all typos rather than the first.
function M.compile(raw)
  local errors = {}
  local function fail(fmt, ...) errors[#errors + 1] = string.format(fmt, ...) end

  local regions = {}
  for name, rect in pairs(M.REGIONS) do regions[name] = rect end
  for name, rect in pairs(raw.regions or {}) do regions[name] = rect end

  local profiles = {}
  for i, profile in ipairs(raw.profiles or {}) do
    if type(profile.name) ~= "string" then fail("profiles[%d]: missing name", i) end
    for key in pairs(profile.when or {}) do
      if not WHEN_KEYS[key] then fail("profiles[%d].when: unknown key '%s'", i, key) end
    end
    if not (raw.layouts or {})[profile.name] then fail("profiles[%d]: no layout named '%s'", i, tostring(profile.name)) end
    profiles[#profiles + 1] = profile
  end

  local layouts, needsTitles = {}, false
  for name, rules in pairs(raw.layouts or {}) do
    local byApp, wildcard = {}, {}
    for i, rule in ipairs(rules) do
      local where = string.format("layouts.%s[%d]", name, i)
      for key in pairs(rule) do
        if not RULE_KEYS[key] then fail("%s: unknown key '%s'", where, key) end
      end
      -- `at` is one region, or a list taken in opening order with the last shared by the rest.
      -- An inline rect is itself a list of numbers, so a list is told apart by its first item.
      local slots = {}
      local list = type(rule.at) == "table" and type(rule.at[1]) ~= "number" and rule.at or { rule.at }
      for n, value in ipairs(list) do
        slots[n] = type(value) == "table" and value or regions[value]
        if not slots[n] and not rule.skip then fail("%s: unknown region '%s'", where, tostring(value)) end
      end
      if rule.skip then
        if rule.at or rule.screen or rule.split then fail("%s: a skip rule takes only apps and title", where) end
      elseif #list == 0 then
        fail("%s: unknown region '%s'", where, tostring(rule.at))
      elseif #list > 1 and rule.split then
        fail("%s: split takes a single region", where)
      end
      if rule.split and rule.split ~= "columns" and rule.split ~= "rows" then
        fail("%s: split must be 'columns' or 'rows'", where)
      end
      local screen = rule.screen == "builtin" and "builtin"
        or math.type(rule.screen) == "integer" and rule.screen >= 1 and ("external" .. rule.screen)
      if not screen and not rule.skip then fail("%s: screen must be \"builtin\" or a monitor number", where) end
      if rule.title then needsTitles = true end
      local apps = asList(rule.apps)
      local compiled = {
        index = i, title = rule.title, screen = screen, slots = slots,
        split = rule.split, max = rule.max, skip = rule.skip, order = {},
      }
      for position, app in ipairs(apps) do
        compiled.order[app] = position
        if app == "*" then
          wildcard[#wildcard + 1] = compiled
        else
          byApp[app] = byApp[app] or {}
          table.insert(byApp[app], compiled)
        end
      end
    end
    layouts[name] = { byApp = byApp, wildcard = wildcard }
  end

  if #errors > 0 then return nil, errors end
  return { profiles = profiles, layouts = layouts, needsTitles = needsTitles }
end

-- screens: { name, frame = {x,y,w,h}, builtin }  in any order. Monitor N in a
-- rule is externalN here: external displays numbered left to right.
function M.roles(screens)
  local sorted = {}
  for _, s in ipairs(screens) do sorted[#sorted + 1] = s end
  table.sort(sorted, function(a, b) return a.frame.x < b.frame.x end)

  local roles, externals = {}, 0
  for _, s in ipairs(sorted) do
    if s.builtin then
      roles.builtin = s
    else
      externals = externals + 1
      roles["external" .. externals] = s
    end
  end
  roles.external1 = roles.external1 or roles.builtin
  return roles
end

function M.detect(config, screens)
  for _, profile in ipairs(config.profiles) do
    local when, ok = profile.when or {}, true
    if when.externals then
      local externals = 0
      for _, s in ipairs(screens) do
        if not s.builtin then externals = externals + 1 end
      end
      ok = externals == when.externals
    end
    if ok and when.minAspect then
      local found = false
      for _, s in ipairs(screens) do
        if s.frame.w / s.frame.h >= when.minAspect then found = true end
      end
      ok = found
    end
    if ok and when.name then
      local found = false
      for _, s in ipairs(screens) do
        if (s.name or ""):match(when.name) then found = true end
      end
      ok = found
    end
    if ok then return profile.name end
  end
  return nil
end

-- An app is named by its bundle id or its .app file name; a window carries both.
local function appKey(table, window)
  return table[window.app] or (window.appFile and table[window.appFile])
end

function M.ruleFor(layout, window)
  if not window.app then return nil end
  local candidates = appKey(layout.byApp, window) or layout.wildcard
  for _, rule in ipairs(candidates) do
    if not rule.title or (window.title or ""):match(rule.title) then return rule end
  end
  if candidates ~= layout.wildcard then
    for _, rule in ipairs(layout.wildcard) do
      if not rule.title or (window.title or ""):match(rule.title) then return rule end
    end
  end
  return nil
end

local function slot(rect, split, index, count)
  local x, y, w, h = rect[1], rect[2], rect[3], rect[4]
  if split == "columns" then return { x + w * (index - 1) / count, y, w / count, h } end
  if split == "rows" then return { x, y + h * (index - 1) / count, w, h / count } end
  return rect
end

local EPSILON = 1e-6

-- Matches Rectangle: a full gap against the screen edge, half a gap on each
-- side of an edge shared with a neighbour, so neighbours sit one gap apart.
local function inset(unitEdge, gap)
  if unitEdge < EPSILON or unitEdge > 1 - EPSILON then return gap end
  return gap / 2
end

local function absolute(unit, screen, gap)
  local left   = screen.x + unit[1] * screen.w + inset(unit[1], gap)
  local top    = screen.y + unit[2] * screen.h + inset(unit[2], gap)
  local right  = screen.x + (unit[1] + unit[3]) * screen.w - inset(unit[1] + unit[3], gap)
  local bottom = screen.y + (unit[2] + unit[4]) * screen.h - inset(unit[2] + unit[4], gap)
  local x, y = math.floor(left + 0.5), math.floor(top + 0.5)
  return { x, y, math.floor(right + 0.5) - x, math.floor(bottom + 0.5) - y }
end

-- Windows absent from the result are left where they are.
function M.plan(config, profileName, screens, windows, pinned, gap)
  local layout = config.layouts[profileName]
  if not layout then return {} end
  local roles = M.roles(screens)
  pinned = pinned or {}
  gap = gap or 0

  local groups, groupOrder = {}, {}
  for _, window in ipairs(windows) do
    local rule = not pinned[window.id] and M.ruleFor(layout, window)
    if rule and not rule.skip and roles[rule.screen] then
      if not groups[rule] then
        groups[rule] = {}
        groupOrder[#groupOrder + 1] = rule
      end
      table.insert(groups[rule], window)
    end
  end

  local frames = {}
  for _, rule in ipairs(groupOrder) do
    local members = groups[rule]
    table.sort(members, function(a, b)
      local pa = appKey(rule.order, a) or rule.order["*"]
      local pb = appKey(rule.order, b) or rule.order["*"]
      if pa ~= pb then return pa < pb end
      return a.id < b.id
    end)

    local count = rule.split and math.min(#members, rule.max or #members) or 1
    local screen = roles[rule.screen].frame
    for i, window in ipairs(members) do
      if rule.split and i > count then break end
      local unit = rule.split and slot(rule.slots[1], rule.split, i, count)
        or rule.slots[math.min(i, #rule.slots)]
      frames[window.id] = absolute(unit, screen, gap)
    end
  end
  return frames
end

-- A window whose frame no longer matches what we last set was moved by hand.
function M.movedByHand(assigned, current, tolerance)
  tolerance = tolerance or 4
  for i = 1, 4 do
    if math.abs(assigned[i] - current[i]) > tolerance then return true end
  end
  return false
end

return M
