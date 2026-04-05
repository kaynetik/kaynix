-- Add the sketchybar module to the package cpath
local home = os.getenv("HOME") or ""
package.cpath = package.cpath .. ";" .. home .. "/.local/share/sketchybar_lua/?.so"

-- Build native helpers only when missing, or when forcing (after editing C sources).
-- Set SKETCHYBAR_FORCE_MAKE=1 to always run `make` (e.g. after changing event_providers).
-- Paths are resolved from CONFIG_DIR when set (LaunchAgent / Nix); else cwd must be the config root.
local config_dir = require("helpers.config_dir")
local cpu_probe = config_dir .. "/helpers/event_providers/cpu_load/bin/cpu_load"

local function helper_bin_missing()
	local probe = io.open(cpu_probe, "rb")
	if probe then
		probe:close()
		return false
	end
	return true
end

if os.getenv("SKETCHYBAR_FORCE_MAKE") == "1" or helper_bin_missing() then
	os.execute("(cd helpers && make)")
end
