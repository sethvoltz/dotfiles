local lastScreenId = -1
local usePhysicalIndicator = true
local useVirtualIndicator = true

local currentIndicator = nil
local indicatorHeight = 3 -- 0..1 = percent of menubar, >1 = pixel height
local indicatorColor = hs.drawing.color.asRGB({
  red = 0,
  green = 1.0,
  blue = 0,
  alpha = 0.3
})

-- -------------------------------------------------------= Change Handlers =--=

function handleLayoutChange()
  local focusedWindow = hs.window.focusedWindow()
  if not focusedWindow then return end

  local screen = focusedWindow:screen()
  local screenId = screen:id()
  if screenId == lastScreenId then return end
  lastScreenId = screenId

  if usePhysicalIndicator then updatePhysicalScreenIndicator(screenId) end
  if useVirtualIndicator  then updateVirtualScreenIndicator(screen) end
  print('Display changed to ' .. screenId)
end


-- ----------------------------------------------------= Virtual Indicators =--=

-- Based heavily on https://git.io/v6kZN
function updateVirtualScreenIndicator(screen)
  clearIndicator()

  local screeng = screen:fullFrame()

  if indicatorHeight >= 0.0 and indicatorHeight <= 1.0 then
    height = indicatorHeight*(screen:frame().y - screeng.y)
  else
    height = indicatorHeight
  end

  indicator = hs.drawing.rectangle(hs.geometry.rect(
    screeng.x,
    screeng.y,
    screeng.w,
    height
  ))

  indicator:setFillColor(indicatorColor)
    :setFill(true)
    :setLevel(hs.drawing.windowLevels.overlay)
    :setStroke(false)
    :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :show()

  currentIndicator = indicator
end

function clearIndicator()
   if currentIndicator ~= nil then
      currentIndicator:delete()
      currentIndicator = nil
   end
end


-- ---------------------------------------------------= Physical Indicators =--=

function updatePhysicalScreenIndicator(screenId)
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


-- --------------------------------------------------------------= Watchers =--=

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
