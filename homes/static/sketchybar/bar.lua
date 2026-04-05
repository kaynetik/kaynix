local colors = require("colors")
local settings = require("settings")

-- Bar strip color: theme black RGB with configurable alpha (`settings.bar_background_alpha`).
-- `colors.bar.bg` is not used here so opacity is controlled in one place.
sbar.bar({
	topmost = "window",
	height = 40,
	color = colors.with_alpha(colors.black, settings.bar_background_alpha),
	blur_radius = 0,
	padding_right = 2,
	padding_left = 2,
})
