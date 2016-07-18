-- Detect layout change
function handleLayoutChange(layout)
  if layout then
    local screenId = hs.window.focusedWindow():screen():id()
    print('current display ' .. screenId)
  end
end

hs.screen.watcher.newWithActiveScreen(handleLayoutChange):start()
print('Monitor-Monitor loaded')
