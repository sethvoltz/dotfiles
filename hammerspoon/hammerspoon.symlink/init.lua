-- Tools by Topic
require "modules/monitor-monitor"
require "modules/caffeine"
require "modules/audio-device"
require "modules/screen-settings"

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
