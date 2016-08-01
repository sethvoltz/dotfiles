lastScreenId = -1

-- Detect layout change
function handleLayoutChange()
  -- Always send the screenId, even on real layout changes (could be add/remove display)
  local focusedWindow = hs.window.focusedWindow()
  if not focusedWindow then return end

  local screenId = focusedWindow:screen():id()
  if screenId == lastScreenId then return end

  lastScreenId = screenId
  setActiveScreen(screenId)
  print('current display ' .. screenId)
end

function setActiveScreen(screenId)
  local devicePath = getSerialOutputDevice()
  if devicePath == "" then return end

  local file = assert(io.open(devicePath, "w"))
  file:write("set " .. screenId .. "\n")
  file:flush()
  file:close()
end

function getSerialOutputDevice()
  local command = "ioreg -c IOSerialBSDClient -r -t " ..
    "| awk 'f;/Photon/{f=1};/IOCalloutDevice/{exit}' " ..
    "| sed -n 's/.*\"\\(\\/dev\\/.*\\)\".*/\\1/p'"
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()
  -- Strip whitespace - https://www.rosettacode.org/wiki/Strip_whitespace_from_a_string/Top_and_tail#Lua
  return result:match("^%s*(.-)%s*$")
end

-- Watchers
hs.screen.watcher.newWithActiveScreen(handleLayoutChange):start()
hs.spaces.watcher.new(handleLayoutChange):start()
handleLayoutChange(true) -- set the initial screen

-- Run this from the Hammerspoon console to get a listing of display IDs
function listAllScreens ()
  local primaryId = hs.screen.primaryScreen():id()
  for _, screen in pairs(hs.screen.allScreens()) do
    local screenId = screen:id()
    print(
      "id: " .. screenId ..
      " \"" .. screen:name() .. "\"" ..
      (screenId == primaryId and " (primary)" or "")
    )
  end
end
