local caffeine = hs.menubar.new()
local filePath = debug.getinfo(1, 'S').source:match("@(.*)/")

function setCaffeineDisplay(state)
  local result
  if state then
    result = caffeine:setIcon(filePath .. "/caffeine-on.pdf")
  else
    result = caffeine:setIcon(filePath .. "/caffeine-off.pdf")
  end
end

function caffeineClicked()
  setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
  caffeine:setClickCallback(caffeineClicked)
  setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end
