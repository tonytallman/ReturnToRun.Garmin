import Toybox.Lang;

// Add Workout's date choice. It starts at today and steps back one day at a
// time. It never goes past today, because history is what was run.
class DateStepper {
	var today as CalendarDay;
	var daysBack as Number;

	function initialize(today as CalendarDay) {
		self.today = today;
		daysBack = 0;
	}

	function date() as CalendarDay {
		return today.plusDays(-daysBack);
	}

	function earlier() as Void {
		daysBack = daysBack + 1;
	}

	// False when already on today.
	function later() as Boolean {
		if (daysBack <= 0) {
			return false;
		}
		daysBack = daysBack - 1;
		return true;
	}

	function isToday() as Boolean {
		return daysBack == 0;
	}

	function isYesterday() as Boolean {
		return daysBack == 1;
	}
}
