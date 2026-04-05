return {
	paddings = 3.5,
	group_paddings = 4,

	item_height = 28,
	item_corner_radius = 9,
	tray_corner_radius = 8,

	-- Bar window fill: `colors.black` from the active theme at this opacity (0.0 to 1.0).
	bar_background_alpha = 0.2,

	-- This is a font configuration for SF Pro and SF Mono (installed manually)
	font = require("helpers.default_font"),
	-- Icon set: "sf_symbols" or "nerdfont" (see icons.lua).
	icons = "sf_symbols",

	wallpaper = {
		path = os.getenv("HOME") .. "/.config/wallpapers",
		scale = 0.09,
	},
}
