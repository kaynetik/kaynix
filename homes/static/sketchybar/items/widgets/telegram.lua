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
			-- Normalize the label for consistency
			label_match = label_match:match("^%s*(.-)%s*$") -- Trim whitespace

			-- Handle specific label states
			if label_match == "" or label_match == nil or label_match == "NULL" or label_match == "kCFNULL" then
				icon_color = colors.green -- No notifications
				label = ""
			elseif label_match == "•" then
				icon_color = colors.yellow -- Unread messages
			elseif label_match:match("^%d+$") then
				icon_color = colors.red -- Specific number of unread chats/messages
				if tonumber(label_match) > 10 then
					label = "10+" -- Limit display to prevent overflow
				else
					label = label_match
				end
			else
				-- Unexpected status
				print("Unexpected label value: " .. label_match)
				return
			end
		else
			-- No valid label found, assume no notifications
			print("No valid status info found")
			icon_color = colors.green
			label = ""
		end

		-- Update the Telegram widget
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
