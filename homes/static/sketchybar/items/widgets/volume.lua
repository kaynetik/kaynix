local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local popup_width = 250

local volume_percent = sbar.add("item", "widgets.volume1", {
	position = "right",
	icon = { drawing = false },
	label = {
		string = "??%",
		padding_left = -1,
		font = { family = settings.font.numbers },
	},
})

local volume_icon = sbar.add("item", "widgets.volume2", {
	position = "right",
	padding_right = -1,
	popup = { align = "center" },
	icon = {
		string = icons.volume._100,
		width = 0,
		align = "left",
		color = colors.grey,
		font = {
			style = settings.font.style_map["Regular"],
			size = 14.0,
		},
	},
	label = {
		width = 25,
		align = "left",
		font = {
			style = settings.font.style_map["Regular"],
			size = 14.0,
		},
	},
})

sbar.add("item", "widgets.volume.padding", {
	position = "right",
	width = settings.group_paddings,
})

local volume_slider = sbar.add("slider", popup_width, {
	position = "popup." .. volume_icon.name,
	slider = {
		highlight_color = colors.blue,
		background = {
			height = 6,
			corner_radius = 3,
			color = colors.bg2,
		},
		knob = {
			string = "􀀁",
			drawing = true,
		},
	},
	background = { color = colors.bg1, height = 2, y_offset = -20 },
	click_script = 'osascript -e "set volume output volume $PERCENTAGE"',
})

volume_percent:subscribe("volume_change", function(env)
	local volume = tonumber(env.INFO)
	local icon = icons.volume._0
	if volume > 60 then
		icon = icons.volume._100
	elseif volume > 30 then
		icon = icons.volume._66
	elseif volume > 10 then
		icon = icons.volume._33
	elseif volume > 0 then
		icon = icons.volume._10
	end

	local lead = ""
	if volume < 10 then
		lead = "0"
	end

	volume_icon:set({ label = icon })
	volume_percent:set({ label = lead .. volume .. "%" })
	volume_slider:set({ slider = { percentage = volume } })
end)

-- The popup shows either the volume slider (left click) or the output-device
-- picker (right click). Track which one is open so the same button toggles it
-- shut, and the other button swaps content in place.
local popup_mode = "none"

local function volume_collapse_details()
	if volume_icon:query().popup.drawing == "on" then
		volume_icon:set({ popup = { drawing = false } })
	end
	sbar.remove("/volume.device\\.*/")
	popup_mode = "none"
end

local function volume_open_slider()
	sbar.remove("/volume.device\\.*/")
	volume_slider:set({ drawing = true })
	volume_icon:set({ popup = { drawing = true } })
	popup_mode = "slider"
end

-- Cap the visible label so long device names cannot overflow the popup
-- ("ThinkPad Thunderbolt 3 Dock USB Audio" -> "ThinkPad Thunderbolt 3 Dock").
-- Switching still uses the full untruncated name.
local max_device_chars = 27

local function device_label(name)
	local label = name:gsub("%s+$", "")
	if #label > max_device_chars then
		label = label:sub(1, max_device_chars):gsub("%s+$", "")
	end
	return label
end

-- Build the output-device list from plain device names: one bare
-- SwitchAudioSource call for the current device, one for the list, no parsing
-- beyond splitting lines. Output names are unique, so match the active device
-- and switch by name.
local function volume_open_devices()
	volume_slider:set({ drawing = false })
	sbar.remove("/volume.device\\.*/")
	volume_icon:set({ popup = { drawing = true } })
	popup_mode = "devices"

	sbar.exec("SwitchAudioSource -c -t output", function(current)
		-- Strip the trailing newline but keep any trailing space in the name,
		-- since the list entries carry it too (e.g. "iFi (by AMR) HD USB Audio ").
		local current_device = (current:gsub("[\r\n]+$", ""))

		sbar.exec("SwitchAudioSource -a -t output", function(available)
			local counter = 0
			for device in available:gmatch("[^\r\n]+") do
				local color = colors.grey
				if device == current_device then
					color = colors.white
				end
				sbar.add("item", "volume.device." .. counter, {
					position = "popup." .. volume_icon.name,
					width = popup_width,
					align = "center",
					label = { string = device_label(device), color = color },
					click_script = 'SwitchAudioSource -s "'
						.. device
						.. '" && sketchybar --set /volume.device\\.*/ label.color='
						.. colors.grey
						.. " --set $NAME label.color="
						.. colors.white,
				})
				counter = counter + 1
			end

			-- Escape hatch to the full Sound settings pane, like the macOS menu.
			sbar.add("item", "volume.device." .. counter, {
				position = "popup." .. volume_icon.name,
				width = popup_width,
				align = "center",
				label = { string = "Sound Settings...", color = colors.grey },
				click_script = "open /System/Library/PreferencePanes/Sound.prefpane",
			})
		end)
	end)
end

local function volume_click(env)
	local want = "slider"
	if env.BUTTON == "right" then
		want = "devices"
	end

	if popup_mode == want then
		volume_collapse_details()
	elseif want == "devices" then
		volume_open_devices()
	else
		volume_open_slider()
	end
end

local function volume_scroll(env)
	local delta = env.SCROLL_DELTA
	sbar.exec(
		'osascript -e "set volume output volume (output volume of (get volume settings) + '
			.. delta
			.. ')"'
	)
end

volume_icon:subscribe("mouse.clicked", volume_click)
volume_icon:subscribe("mouse.scrolled", volume_scroll)
volume_icon:subscribe("mouse.exited.global", volume_collapse_details)
volume_percent:subscribe("mouse.clicked", volume_click)
volume_percent:subscribe("mouse.scrolled", volume_scroll)
volume_percent:subscribe("mouse.exited.global", volume_collapse_details)
