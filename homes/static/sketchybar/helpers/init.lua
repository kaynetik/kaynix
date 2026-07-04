-- Add the sketchybar module to the package cpath (fallback for manual runs; the
-- LaunchAgent sets LUA_CPATH via modules/apps.nix).
local home = os.getenv("HOME") or ""
package.cpath = package.cpath .. ";" .. home .. "/.local/share/sketchybar_lua/?.so"
