local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
		color = colors.white,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
		background = { image = { corner_radius = settings.item_corner_radius } },
	},
	label = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Semibold"],
			size = 13.0,
		},
		color = colors.white,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		height = settings.item_height,
		corner_radius = settings.item_corner_radius,
		border_width = 0,
		image = {
			corner_radius = settings.item_corner_radius,
		},
	},
	popup = {
		background = {
			border_width = 1,
			corner_radius = 9,
			border_color = colors.popup.border,
			color = colors.popup.bg,
			shadow = { drawing = true },
		},
		blur_radius = 20,
	},
	blur_radius = 20,
	padding_left = 4,
	padding_right = 4,
	scroll_texts = true,
})
