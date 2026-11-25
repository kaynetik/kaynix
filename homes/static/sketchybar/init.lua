sbar = require("sketchybar")

-- One message to sketchybar instead of one per item.
sbar.begin_config()
require("bar")
require("default")
require("items")
sbar.end_config()

-- Without the event loop no Lua callbacks run.
sbar.event_loop()
