util = require('util')

-- Fancy auto-reload thing. Started before any module loads, so a module that
-- fails to load cannot take reloading down with it.
function reloadConfig(files)
  doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end

_reloadPathWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

util.autoimport("./modules")

hs.notify.new({
  title="Hammerspoon",
  informativeText="Configuration Loaded",
  ""
}):send()
