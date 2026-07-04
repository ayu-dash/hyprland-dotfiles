-- ##############################
-- ### WINDOWS AND WORKSPACES ###
-- ##############################

hl.window_rule({
  match = {
    class = "^(nm-connection-editor)$"
  },
  float = true
})

hl.window_rule({
  match = {
    class = "^(blueman-manager)$"
  },
  float = true
})

hl.window_rule({
  match = {
    title = "^(blueman-manager)$"
  },
  float = true
})

hl.window_rule({
  match = {
    class = "^(xdg-desktop-portal-gtk)$"
  },
  tile = true
})

hl.window_rule({
  match = {
    class = "^(DesktopEditors)$"
  },
  center = true
})

