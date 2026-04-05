-- Aerospace workspace strip: batch CLI calls and debounce events to cut Mach IPC load.
local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local max_workspaces = 10

local function workspace_bg(is_focused)
	if is_focused then
		return colors.bg2
	end
	return colors.with_alpha(colors.bg3, 0.45)
end

local query_workspaces = "aerospace list-workspaces --all --format '%{workspace}%{monitor-id}' --json"
local query_monitor = "aerospace list-monitors --count"
local workspace_monitor = {}

sbar.add("item", {
	icon = {
		color = colors.white,
		highlight_color = colors.red,
		drawing = false,
	},
	label = {
		color = colors.grey,
		highlight_color = colors.white,
		drawing = false,
	},
	background = {
		color = colors.with_alpha(colors.bg1, colors.transparency),
		border_width = 0,
		height = settings.item_height,
		corner_radius = settings.tray_corner_radius,
		drawing = false,
	},
	padding_left = 6,
	padding_right = 0,
})

local workspaces = {}

local function apply_workspace_icons(workspace_index, open_windows, focused_workspace)
	local focused_num = tonumber(focused_workspace)
	local icon_line = ""
	local no_app = true
	for _, open_window in ipairs(open_windows) do
		no_app = false
		local app = open_window["app-name"]
		local lookup = app_icons[app]
		local icon = (lookup == nil) and app_icons["default"] or lookup
		icon_line = icon_line .. " " .. icon
	end
	sbar.animate("tanh", 10, function()
		if no_app and workspace_index ~= focused_num then
			workspaces[workspace_index]:set({
				icon = { drawing = false },
				label = { drawing = false },
				background = { drawing = false },
				padding_right = 0,
				padding_left = 0,
			})
			return
		end
		if no_app and workspace_index == focused_num then
			icon_line = " -"
			workspaces[workspace_index]:set({
				icon = { drawing = true },
				label = {
					string = icon_line,
					drawing = true,
					font = "sketchybar-app-font:Regular:16.0",
					y_offset = -1,
				},
				background = {
					drawing = true,
					color = workspace_bg(true),
				},
				padding_right = 1,
				padding_left = 1,
			})
		end

		workspaces[workspace_index]:set({
			icon = { drawing = true },
			label = { drawing = true, string = icon_line },
			background = {
				drawing = true,
				color = workspace_bg(workspace_index == focused_num),
			},
			padding_right = 1,
			padding_left = 1,
		})
	end)
end

-- One focused query, then per-workspace window lists (still N calls; avoids N duplicate focused queries).
local function refresh_all_workspace_windows(on_focused)
	sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
		for workspace_index = 1, max_workspaces do
			local get_windows = string.format(
				"aerospace list-windows --workspace %s --format '%%{app-name}' --json",
				workspace_index
			)
			sbar.exec(get_windows, function(open_windows)
				apply_workspace_icons(workspace_index, open_windows, focused_workspace)
			end)
		end
		if on_focused then
			on_focused(focused_workspace)
		end
	end)
end

local function refresh_all_workspace_displays()
	sbar.exec(query_workspaces, function(workspaces_and_monitors)
		sbar.exec(query_monitor, function(monitor_number)
			local monitor_id_map
			if tonumber(monitor_number) ~= 1 then
				monitor_id_map = { [1] = 2, [2] = 1 }
			else
				monitor_id_map = { [1] = 1, [2] = 2 }
			end
			for _, entry in ipairs(workspaces_and_monitors) do
				local space_index = tonumber(entry.workspace)
				local monitor_id = math.floor(entry["monitor-id"])
				workspace_monitor[space_index] = monitor_id_map[monitor_id]
			end
			for workspace_index = 1, max_workspaces do
				workspaces[workspace_index]:set({
					display = workspace_monitor[workspace_index],
				})
			end
		end)
	end)
end

local function debounced(delay_sec, fn)
	local seq = 0
	return function()
		seq = seq + 1
		local token = seq
		sbar.delay(delay_sec, function()
			if token ~= seq then
				return
			end
			fn()
		end)
	end
end

local schedule_focus_refresh = debounced(0.08, function()
	refresh_all_workspace_windows(nil)
end)
local schedule_display_refresh = debounced(0.15, function()
	refresh_all_workspace_windows(nil)
	refresh_all_workspace_displays()
end)

for workspace_index = 1, max_workspaces do
	local workspace = sbar.add("item", {
		icon = {
			color = colors.white,
			highlight_color = colors.red,
			drawing = false,
			font = { family = settings.font.numbers },
			string = workspace_index,
			padding_left = 10,
			padding_right = 5,
			background = { drawing = false },
		},
		label = {
			padding_right = 12,
			color = colors.grey,
			highlight_color = colors.white,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
			background = { drawing = false },
		},
		padding_right = 2,
		padding_left = 2,
		background = {
			color = workspace_bg(false),
			border_width = 0,
			height = settings.item_height,
			corner_radius = settings.tray_corner_radius,
		},
		click_script = "aerospace workspace " .. workspace_index,
	})

	workspaces[workspace_index] = workspace

	workspace:subscribe("aerospace_workspace_change", function(env)
		local focused_workspace = tonumber(env.FOCUSED_WORKSPACE)
		local is_focused = focused_workspace == workspace_index

		sbar.animate("tanh", 10, function()
			workspace:set({
				icon = { highlight = is_focused },
				label = { highlight = is_focused },
				background = {
					color = workspace_bg(is_focused),
					border_width = 0,
				},
			})
		end)
	end)

	workspace:subscribe("aerospace_focus_change", schedule_focus_refresh)

	workspace:subscribe("display_change", schedule_display_refresh)
end

refresh_all_workspace_windows(function(_focused_workspace)
	local fw = tonumber(_focused_workspace)
	if workspaces[fw] then
		workspaces[fw]:set({
			icon = { highlight = true },
			label = { highlight = true },
			background = {
				color = workspace_bg(true),
				border_width = 0,
			},
		})
	end
end)
refresh_all_workspace_displays()
