local f20modal = hs.hotkey.modal.new('cmd', 'f20')

function f20modal:entered()
  hs.timer.doAfter(1, function() f20modal:exit() end)
--   hs.alert'Entered mode'
end

-- function f20modal:exited()
--   hs.alert'Exited mode'
-- end

-- iTunes

f20modal:bind('', 'f1', function() hs.itunes.previous(); f20modal:exit() end)
f20modal:bind('', 'f2', function() hs.itunes.next(); f20modal:exit() end)
f20modal:bind('', 'f3', function() hs.itunes.playpause(); f20modal:exit() end)
f20modal:bind('', 'f4', function() hs.itunes.volumeUp(); f20modal:exit() end)
f20modal:bind('', 'f5', function() hs.itunes.volumeDown(); f20modal:exit() end)
