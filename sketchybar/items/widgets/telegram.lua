local colors = require("colors")
local settings = require("settings")

local telegram = sbar.add("item", "widgets.telegram", {
	position = "right",
	icon = {
		string = "󰘑",
		font = {
			style = settings.font.style_map["Regular"],
			size = 19.0,
		},
	},
	label = { font = { family = settings.font.numbers } },
	update_freq = 30,
	popup = { align = "center" },
})

telegram:subscribe({ "routine", "workspace_change" }, function()
	sbar.exec('lsappinfo info -only StatusLabel "Telegram"', function(status_info)
		local icon = "󰘑"
		local label = ""
		local icon_color = colors.green

		-- Extract label using pattern matching
		local label_match = status_info:match('"label"="([^"]*)"')

		if label_match then
			label = label_match

			-- Determine icon color and state based on Telegram notifications
			if label == "" or label == nil or label == "NULL" or label == "kCFNULL" then
				icon_color = colors.green -- No notifications
				label = ""
			elseif label == "•" then
				icon_color = colors.yellow -- Unread messages
			elseif label:match("^%d+$") then
				icon_color = colors.red -- Specific number of unread chats/messages
				if tonumber(label) > 10 then
					-- Limit display to prevent overflow
					label = "10+"
				end
			else
				-- Unexpected status, don't update
				return
			end
		else
			-- No valid status found
			return
		end

		telegram:set({
			icon = {
				string = icon,
				color = icon_color,
			},
			label = {
				string = label,
			},
		})
	end)
end)

telegram:subscribe("mouse.clicked", function(env)
	-- Optional: Add interaction when clicked
	-- Bring Telegram to foreground or toggle notification view
	sbar.exec("open -a Telegram")
end)

-- Add an optional popup with more detailed notification info
local telegram_popup = sbar.add("item", {
	position = "popup." .. telegram.name,
	icon = {
		string = "Notifications:",
		width = 120,
		align = "left",
	},
	label = {
		string = "Loading...",
		width = 100,
		align = "right",
	},
})

telegram:subscribe("mouse.entered", function()
	sbar.exec('lsappinfo info -only StatusLabel "Telegram"', function(status_info)
		local label_match = status_info:match('"label"="([^"]*)"')
		if label_match and label_match ~= "" then
			telegram_popup:set({
				label = { string = label_match .. " unread" },
			})
		end
	end)
end)

sbar.add("bracket", "widgets.telegram.bracket", { telegram.name }, {
	background = {
		color = colors.bg3,
	},
})

sbar.add("item", "widgets.telegram.padding", {
	position = "right",
	width = settings.group_paddings,
})
