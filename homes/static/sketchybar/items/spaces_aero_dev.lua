-- Aerospace workspace strip: batch CLI calls and debounce events to cut Mach IPC load.
-- Workspace names are strings (1-5, A, B, G, S, T, W, X per modules/aerospace.nix
-- bindings), never assume numeric.
local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Discover workspace names synchronously at load so items are created in order
-- (before front_app and friends). Falls back to 1-10 if aerospace is not up yet.
local workspace_names = {}
local list = io.popen("aerospace list-workspaces --all 2>/dev/null")
if list then
	for line in list:lines() do
		local name = trim(line)
		if name ~= "" then
			table.insert(workspace_names, name)
		end
	end
	list:close()
end
if #workspace_names == 0 then
	for i = 1, 10 do
		table.insert(workspace_names, tostring(i))
	end
end

local function workspace_bg(is_focused)
	if is_focused then
		return colors.bg2
	end
	return colors.with_alpha(colors.bg3, 0.45)
end

local query_workspaces =
	"aerospace list-workspaces --all --format '%{workspace}%{monitor-id}' --json"
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

local function apply_workspace_icons(workspace_name, open_windows, focused_workspace)
	local is_focused = workspace_name == focused_workspace
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
		if no_app and not is_focused then
			workspaces[workspace_name]:set({
				icon = { drawing = false },
				label = { drawing = false },
				background = { drawing = false },
				padding_right = 0,
				padding_left = 0,
			})
			return
		end
		if no_app and is_focused then
			icon_line = " -"
			workspaces[workspace_name]:set({
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

		workspaces[workspace_name]:set({
			icon = { drawing = true },
			label = { drawing = true, string = icon_line },
			background = {
				drawing = true,
				color = workspace_bg(is_focused),
			},
			padding_right = 1,
			padding_left = 1,
		})
	end)
end

-- Two async calls instead of N+1: one for focused workspace, one for all windows.
local function refresh_all_workspace_windows(on_focused)
	sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
		local focused = trim(tostring(focused_workspace))
		sbar.exec(
			"aerospace list-windows --all --format '%{workspace}%{app-name}' --json 2>/dev/null",
			function(all_windows)
				local by_workspace = {}
				for _, name in ipairs(workspace_names) do
					by_workspace[name] = {}
				end

				if type(all_windows) == "table" then
					for _, win in ipairs(all_windows) do
						local ws = trim(tostring(win.workspace))
						if by_workspace[ws] then
							table.insert(by_workspace[ws], win)
						end
					end
				end

				for _, name in ipairs(workspace_names) do
					apply_workspace_icons(name, by_workspace[name], focused)
				end

				if on_focused then
					on_focused(focused)
				end
			end
		)
	end)
end

local function refresh_all_workspace_displays()
	sbar.exec(query_workspaces, function(workspaces_and_monitors)
		sbar.exec(query_monitor, function(monitor_number)
			-- Aerospace numbers monitors left-to-right; sketchybar puts the primary
			-- display first. With the two-monitor layout those orders are swapped.
			-- Unmapped ids (3+ monitors) fall back to the aerospace id.
			local monitor_id_map
			if tonumber(monitor_number) ~= 1 then
				monitor_id_map = { [1] = 2, [2] = 1 }
			else
				monitor_id_map = { [1] = 1, [2] = 2 }
			end
			if type(workspaces_and_monitors) ~= "table" then
				return
			end
			for _, entry in ipairs(workspaces_and_monitors) do
				local name = trim(tostring(entry.workspace))
				local monitor_id = math.floor(entry["monitor-id"])
				workspace_monitor[name] = monitor_id_map[monitor_id] or monitor_id
			end
			for _, name in ipairs(workspace_names) do
				if workspace_monitor[name] then
					workspaces[name]:set({
						display = workspace_monitor[name],
					})
				end
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

for _, workspace_name in ipairs(workspace_names) do
	local workspace = sbar.add("item", {
		icon = {
			color = colors.white,
			highlight_color = colors.red,
			drawing = false,
			font = { family = settings.font.numbers },
			string = workspace_name,
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
		click_script = "aerospace workspace " .. workspace_name,
	})

	workspaces[workspace_name] = workspace

	workspace:subscribe("aerospace_workspace_change", function(env)
		local is_focused = trim(tostring(env.FOCUSED_WORKSPACE)) == workspace_name

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

		-- Switching workspaces can reveal stale icon state (windows opened or
		-- moved while the strip was not refreshed), so refresh here too.
		schedule_focus_refresh()
	end)

	workspace:subscribe("aerospace_focus_change", schedule_focus_refresh)

	workspace:subscribe("display_change", schedule_display_refresh)
end

refresh_all_workspace_windows(function(focused_workspace)
	if workspaces[focused_workspace] then
		workspaces[focused_workspace]:set({
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
