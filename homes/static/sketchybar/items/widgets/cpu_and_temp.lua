local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local MACMON = "/etc/profiles/per-user/" .. (os.getenv("USER") or "kaynetik") .. "/bin/macmon"
local UPDATE_FREQ = 5

local temp = sbar.add("graph", "widgets.temp", 42, {
	position = "right",
	graph = { color = colors.blue },
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	label = {
		string = "􀇬 ??󰔄",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		align = "right",
		padding_right = 0,
		width = 0,
		y_offset = 4,
	},
	blur_radius = colors.blur_radius,
	padding_right = settings.paddings + 6,
})

local cpu = sbar.add("graph", "widgets.cpu", 42, {
	position = "right",
	update_freq = UPDATE_FREQ,
	graph = { color = colors.blue },
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	icon = { string = icons.cpu },
	label = {
		string = "cpu ??%",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		align = "right",
		padding_right = 0,
		width = 0,
		y_offset = 4,
	},
	padding_right = -6,
})

local function update()
	sbar.exec(MACMON .. " pipe -s 1 -i 500 2>/dev/null", function(output)
		if not output then
			return
		end

		local temperature, cpu_pct
		if type(output) == "table" then
			local t = output.temp
			temperature = t and tonumber(t.cpu_temp_avg)
			cpu_pct = tonumber(output.cpu_usage_pct)
		elseif type(output) == "string" and output ~= "" then
			temperature = tonumber(output:match('"cpu_temp_avg"%s*:%s*([%d%.]+)'))
			cpu_pct = tonumber(output:match('"cpu_usage_pct"%s*:%s*([%d%.]+)'))
		end

		if temperature then
			temp:push({ temperature / 130.0 })

			local color = colors.green
			if temperature >= 80 then
				color = colors.red
			elseif temperature >= 70 then
				color = colors.orange
			elseif temperature > 50 then
				color = colors.yellow
			end

			temp:set({
				graph = { color = color },
				label = "􀇬 " .. math.floor(temperature) .. "󰔄",
			})
		end

		if cpu_pct then
			local load = cpu_pct * 100
			cpu:push({ cpu_pct })

			local color = colors.blue
			if load >= 80 then
				color = colors.red
			elseif load >= 60 then
				color = colors.orange
			elseif load > 30 then
				color = colors.yellow
			end

			cpu:set({
				graph = { color = color },
				label = string.format("cpu %.0f%%", load),
			})
		end
	end)
end

cpu:subscribe("routine", update)
cpu:subscribe({ "system_woke", "power_source_change" }, update)

cpu:subscribe("mouse.clicked", function(_env)
	sbar.exec("open -a 'Activity Monitor'")
end)

sbar.add("item", "widgets.cpu.padding", {
	position = "right",
	width = settings.group_paddings,
})
