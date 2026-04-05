local settings = require("settings")
local colors = require("colors")

sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
	icon = {
		color = colors.white,
		padding_left = 8,
		font = {
			style = settings.font.style_map["Black"],
			size = 12.0,
		},
		background = { drawing = false },
	},
	label = {
		color = colors.white,
		padding_right = 10,
		width = 80,
		align = "right",
		font = { family = settings.font.numbers },
		background = { drawing = false },
	},
	position = "right",
	update_freq = 30,
	padding_left = 1,
	padding_right = 1,
	background = {
		color = colors.bg3,
		border_width = 0,
		height = settings.item_height,
		corner_radius = settings.tray_corner_radius,
	},
})

sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke", "system_clock" }, function(env)
	cal:set({ icon = os.date("%a. %d %b "), label = os.date("%H:%M") })
end)
