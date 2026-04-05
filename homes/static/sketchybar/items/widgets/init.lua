require("items.widgets.battery")
require("items.widgets.secure_input")
-- require("items.widgets.qq")
-- require("items.widgets.wechat_and_qq")
require("items.widgets.language")
require("items.widgets.volume")
require("items.widgets.wifi")
-- require("items.widgets.weather")
require("items.widgets.cpu_and_temp")
require("items.widgets.slack")
require("items.widgets.telegram")
require("items.widgets.pomodoro")
-- require("items.widgets.front_app")
-- require("items.widgets.temperature")
-- require("items.widgets.cpu")

-- One shared background for the right-side widget strip (inner widget brackets use transparent fill).
local colors = require("colors")
local settings = require("settings")

sbar.add("bracket", "widgets.tray", {
	"widgets.pomodoro",
	"widgets.pomodoro.padding",
	"widgets.telegram",
	"widgets.telegram.padding",
	"widgets.slack",
	"widgets.slack.padding",
	"widgets.cpu",
	"widgets.temp",
	"widgets.cpu.padding",
	"widgets.wifi.padding",
	"widgets.wifi1",
	"widgets.wifi2",
	"widgets.wifi.group_padding",
	"widgets.volume2",
	"widgets.volume1",
	"widgets.volume.padding",
	"widgets.language",
	"widgets.battery.padding",
	"widgets.battery",
}, {
	background = {
		color = colors.bg3,
		corner_radius = settings.tray_corner_radius,
		height = settings.item_height,
	},
})
