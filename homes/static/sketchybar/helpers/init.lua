-- Fallback cpath for a manual lua run. The LaunchAgent sets LUA_CPATH in
-- modules/sketchybar.nix.
local home = os.getenv("HOME") or ""
package.cpath = package.cpath .. ";" .. home .. "/.local/share/sketchybar_lua/?.so"
