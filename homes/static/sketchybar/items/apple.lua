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
		border_color = colors.grey,
		border_width = 1,
		height = 28,
		corner_radius = 9,
	},
	padding_left = 1,
	padding_right = 1,
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

sbar.add("item", { width = 7 })
