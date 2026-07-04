-- ##################
-- ### KEYBINDINGS ###
-- ##################

-- Applications
local terminal = "kitty"
local fileManager = "dolphin"
local browser = "brave"
local codeEditor = "code"

local scriptDir = os.getenv("HOME") .. "/.config/hypr/Scripts"

-- Scripts
local rofiLauncher = scriptDir .. "/RofiLauncher.py"
local wlogout = scriptDir .. "/Wlogout.py"
local audio = scriptDir .. "/Audio.py"
local brightness = scriptDir .. "/Brightness.py"
local gamemode = scriptDir .. "/GameMode.py"

-- Main modifier
local mainMod = "SUPER"

-- Determine if Celestia is the active theme
local function get_active_theme()
  local file = io.open(os.getenv("HOME") .. "/.config/hypr/Themes/ThemeVariables.conf", "r")
  if not file then return "NierAutomata" end
  local content = file:read("*all")
  file:close()
  local theme = content:match("%$theme_dir%s*=%s*%S+/Themes/([%w_-]+)")
  return theme or "NierAutomata"
end

local activeTheme = get_active_theme()

-- User Defined KeyBinds
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(codeEditor))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("python " .. gamemode))

if activeTheme == "Caelestia" then
  hl.bind(mainMod .. " + Space", hl.dsp.global("caelestia:launcher"))
  hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("python " .. rofiLauncher .. " calc"))
  hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("python " .. rofiLauncher .. " theme"))
  hl.bind(mainMod .. " + W", hl.dsp.global("caelestia:nexus"))
  -- hl.bind(mainMod .. " + S", hl.dsp.global("caelestia:nexus"))
  
  hl.bind(mainMod .. " + S", hl.dsp.global("caelestia:nexus"))
  hl.bind(mainMod .. " + SHIFT + CTRL + ALT + Space", hl.dsp.exec_cmd("caelestia emoji --picker"))
  hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("caelestia clipboard"))
  hl.bind("XF86PowerOff", hl.dsp.global("caelestia:session"))
  hl.bind(mainMod .. " + D", hl.dsp.global("caelestia:dashboard"))
else
  hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("python " .. rofiLauncher .. " menu"))
  hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("python " .. rofiLauncher .. " calc"))
  hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("python " .. rofiLauncher .. " theme"))
  hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("python " .. rofiLauncher .. " wall"))
  hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("python " .. rofiLauncher .. " config"))
  hl.bind(mainMod .. " + SHIFT + CTRL + ALT + Space", hl.dsp.exec_cmd("python " .. rofiLauncher .. " emoji"))
  hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("python " .. rofiLauncher .. " clip"))
  hl.bind("XF86PowerOff", hl.dsp.exec_cmd("python " .. rofiLauncher .. " session"))
end
hl.bind("XF86Launch2", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/remoteWin10 start"))
hl.bind("F12", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/remoteWin10 stop"))

-- Window Mode
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + CTRL + M", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + CTRL + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.window.pseudo())

-- Lockscreen & logout
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + ALT + M", hl.dsp.exit())

-- Screenshot
if activeTheme == "Caelestia" then
  hl.bind("Print", hl.dsp.global("caelestia:screenshotFreeze"))
  hl.bind(mainMod .. " + Print", hl.dsp.global("caelestia:screenshot"))
  hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.global("caelestia:screenshotFreezeClip"))
else
  hl.bind("Print", hl.dsp.exec_cmd("python " .. rofiLauncher .. " cap"))
  hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window"))
  hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m region"))
end

-- Group
hl.bind("CTRL + ALT + G", hl.dsp.group.toggle())
hl.bind("CTRL + ALT + Tab", hl.dsp.group.active({ index = 1 }))
hl.bind("CTRL + ALT + Right", hl.dsp.group.next())
hl.bind("CTRL + ALT + Left", hl.dsp.group.prev())

-- Move focus
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + Tab", hl.dsp.window.alter_zorder({ mode = "top" }))
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "d" }))

-- Resize active window (arrow keys)
hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.resize({ x = 20,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.window.resize({ x = 0, y = 20,  relative = true }), { repeating = true })

-- Resize active window (VIM keys)
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -20, y = 0 }), { repeat_ = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 20, y = 0 }), { repeat_ = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -20 }), { repeat_ = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 20 }), { repeat_ = true })

-- Move window (arrow keys)
hl.bind(mainMod .. " + CTRL + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.window.move({ direction = "d" }))

-- Move window (VIM keys)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "d" }))

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special())

-- Switch workspaces with mainMod + [0-9]
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- Move active window and follow to workspace
for i = 1, 9 do
  hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + CTRL + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(mainMod .. " + CTRL + BracketLeft", hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + CTRL + BracketRight", hl.dsp.window.move({ workspace = "+1" }))

-- Move active window silently (without following)
for i = 1, 9 do
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = false }))
hl.bind(mainMod .. " + SHIFT + BracketLeft", hl.dsp.window.move({ workspace = "-1", follow = false }))
hl.bind(mainMod .. " + SHIFT + BracketRight", hl.dsp.window.move({ workspace = "+1", follow = false }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Resize windows with SUPER + SHIFT + LMB drag
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize())

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("python " .. audio .. " raiseVolume"), { repeat_ = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("python " .. audio .. " lowerVolume"), { repeat_ = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("python " .. audio .. " muteToggle"), { repeat_ = true, locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("python " .. audio .. " micToggle"), { repeat_ = true, locked = true })
if activeTheme == "Caelestia" then
  hl.bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), { repeat_ = true, locked = true })
  hl.bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), { repeat_ = true, locked = true })
else
  hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("python " .. brightness .. " up"), { repeat_ = true, locked = true })
  hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("python " .. brightness .. " down"), { repeat_ = true, locked = true })
end

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
