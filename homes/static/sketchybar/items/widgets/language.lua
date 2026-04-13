local ITEM_NAME = "widgets.language"

local function get_input_source_name()
	local handle = io.popen(
		"defaults read com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null"
	)
	if not handle then
		return "?"
	end
	local source = handle:read("*a") or ""
	handle:close()
	source = source:gsub("^%s*(.-)%s*$", "%1")

	local input_map = {
		["com.apple.keylayout.US"] = "en",
		["com.apple.keylayout.ABC"] = "en-us",
		["com.apple.keylayout.Serbian-Latin"] = "sr",
		["com.apple.keylayout.Serbian"] = "sr-cyr",
	}

	return input_map[source] or source
end

-- Avoid calling item:set() inside this event callback: SketchyBar can deadlock (Mach IPC)
-- when Lua callbacks invoke :set() while handling notifications (see SketchyBar issue #794).
local function set_label_deferred(label)
	label = (label or ""):gsub("[^%w._-]", "")
	if label == "" then
		label = "?"
	end
	os.execute("sketchybar --set " .. ITEM_NAME .. " label=" .. label .. " >/dev/null 2>&1 &")
end

sbar.add("event", "input.changed", "AppleSelectedInputSourcesChangedNotification")

local input = sbar.add("item", ITEM_NAME, {
	icon = { drawing = false },
	label = get_input_source_name(),
	position = "right",
})

input:subscribe("input.changed", function(_)
	set_label_deferred(get_input_source_name())
end)

input:subscribe("mouse.clicked", function(_)
	sbar.exec("osascript -e 'tell application \"System Events\" to key code 49 using control down'")
end)
