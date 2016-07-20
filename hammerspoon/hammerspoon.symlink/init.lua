util = require('util')
util.autoimport("./modules")

-- Fancy auto-reload thing
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

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.notify.new({
  title="Hammerspoon",
  informativeText="Configuration Loaded",
  ""
}):send()
