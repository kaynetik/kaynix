local settings = require("settings")
local globals = require("items.wallpaper.globals")
local helpers = require("items.wallpaper.helpers")
local components = require("items.wallpaper.components")
local pathguard = require("items.wallpaper.pathguard")

local wallpaper_root = pathguard.normalize_path(settings.wallpaper.path)

-- Key events
sbar.add("event", "request_bg")
sbar.add("event", "cycle_bg")
sbar.add("event", "select_bg")

components.bg:subscribe("request_bg", function(env)
	helpers.setAnchorText()
	local requested = env.REQUEST_BG == "true"

	components.bg:set({ popup = { drawing = requested } })
	components.bgAnchor:set({ popup = { drawing = requested } })
	components.previewAnchor:set({ popup = { drawing = requested } })

	local tbl = helpers.seekTbl(requested)
	helpers.entryToggle(tbl, false, requested)
end)

components.bg:subscribe("cycle_bg", function(env)
	if env.CYCLE == "next" then
		helpers.cycleNext()
	else
		helpers.cyclePrev()
	end
end)

local function setWallpaper()
	local raw = globals.selectedFilePath
	local path = pathguard.validate_wallpaper_path(raw, wallpaper_root)
	if not path then
		return
	end
	local f = io.open(path, "r")
	if not f then
		return
	end
	f:close()

	local inner = pathguard.applescript_escape_string(path)
	local applescript = 'tell application "System Events" to set picture of every desktop to POSIX file "'
		.. inner
		.. '"'
	local shell_arg = pathguard.shell_single_quote(applescript)
	sbar.exec("/usr/bin/osascript -e " .. shell_arg)
end

components.bg:subscribe("select_bg", function(env)
	if env.SELECT == "true" then
		components.bgAnchor:set({
			icon = {
				string = "􀏆",
				-- drawing = true,
			},
			drawing = true,
		})
		components.bg:set({
			icon = {
				string = "􀏆",
				-- drawing = true,
			},
			drawing = true,
		})
		local tbl = helpers.getFocusedEntryTbl()
		helpers.entryToggle(tbl, true, true)

		globals.depth = globals.depth + 1
		if globals.lockedFilePath then
			globals.depth = globals.depth - 1 < 1 and 1 or globals.depth - 1
			-- sbar.exec('skhd -k "ctrl - b"')
			setWallpaper()
		end
	else
		if globals.depth > 1 then
			-- Moved out one directory
			globals.depth = globals.depth - 1

			-- Need the table only
			local tbl = helpers.getFocusedEntryTbl()

			-- Unset highlight
			helpers.entryToggle(tbl, false, true)
			-- else
			-- sbar.exec('skhd -k "ctrl - b"')
		end
	end
end)
