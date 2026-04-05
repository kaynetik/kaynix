-- Pomodoro preset definitions.
--
-- Each preset drives a full work/break cycle sequence:
--   work -> break -> work -> break -> ... -> long_break -> (repeat)
--
-- Fields:
--   name        display name shown in the bar popup
--   work        work session length in minutes
--   short_break short break length in minutes
--   cycles      number of work sessions before a long break
--   long_break  long break length in minutes
--
-- After every break (short or long) the bar waits for the user to click
-- "Start" before beginning the next work session.

return {
	{
		name = "Classic (25/5)",
		work = 25,
		short_break = 5,
		cycles = 4,
		long_break = 15,
	},
	{
		name = "Deep Work (40/7)",
		work = 40,
		short_break = 7,
		cycles = 3,
		long_break = 20,
	},
}
