local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local config_dir = require("helpers.config_dir")

-- Event provider: fires "cpu_update" every 2.0s. Use absolute path; $CONFIG_DIR is not always set in sh -c.
sbar.exec(
	"killall cpu_load 2>/dev/null; "
		.. config_dir
		.. "/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0"
)

-- SOC temperature: smctemp is slower than the cpu graph; throttle to avoid spawning every 2s.
local TEMP_INTERVAL_SEC = 5
local last_temp_ts = 0

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

local function updateTemperature(force)
	local now = os.time()
	if not force and (now - last_temp_ts) < TEMP_INTERVAL_SEC then
		return
	end
	last_temp_ts = now

	sbar.exec("/usr/local/bin/smctemp -c", function(output)
		local temperature = tonumber(output)
		if not temperature then
			return
		end
		temp:push({ temperature / 130. })

		local color = colors.green
		if temperature > 50 then
			if temperature < 70 then
				color = colors.yellow
			elseif temperature < 80 then
				color = colors.orange
			else
				color = colors.red
			end
		end

		temp:set({
			graph = { color = color },
			label = "􀇬 " .. temperature .. "󰔄",
		})
	end)
end

cpu:subscribe("cpu_update", function(env)
	local load = tonumber(env.total_load)
	cpu:push({ load / 100. })

	local color = colors.blue
	if load > 30 then
		if load < 60 then
			color = colors.yellow
		elseif load < 80 then
			color = colors.orange
		else
			color = colors.red
		end
	end

	cpu:set({
		graph = { color = color },
		label = "cpu " .. env.total_load .. "%",
	})
	updateTemperature(false)
end)

cpu:subscribe({ "system_woke", "power_source_change" }, function()
	updateTemperature(true)
end)

cpu:subscribe("mouse.clicked", function(_env)
	sbar.exec("open -a 'Activity Monitor'")
end)

sbar.add("item", "widgets.cpu.padding", {
	position = "right",
	width = settings.group_paddings,
})
