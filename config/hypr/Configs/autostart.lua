-- ################
-- ### AUTOSTART ###
-- ################

local scriptDir = os.getenv("HOME") .. "/.config/hypr/Scripts"

local function get_theme_activation_cmd()
  local file = io.open(os.getenv("HOME") .. "/.config/hypr/Themes/ThemeLoader.conf", "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  local cmd = content:match("exec%-once%s*=%s*(.-)\n") or content:match("exec%-once%s*=%s*(.+)$")
  if cmd then
    cmd = cmd:gsub("%$HOME", os.getenv("HOME"))
    return cmd
  end
  return nil
end

hl.on("hyprland.start", function()
  -- Theme activation
  local act_cmd = get_theme_activation_cmd()
  if act_cmd then
    hl.exec_cmd(act_cmd)
  else
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/Themes/NierAutomata/Activate.sh")
  end

  -- System services
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("systemctl --user import-environment QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE")

  -- Inhibit power key (handle via Hyprland keybind instead)
  hl.exec_cmd("systemd-inhibit --who='Hyprland config' --why='session keybind' --what=handle-power-key --mode=block sleep infinity & echo $! > /tmp/.hyprland-systemd-inhibit")

  -- Custom scripts (delayed mic LED sync)
  hl.exec_cmd("sh -c 'sleep 5 && python " .. scriptDir .. "/Audio.py syncMicLed'")
  hl.exec_cmd("python " .. scriptDir .. "/Wallpaper.py run")
  hl.exec_cmd("python " .. scriptDir .. "/Battery.py")

  -- Applets
  hl.exec_cmd("blueman-applet")

  -- Utilities
  hl.exec_cmd("udiskie")
  hl.exec_cmd("hypridle")

  -- Clipboard
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

hl.on("hyprland.shutdown", function()
  hl.exec_cmd("kill -9 \"$(cat /tmp/.hyprland-systemd-inhibit)\"")
end)
