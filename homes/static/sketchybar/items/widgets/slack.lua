local colors = require("colors")
local settings = require("settings")

-- StatusLabel is omitted from the default dump; -all is required.
local STATUS_CMD = "lsappinfo -all info -only StatusLabel Slack"

local slack = sbar.add("item", "widgets.slack", {
	position = "right",
	icon = {
		string = "󰒱",
		font = {
			style = settings.font.style_map["Regular"],
			size = 19.0,
		},
	},
	label = { font = { family = settings.font.numbers } },
	update_freq = 30,
	updates = true,
})

local function parse_badge(raw)
	if type(raw) ~= "string" then
		return ""
	end
	local label = raw:match('"label"%s*=%s*"([^"]*)"')
	if not label then
		return ""
	end
	return label:match("^%s*(.-)%s*$") or ""
end

slack:subscribe({ "routine", "forced", "system_woke", "workspace_change" }, function()
	sbar.exec(STATUS_CMD, function(status_info)
		local label = parse_badge(status_info)
		local icon_color = colors.green

		if label == "•" or label == "●" then
			icon_color = colors.yellow
		elseif label:match("^%d+$") then
			icon_color = colors.red
		else
			label = ""
		end

		slack:set({
			icon = {
				string = "󰒱",
				color = icon_color,
			},
			label = {
				string = label,
			},
		})
	end)
end)

slack:subscribe("mouse.clicked", function()
	sbar.exec("open -a Slack")
end)

sbar.add("item", "widgets.slack.padding", {
	position = "right",
	width = settings.group_paddings,
})
