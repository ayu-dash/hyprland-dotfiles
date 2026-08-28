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
    class = "^(org.freedesktop.impl.portal.desktop.kde)$"
  },
  float = true,
  center = true
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

-- fix ozone
hl.window_rule({
	match = {
		class = "^()$",
		title = "^()$"
	},
	no_blur = true
})
