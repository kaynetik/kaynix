local colors = require("colors")
local settings = require("settings")

local SOUND_PATH =
	"/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/Sounds/"
local DEFAULT_DURATION = 25 * 60

local active_timer_end = nil

local function play_sound(file)
	sbar.exec("afplay " .. SOUND_PATH .. file)
end

local function format_time(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

local timer = sbar.add("item", "widgets.pomodoro", {
	position = "right",
	icon = {
		string = "􀐱",
		color = colors.white,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	label = { drawing = false },
	update_freq = 0,
	popup = { align = "center" },
})

local function stop_timer()
	active_timer_end = nil
	timer:set({
		icon = { color = colors.white, padding_right = settings.paddings },
		label = { drawing = false },
		update_freq = 0,
		popup = { drawing = false },
	})
	play_sound("TrackingOff.aiff")
end

local function start_timer(duration_seconds)
	if not duration_seconds then
		return
	end
	active_timer_end = os.time() + duration_seconds
	timer:set({
		icon = { color = colors.green },
		update_freq = 1,
		popup = { drawing = false },
	})
	play_sound("TrackingOn.aiff")
	timer:trigger("routine")
end

local function open_custom_input()
	sbar.exec(
		'osascript -e \'display dialog "Enter time (MM:SS or Minutes):" '
			.. 'default answer "" '
			.. 'with title "Set Timer" '
			.. 'buttons {"Cancel", "Start"} '
			.. 'default button "Start"\'',
		function(result)
			local m, s = result:match("text returned:(%d+):(%d+)")
			if m and s then
				start_timer(tonumber(m) * 60 + tonumber(s))
				return
			end
			local m_only = result:match("text returned:(%d+)")
			if m_only then
				start_timer(tonumber(m_only) * 60)
			end
		end
	)
end

timer:subscribe("routine", function()
	if not active_timer_end then
		return
	end
	local now = os.time()
	local remaining = active_timer_end - now

	if remaining > 0 then
		timer:set({
			icon = { padding_right = math.floor(settings.paddings * 0.5) },
			label = { string = format_time(remaining), drawing = true },
		})
	else
		active_timer_end = nil
		timer:set({
			icon = { color = colors.white, padding_right = settings.paddings },
			label = { string = "Done!", drawing = true },
			update_freq = 0,
		})
		play_sound("GuideSuccess.aiff")
		sbar.exec(
			'osascript -e \'tell application "System Events" to display dialog "Timer finished!" '
				.. 'buttons {"OK"} default button "OK" with title "Pomodoro" with icon caution\''
		)
	end
end)

-- Popup preset buttons
local presets = { 5, 10, 25, 45 }

for _, mins in ipairs(presets) do
	local preset = sbar.add("item", "widgets.pomodoro." .. mins, {
		position = "popup." .. timer.name,
		icon = { drawing = false },
		label = {
			string = string.format("%2d Minutes", mins),
			padding_left = settings.paddings,
			padding_right = settings.paddings,
		},
	})

	preset:subscribe("mouse.clicked", function()
		start_timer(mins * 60)
	end)

	preset:subscribe("mouse.entered", function()
		preset:set({ background = { drawing = true, color = 0x33ffffff } })
	end)

	preset:subscribe("mouse.exited", function()
		preset:set({ background = { drawing = false } })
	end)
end

-- Custom duration input entry
local custom = sbar.add("item", "widgets.pomodoro.custom", {
	position = "popup." .. timer.name,
	icon = { drawing = false },
	label = {
		string = "Custom...",
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
})

custom:subscribe("mouse.clicked", function()
	timer:set({ popup = { drawing = false } })
	open_custom_input()
end)

custom:subscribe("mouse.entered", function()
	custom:set({ background = { drawing = true, color = 0x33ffffff } })
end)

custom:subscribe("mouse.exited", function()
	custom:set({ background = { drawing = false } })
end)

-- Mouse interactions on the main item
timer:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		if active_timer_end then
			stop_timer()
		else
			start_timer(DEFAULT_DURATION)
		end
	else
		local is_drawing = timer:query().popup.drawing
		timer:set({ popup = { drawing = (is_drawing == "off") } })
	end
end)

timer:subscribe("mouse.exited.global", function()
	timer:set({ popup = { drawing = false } })
end)

-- Bracket + padding to match sibling widget visual style
sbar.add("bracket", "widgets.pomodoro.bracket", { timer.name }, {
	background = { color = colors.bg3 },
})

sbar.add("item", "widgets.pomodoro.padding", {
	position = "right",
	width = settings.group_paddings,
})
