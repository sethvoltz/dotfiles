-- WIP: Do not require from init yet!

-- Define audio device names for headphone/speaker switching
local headphoneDevice = "Turtle Beach USB Audio"
local speakerDevice = "Audioengine 2_  "

-- Toggle between speaker and headphone sound devices (useful if you have multiple USB soundcards that are always connected)
function toggle_audio_output()
  local current = hs.audiodevice.defaultOutputDevice()
  local speakers = hs.audiodevice.findOutputByName(speakerDevice)
  local headphones = hs.audiodevice.findOutputByName(headphoneDevice)

  if not speakers or not headphones then
    hs.notify.new({title="Hammerspoon", informativeText="ERROR: Some audio devices missing", ""}):send()
    return
  end

  if current:name() == speakers:name() then
    headphones:setDefaultOutputDevice()
  else
    speakers:setDefaultOutputDevice()
  end

  hs.notify.new({
    title='Hammerspoon',
    informativeText='Default output device:'..hs.audiodevice.defaultOutputDevice():name()
  }):send()
end
