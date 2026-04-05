local colors = require("colors")
local settings = require("settings")
local presets = require("items.widgets.pomodoro_config")

local SOUND_PATH =
	"/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/Sounds/"

-- Sequencer state
local active_preset = nil   -- currently selected preset table
local cycle_index = 1       -- which work session we are in (1..preset.cycles)
local phase = "idle"        -- "idle" | "work" | "break" | "long_break" | "awaiting"
local session_end = nil     -- epoch time when the current phase ends

local function play_sound(file)
	sbar.exec("afplay " .. SOUND_PATH .. file)
end

local function format_time(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

-- Returns a short status string shown as the icon badge.
-- e.g. "W2/4" during work session 2 of 4, "B" during short break, "LB" during long break.
local function phase_badge()
	if phase == "work" then
		return string.format("W%d/%d", cycle_index, active_preset.cycles)
	elseif phase == "break" then
		return string.format("B%d/%d", cycle_index, active_preset.cycles)
	elseif phase == "long_break" then
		return "LB"
	elseif phase == "awaiting" then
		return "▶"
	end
	return ""
end

-- Main bar item
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

-- Forward declarations so phases can call each other
local enter_work, enter_break, enter_long_break, enter_awaiting, reset_all

-- Drives the countdown; also used by SketchyBar's update_freq tick.
local function tick()
	if not session_end then
		return
	end
	local remaining = session_end - os.time()

	if remaining > 0 then
		timer:set({
			icon = { padding_right = math.floor(settings.paddings * 0.5) },
			label = {
				string = phase_badge() .. " " .. format_time(remaining),
				drawing = true,
			},
		})
		return
	end

	-- Phase ended -- decide what comes next.
	if phase == "work" then
		play_sound("GuideSuccess.aiff")
		if cycle_index >= active_preset.cycles then
			enter_long_break()
		else
			enter_break()
		end
	elseif phase == "break" then
		play_sound("TrackingOff.aiff")
		cycle_index = cycle_index + 1
		enter_awaiting("work")
	elseif phase == "long_break" then
		play_sound("TrackingOff.aiff")
		cycle_index = 1
		enter_awaiting("long_break_done")
	end
end

-- Resets everything back to idle.
reset_all = function()
	phase = "idle"
	active_preset = nil
	cycle_index = 1
	session_end = nil
	timer:set({
		icon = { color = colors.white, padding_right = settings.paddings },
		label = { drawing = false },
		update_freq = 0,
		popup = { drawing = false },
	})
	play_sound("TrackingOff.aiff")
end

-- Puts the bar into a waiting state after a break.
-- kind: "work" (waiting to start next work session) | "long_break_done" (cycle complete)
enter_awaiting = function(kind)
	phase = "awaiting"
	session_end = nil
	local msg
	if kind == "long_break_done" then
		msg = "Cycle complete! Click to restart."
	else
		msg = string.format("Break done. Click to start session %d/%d.", cycle_index, active_preset.cycles)
	end

	timer:set({
		update_freq = 0,
		icon = { color = colors.yellow, padding_right = settings.paddings },
		label = { string = "▶ Ready", drawing = true },
	})
	play_sound("TrackingOn.aiff")

	-- macOS notification so the user knows even if the bar is not in view.
	sbar.exec(
		'osascript -e \'display notification "'
			.. msg
			.. '" with title "Pomodoro" sound name "Glass"\''
	)
end

enter_work = function()
	phase = "work"
	session_end = os.time() + active_preset.work * 60
	timer:set({
		icon = { color = colors.green, padding_right = math.floor(settings.paddings * 0.5) },
		label = {
			string = phase_badge() .. " " .. format_time(active_preset.work * 60),
			drawing = true,
		},
		update_freq = 1,
	})
	play_sound("TrackingOn.aiff")
	timer:trigger("routine")
end

enter_break = function()
	phase = "break"
	session_end = os.time() + active_preset.short_break * 60
	timer:set({
		icon = { color = colors.blue, padding_right = math.floor(settings.paddings * 0.5) },
		label = {
			string = phase_badge() .. " " .. format_time(active_preset.short_break * 60),
			drawing = true,
		},
		update_freq = 1,
	})
	play_sound("TrackingOn.aiff")
	timer:trigger("routine")
end

enter_long_break = function()
	phase = "long_break"
	session_end = os.time() + active_preset.long_break * 60
	timer:set({
		icon = { color = colors.magenta, padding_right = math.floor(settings.paddings * 0.5) },
		label = {
			string = "LB " .. format_time(active_preset.long_break * 60),
			drawing = true,
		},
		update_freq = 1,
	})
	play_sound("TrackingOn.aiff")
	timer:trigger("routine")
end

-- Subscribe to SketchyBar's per-second tick.
timer:subscribe("routine", tick)

-- Left-click: toggle popup (idle) or advance from awaiting state.
-- Right-click: stop/reset everything.
timer:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		reset_all()
		return
	end

	if phase == "awaiting" then
		-- User acknowledged the break -- start next work session.
		enter_work()
		return
	end

	if phase == "idle" then
		local is_drawing = timer:query().popup.drawing
		timer:set({ popup = { drawing = (is_drawing == "off") } })
	end
end)

timer:subscribe("mouse.exited.global", function()
	timer:set({ popup = { drawing = false } })
end)

-- Popup: one entry per preset + a stop button when running.
for i, preset in ipairs(presets) do
	local entry = sbar.add("item", "widgets.pomodoro.preset." .. i, {
		position = "popup." .. timer.name,
		icon = { drawing = false },
		label = {
			string = preset.name,
			padding_left = settings.paddings,
			padding_right = settings.paddings,
		},
	})

	entry:subscribe("mouse.clicked", function()
		active_preset = preset
		cycle_index = 1
		timer:set({ popup = { drawing = false } })
		enter_work()
	end)

	entry:subscribe("mouse.entered", function()
		entry:set({ background = { drawing = true, color = 0x33ffffff } })
	end)

	entry:subscribe("mouse.exited", function()
		entry:set({ background = { drawing = false } })
	end)
end

-- Stop entry (always visible in popup so user can abort mid-cycle).
local stop_entry = sbar.add("item", "widgets.pomodoro.stop", {
	position = "popup." .. timer.name,
	icon = { drawing = false },
	label = {
		string = "Stop",
		color = colors.red,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
})

stop_entry:subscribe("mouse.clicked", function()
	reset_all()
end)

stop_entry:subscribe("mouse.entered", function()
	stop_entry:set({ background = { drawing = true, color = 0x33ffffff } })
end)

stop_entry:subscribe("mouse.exited", function()
	stop_entry:set({ background = { drawing = false } })
end)

-- Bracket + padding to match sibling widget visual style.
sbar.add("bracket", "widgets.pomodoro.bracket", { timer.name }, {
	background = { color = colors.bg3 },
})

sbar.add("item", "widgets.pomodoro.padding", {
	position = "right",
	width = settings.group_paddings,
})
