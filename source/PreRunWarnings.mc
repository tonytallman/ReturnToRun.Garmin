import Toybox.Lang;

// Pre-run warnings. Every warning that applies is returned in priority order.
// The warning screen shows them one at a time, in that order. Consecutive-day
// warnings are about calendar days that have at least one entry.
module PreRunWarnings {
	const ALREADY_LOGGED_TODAY = 1;
	const SEVEN_CONSECUTIVE_DAYS = 2;

	const PREVIOUS_WINDOW_DAYS = 6;

	// Every warning that applies today, highest priority first.
	function evaluate(history as HistoryStore, today as CalendarDay) as Array<Number> {
		var warnings = [] as Array<Number>;
		if (hasEntryOn(history, today)) {
			warnings.add(ALREADY_LOGGED_TODAY);
		}
		if (consecutivePreviousDays(history, today) >= PREVIOUS_WINDOW_DAYS) {
			warnings.add(SEVEN_CONSECUTIVE_DAYS);
		}
		return warnings;
	}

	function hasEntryOn(history as HistoryStore, day as CalendarDay) as Boolean {
		for (var i = 0; i < history.size(); i++) {
			var entry = history.entryAt(i) as HistoryEntry;
			if (entry.date.compare(day) == 0) {
				return true;
			}
		}
		return false;
	}

	function consecutivePreviousDays(history as HistoryStore, today as CalendarDay) as Number {
		var streak = 0;
		var cursor = today;
		var counting = true;
		for (var i = 0; i < PREVIOUS_WINDOW_DAYS; i++) {
			if (counting) {
				cursor = cursor.plusDays(-1);
				if (hasEntryOn(history, cursor)) {
					streak = streak + 1;
				} else {
					counting = false;
				}
			}
		}
		return streak;
	}
}
