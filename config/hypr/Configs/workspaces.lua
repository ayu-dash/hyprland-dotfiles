-- ####################
-- ### WORKSPACES  ###
-- ####################

-- eDP-1 (laptop) workspaces
for i = 1, 5 do
  hl.workspace_rule({
    workspace = tostring(i),
    monitor = "eDP-1",
    default = (i == 1),
  })
end

-- HDMI-A-1 (external) workspaces
for i = 6, 10 do
  hl.workspace_rule({
    workspace = tostring(i),
    monitor = "HDMI-A-1",
    default = (i == 6),
  })
end
