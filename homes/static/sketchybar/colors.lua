-- Set SKETCHYBAR_THEME to switch palettes (e.g. tokyo_night, rose_pine).
-- Reload: sketchybar --reload

-- Default matches flake `sketchybar.theme` when SKETCHYBAR_THEME is unset (e.g. manual `lua` run).
local theme = os.getenv("SKETCHYBAR_THEME") or "rose_pine"
local mod = "colors_" .. theme
local ok, base = pcall(require, mod)

if not ok then
	io.stderr:write(
		"[sketchybar] theme '"
			.. theme
			.. "' failed ("
			.. tostring(base)
			.. "); using colors_tokyo_night\n"
	)
	base = require("colors_tokyo_night")
end

local colors = {}
for k, v in pairs(base) do
	colors[k] = v
end

colors.with_alpha = function(color, alpha)
	if alpha > 1.0 or alpha < 0.0 then
		return color
	end
	return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

return colors
