package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local P = require("planner")
local failures = 0
local function eq(label, got, want)
  local g = table.concat(got or {"nil"}, ","); local w = table.concat(want, ",")
  if g ~= w then failures = failures + 1; print("FAIL " .. label .. ": got " .. g .. " want " .. w) else print("ok   " .. label) end
end
local function untouched(frame) return { frame and "moved" or "untouched" } end

local MAIL, NOTES, SAFARI, TERM = "com.apple.mail", "com.apple.Notes", "com.apple.Safari", "com.apple.Terminal"
local config = assert(P.compile({
  profiles = {
    { name = "home",   when = { minAspect = 2.1 } },
    { name = "office", when = { externals = 2 } },
    { name = "laptop", when = { externals = 0 } },
  },
  layouts = {
    laptop = { { apps = "*", screen = "builtin", at = "full" } },
    office = {
      { apps = { MAIL, NOTES }, screen = 1, at = "left half" },
      { apps = SAFARI, screen = 1, at = "right half" },
      { apps = TERM, screen = 2, at = "full", split = "columns", max = 2 },
    },
    home = {
      { apps = { MAIL, NOTES }, screen = 1, at = "first third", split = "rows" },
      { apps = SAFARI, screen = 1, at = "middle third" },
      { apps = TERM, screen = 1, at = "last third", split = "rows", max = 2 },
    },
  },
}))

local office = {
  { name = "Right", frame = { x = 2560, y = 0, w = 2560, h = 1415 } },
  { name = "Left",  frame = { x = 0,    y = 0, w = 2560, h = 1415 } },
}
local ultrawide = { { name = "Wide", frame = { x = 0, y = 0, w = 3440, h = 1415 } } }
local laptop = { { name = "Built-in Retina Display", builtin = true, frame = { x = 0, y = 25, w = 1512, h = 957 } } }

eq("detect office", { P.detect(config, office) }, { "office" })
eq("detect laptop", { P.detect(config, laptop) }, { "laptop" })
eq("ultrawide alone is home, not laptop", { P.detect(config, ultrawide) }, { "home" })
eq("lid open at the office is still office", { P.detect(config, { office[1], office[2], laptop[1] }) }, { "office" })

local wins = {
  { id = 10, app = MAIL }, { id = 11, app = NOTES }, { id = 12, app = SAFARI },
  { id = 20, app = TERM }, { id = 7, app = "com.apple.finder" },
}
local f = P.plan(config, "office", office, wins)
eq("office mail left half of left monitor", f[10], { 0, 0, 1280, 1415 })
eq("office notes stacks with mail",         f[11], { 0, 0, 1280, 1415 })
eq("office safari right half left monitor", f[12], { 1280, 0, 1280, 1415 })
eq("office one terminal fills right monitor", f[20], { 2560, 0, 2560, 1415 })
eq("office unruled app untouched", untouched(f[7]), { "untouched" })

table.insert(wins, { id = 21, app = TERM })
f = P.plan(config, "office", office, wins)
eq("office terminal A left half",  f[20], { 2560, 0, 1280, 1415 })
eq("office terminal B right half", f[21], { 3840, 0, 1280, 1415 })

table.insert(wins, { id = 22, app = TERM })
f = P.plan(config, "office", office, wins)
eq("office 3rd terminal beyond max untouched", untouched(f[22]), { "untouched" })
eq("office first two keep halves", f[21], { 3840, 0, 1280, 1415 })

f = P.plan(config, "office", office, wins, { [20] = true })
eq("pinned terminal excluded, next one takes left half", f[21], { 2560, 0, 1280, 1415 })

f = P.plan(config, "home", ultrawide, wins)
eq("home mail top of first third",      f[10], { 0, 0, 1147, 708 })
eq("home notes bottom of first third",  f[11], { 0, 708, 1147, 707 })
eq("home safari middle third",          f[12], { 1147, 0, 1146, 1415 })

f = P.plan(config, "laptop", laptop, { { id = 7, app = "com.apple.finder" }, { id = 8, app = nil } })
eq("laptop wildcard maximizes finder", f[7], { 0, 25, 1512, 957 })
eq("wildcard skips windows with no bundle id", untouched(f[8]), { "untouched" })

local named = assert(P.compile({ profiles = {}, layouts = { office = {
  { apps = { "Mail.app", "Notes.app" }, screen = 1, at = "left half", split = "rows" } } } }))
f = P.plan(named, "office", { { name = "L", frame = { x = 0, y = 0, w = 2000, h = 1000 } } },
  { { id = 2, app = NOTES, appFile = "Notes.app" }, { id = 1, app = MAIL, appFile = "Mail.app" } })
eq("apps matched by .app name, ordered as listed", { f[1][2], f[2][2] }, { 0, 500 })

local withSkip = assert(P.compile({ profiles = {}, layouts = { laptop = {
  { apps = { "Calculator.app", "System Settings.app" }, skip = true },
  { apps = "*", screen = "builtin", at = "full" } } } }))
f = P.plan(withSkip, "laptop", laptop, {
  { id = 1, app = "com.apple.calculator", appFile = "Calculator.app" },
  { id = 2, app = "com.apple.finder", appFile = "Finder.app" } })
eq("skip rule beats the wildcard", untouched(f[1]), { "untouched" })
eq("wildcard still maximizes the rest", f[2], { 0, 25, 1512, 957 })
local _, badSkip = P.compile({ profiles = {}, layouts = { laptop = { { apps = "Finder.app", skip = true, at = "full" } } } })
eq("skip rule rejects placement keys", { #badSkip }, { 1 })

eq("hand-move detected",  { tostring(P.movedByHand({0,0,1280,1415}, {0,0,1000,1415})) }, { "true" })
eq("rounding not a move", { tostring(P.movedByHand({0,0,1280,1415}, {0,0,1282,1415})) }, { "false" })

local _, bad = P.compile({ profiles = { { name = "office" } }, layouts = { office = {
  { apps = SAFARI, screen = "1", at = "left hlaf", spilt = "rows" } } } })
eq("validation reports every typo at once", { #bad }, { 3 })
for _, e in ipairs(bad) do print("       " .. e) end

-- Rectangle's gap rule: a full gap at a screen edge, half a gap either side of
-- a shared edge. Menu bar offsets the usable area on both screens.
local menubar = {
  { name = "Left",  frame = { x = -2560, y = 25, w = 2560, h = 1415 } },
  { name = "Right", frame = { x = 0,     y = 25, w = 2560, h = 1415 } },
}
f = P.plan(config, "office", menubar, { { id = 1, app = MAIL }, { id = 2, app = SAFARI } }, nil, 4)
eq("gap: left half inset 4 at screen edge, 2 at centre", f[1], { -2556, 29, 1274, 1407 })
eq("gap: right half inset 2 at centre, 4 at screen edge", f[2], { -1278, 29, 1274, 1407 })
f = P.plan(config, "office", menubar, { { id = 3, app = TERM } }, nil, 4)
eq("gap: full screen inset 4 on every side", f[3], { 4, 29, 2552, 1407 })

print(failures == 0 and "ALL PASS" or (failures .. " FAILED"))
os.exit(failures == 0 and 0 or 1)
