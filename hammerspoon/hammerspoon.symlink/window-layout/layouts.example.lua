-- Copy to ~/.config/window-layout/layouts.lua; the real file stays out of the
-- repo because it names each machine's apps and monitors.
--
-- The first profile whose `when` matches wins. Monitor numbers count external
-- displays only, left to right. Region names are in planner.lua; windows past
-- a split's `max` are left alone. A list for `at` places windows in opening
-- order, and every window past the end of the list shares its last region.

return {
  profiles = {
    { name = "home",   when = { minAspect = 2.1 } },
    { name = "desk",   when = { externals = 2 } },
    { name = "laptop", when = { externals = 0 } },
  },

  layouts = {
    laptop = {
      { apps = "System Settings.app", skip = true },
      { apps = "*", screen = "builtin", at = "full" },
    },

    desk = {
      { apps = "Messages.app", screen = 1, at = "left half" },
      { apps = "Safari.app",   screen = 1, at = "right half" },
      { apps = "Terminal.app", screen = 2, at = "full", split = "columns", max = 2 },
    },

    home = {
      { apps = "Messages.app", screen = 1, at = "first third" },
      { apps = "Safari.app",   screen = 1, at = "middle third" },
      { apps = "Terminal.app", screen = 1, at = "last third", split = "rows", max = 2 },
    },
  },
}
