-- ################
-- ### MONITORS ###
-- ################


hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60",
  position = "auto",
  scale = 1,
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "1366x768@60",
  position = "auto-left",
  scale = 1,
})

-- mirroring screen
-- hl.monitor({
--   output = "",
--   mode = "preferred",
--   position = "auto",
--   scale = 1,
--   mirror = "eDP-1"
-- })
