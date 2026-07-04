-- ###############
-- ### CURSORS ###
-- ###############

hl.on("hyprland.start", function()
  hl.exec_cmd("hyprctl setcursor Sweet-cursors 24")
end)

hl.config({
  cursor = {
    sync_gsettings_theme = true,
    no_hardware_cursors = true,
  }
})
