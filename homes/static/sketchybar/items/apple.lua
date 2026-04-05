local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

sbar.add("item", { width = 5 })

local apple = sbar.add("item", {
	icon = {
		font = { size = 16.0 },
		string = icons.apple,
		padding_right = 8,
		padding_left = 8,
		-- default.lua gives icons a separate rounded background; disable so one box draws cleanly
		background = { drawing = false },
	},
	label = { drawing = false },
	background = {
		color = colors.bg3,
		border_width = 0,
		height = settings.item_height,
		corner_radius = settings.tray_corner_radius,
	},
	padding_left = 1,
	padding_right = 1,
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

sbar.add("item", { width = 7 })
