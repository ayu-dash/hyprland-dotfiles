-- Dynamic active theme environment variables
local function get_active_theme_dir()
  local file = io.open(os.getenv("HOME") .. "/.config/hypr/Themes/ThemeVariables.conf", "r")
  if not file then return os.getenv("HOME") .. "/.config/hypr/Themes/NierAutomata" end
  local content = file:read("*all")
  file:close()
  local path = content:match("%$theme_dir%s*=%s*(%S+)")
  if path then
    path = path:gsub("%$HOME", os.getenv("HOME"))
    return path
  end
  return os.getenv("HOME") .. "/.config/hypr/Themes/NierAutomata"
end

local theme_dir = get_active_theme_dir()
hl.env("HYPR_THEME_DIR", theme_dir)
hl.env("KITTY_CONFIG_DIRECTORY", theme_dir .. "/Kitty/")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("KDE_SESSION_VERSION", "6")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("EDITOR", "micro")

hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "Wayland")
hl.env("XDG_MENU_PREFIX", "arch-")

-- Ensure XDG_DATA_DIRS contains flatpak paths
local xdg_data_dirs = os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
if not xdg_data_dirs:find("flatpak") then
  xdg_data_dirs = os.getenv("HOME") .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:" .. xdg_data_dirs
end
hl.env("XDG_DATA_DIRS", xdg_data_dirs)



hl.config({
  xwayland = {
    force_zero_scaling = true
  }
})

hl.config({
  ecosystem = {
    no_update_news = true
  }
})
