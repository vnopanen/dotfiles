local cutils = require("common-utils")

local card_name =
  "alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"

local headphone_profile =
  "HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1, Mic2)"

local speaker_profile =
  "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"

local function get_target_profile(device)
  if device.properties["device.name"] ~= card_name then
    return nil
  end

  local headphones_present = nil

  for p in device:iterate_params("EnumRoute") do
    local route = cutils.parseParam(p, "EnumRoute")
    if route and route.name == "[Out] Headphones" then
      headphones_present = route.available == "yes"
      break
    end
  end

  if headphones_present == nil then
    return nil
  end

  local wanted = headphones_present and headphone_profile or speaker_profile

  for p in device:iterate_params("EnumProfile") do
    local profile = cutils.parseParam(p, "EnumProfile")
    if profile and profile.name == wanted and profile.available ~= "no" then
      return profile
    end
  end

  return nil
end

SimpleEventHook {
  name = "device/thinkpad-jack-profile-trigger",
  before = "device/select-route",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-params-changed" },
      Constraint { "event.subject.param-id", "=", "EnumRoute" },
    },
  },
  execute = function(event)
    local device = event:get_subject()
    if device.properties["device.name"] == card_name then
      event:get_source():call("push-event", "select-profile", device, nil)
    end
  end,
}:register()

SimpleEventHook {
  name = "device/thinkpad-jack-profile-select",
  before = "device/find-stored-profile",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-profile" },
    },
  },
  execute = function(event)
    local profile = get_target_profile(event:get_subject())
    if profile then
      event:set_data("selected-profile", profile)
    end
  end,
}:register()
