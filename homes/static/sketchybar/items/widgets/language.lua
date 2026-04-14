local ITEM_NAME = "widgets.language"

local INPUT_MAP = {
	["com.apple.keylayout.US"] = "en",
	["com.apple.keylayout.ABC"] = "en-us",
	["com.apple.keylayout.Serbian-Latin"] = "sr",
	["com.apple.keylayout.Serbian"] = "sr-cyr",
}

local READ_CMD =
	"defaults read com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null"

local function parse_input_source(raw)
	local source = (raw or ""):gsub("^%s*(.-)%s*$", "%1")
	if source == "" then
		return "?"
	end
	return INPUT_MAP[source] or source
end

-- Sync read: acceptable at startup before the event loop is running.
local function get_input_source_sync()
	local handle = io.popen(READ_CMD)
	if not handle then
		return "?"
	end
	local raw = handle:read("*a") or ""
	handle:close()
	return parse_input_source(raw)
end

-- Deferred CLI set avoids Mach IPC deadlock when called from notification
-- callbacks (SketchyBar #794). The backgrounded `&` keeps os.execute near-instant.
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
	label = get_input_source_sync(),
	position = "right",
})

input:subscribe("input.changed", function(_)
	sbar.exec(READ_CMD, function(output)
		set_label_deferred(parse_input_source(output))
	end)
end)

input:subscribe("mouse.clicked", function(_)
	sbar.exec("osascript -e 'tell application \"System Events\" to key code 49 using control down'")
end)
