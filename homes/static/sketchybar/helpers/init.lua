-- Add the sketchybar module to the package cpath
package.cpath = package.cpath
	.. ";/Users/"
	.. os.getenv("USER")
	.. "/.local/share/sketchybar_lua/?.so"

-- Build native helpers only when missing, or when forcing (after editing C sources).
-- Set SKETCHYBAR_FORCE_MAKE=1 to always run `make` (e.g. after changing event_providers).
local function helper_bin_missing()
	local probe = io.open("helpers/event_providers/cpu_load/bin/cpu_load", "rb")
	if probe then
		probe:close()
		return false
	end
	return true
end

if os.getenv("SKETCHYBAR_FORCE_MAKE") == "1" or helper_bin_missing() then
	os.execute("(cd helpers && make)")
end
