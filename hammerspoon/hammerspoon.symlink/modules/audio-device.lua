-- Define audio device names for headphone/speaker switching
local headphoneDevice = "VIA Technologies" -- USB sound card
local speakerDevice = "AppleHDAEngineOutput" -- Built-in output

-- Toggle between speaker and headphone sound devices (useful if you have multiple USB soundcards that are always connected)
function toggleAudioOutput()
  local current = hs.audiodevice.defaultOutputDevice()
  local speakers = findOutputByPartialUID(speakerDevice)
  local headphones = findOutputByPartialUID(headphoneDevice)

  -- if not speakers or not headphones then
  --   hs.notify.new({title="Hammerspoon", informativeText="ERROR: Some audio devices missing", ""}):send()
  --   return
  -- end

  -- if current:name() == speakers:name() then
  --   headphones:setDefaultOutputDevice()
  -- else
  --   speakers:setDefaultOutputDevice()
  -- end

  hs.notify.new({
    title='Hammerspoon',
    informativeText='Default output device:' .. hs.audiodevice.defaultOutputDevice():name()
  }):send()
end

function findOutputByPartialUID(uid)
  for _, device in pairs(hs.audiodevice.allOutputDevices()) do
    if device:uid():match(uid) then
      return device
    end
  end
end
