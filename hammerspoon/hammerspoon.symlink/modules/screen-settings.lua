local thunderboltBrightness = 0.7

function handleLayoutChange()
  local thunderboltCount = 0
  local screenSet = hs.screen.allScreens()

  for _, screen in pairs(screenSet) do
    if screen:name():match("Thunderbolt Display") then
      thunderboltCount = thunderboltCount + 1
    end
  end

  if thunderboltCount >= 2 then
    for _, screen in pairs(screenSet) do
      screen:setBrightness(thunderboltBrightness)
    end
  end
end

hs.screen.watcher.new(handleLayoutChange):start()
handleLayoutChange()
