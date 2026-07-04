-- =============================================================================
-- Caelestia Theme Specific Keybindings
-- =============================================================================

local mainMod = "SUPER"
local scriptDir = os.getenv("HOME") .. "/.config/hypr/Scripts"
local rofiLauncher = scriptDir .. "/RofiLauncher.py"

-- Unbind default keybindings that are overridden by Caelestia
hl.unbind(mainMod .. " + Space")
hl.unbind(mainMod .. " + C")
hl.unbind(mainMod .. " + T")
hl.unbind(mainMod .. " + W")
hl.unbind(mainMod .. " + S")
hl.unbind(mainMod .. " + SHIFT + CTRL + ALT + Space")
hl.unbind(mainMod .. " + SHIFT + C")
hl.unbind("XF86PowerOff")
hl.unbind("Print")
hl.unbind(mainMod .. " + Print")
hl.unbind(mainMod .. " + SHIFT + Print")
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")

-- Bind Caelestia specific actions
hl.bind(mainMod .. " + Space", hl.dsp.global("caelestia:launcher"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("python " .. rofiLauncher .. " calc"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("python " .. rofiLauncher .. " theme"))
hl.bind(mainMod .. " + W", hl.dsp.global("caelestia:nexus"))
hl.bind(mainMod .. " + S", hl.dsp.global("caelestia:nexus"))
hl.bind(mainMod .. " + SHIFT + CTRL + ALT + Space", hl.dsp.exec_cmd("caelestia emoji --picker"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("caelestia clipboard"))
hl.bind("XF86PowerOff", hl.dsp.global("caelestia:session"))
hl.bind(mainMod .. " + D", hl.dsp.global("caelestia:dashboard"))

-- Screenshot
hl.bind("Print", hl.dsp.global("caelestia:screenshotFreeze"))
hl.bind(mainMod .. " + Print", hl.dsp.global("caelestia:screenshot"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.global("caelestia:screenshotFreezeClip"))

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), { repeat_ = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), { repeat_ = true, locked = true })
