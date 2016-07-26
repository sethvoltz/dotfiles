local hyper = {"shift", "cmd", "alt", "ctrl"}
local mash = {"ctrl", "alt", "cmd"}

-- Global shortcut to reload Hammerspoon
hs.hotkey.bind(hyper, "r", hs.reload)

-- Move windows around current screen
hs.hotkey.bind(mash, "left",   function() window:leftHalf()   end);
hs.hotkey.bind(mash, "right",  function() window:rightHalf()  end);
hs.hotkey.bind(mash, "up",     function() window:topHalf()    end);
hs.hotkey.bind(mash, "down",   function() window:bottomHalf() end);
hs.hotkey.bind(hyper, "f",     function() window:maximize()   end)

-- Move between screens
hs.hotkey.bind(hyper, "left",  function() hs.window.focusedWindow():moveOneScreenWest() end)
hs.hotkey.bind(hyper, "right", function() hs.window.focusedWindow():moveOneScreenEast() end)

window = {}

local function currentFrame()
  return hs.window.focusedWindow():frame()
end

local function currentScreenFrame()
  return hs.window.focusedWindow():screen():frame()
end

function window:maximize ()
  hs.window.focusedWindow():maximize()
end

function window:move (f, window)
  if window == nil then
    window = hs.window.focusedWindow()
  end
  local oldFrame = window:frame()
  if oldFrame ~= f then
    window:move(hs.geometry(f.x, f.y, f.w, f.h))
  end
end

function window:leftHalf ()
  local s = currentScreenFrame()
  self:move({ x = 0, y = 0, w = (s.w / 2), h = s.h })
end

function window:rightHalf ()
  local s = currentScreenFrame()
  self:move({ x = (s.w / 2), y = 0, w = (s.w / 2), h = s.h })
end

function window:topHalf ()
  local s = currentScreenFrame()
  self:move({ x = 0, y = 0, w = s.w, h = (s.h / 2) })
end

function window:bottomHalf ()
  local s = currentScreenFrame()
  self:move({ x = 0, y = (s.h / 2), w = s.w, h = (s.h / 2) })
end
