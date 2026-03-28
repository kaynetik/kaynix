local colors = require("colors")
local settings = require("settings")

local secure_input = sbar.add("item", "widgets.secure_input", {
	position = "left",
	icon = {
		string = "󰌾",
		color = colors.red,
		font = {
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
		drawing = false,
	},
	label = {
		string = "SecureInput",
		color = colors.red,
		font = {
			style = settings.font.style_map["Bold"],
			size = 11.0,
		},
		drawing = false,
	},
	update_freq = 10,
	background = {
		color = colors.with_alpha(colors.red, 0.15),
		border_color = colors.red,
		border_width = 1,
		corner_radius = 4,
		drawing = false,
	},
	padding_left = 4,
	padding_right = 4,
})

secure_input:subscribe({ "routine", "system_woke" }, function()
	sbar.exec("ioreg -l -w 0 | grep -c SecureInputPID", function(output)
		local count = tonumber(output) or 0
		local active = count > 0
		secure_input:set({
			icon = { drawing = active },
			label = { drawing = active },
			background = { drawing = active },
		})
	end)
end)
