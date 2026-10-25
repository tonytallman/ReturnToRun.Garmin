import Toybox.Lang;

// Application rules over the history store: recommendation, warnings, and the
// one-time program-complete flag. The flag records that the completion screen
// was shown. It is not set when completion is merely detected.
class Progress {
	private var history as HistoryStore;

	function initialize(history as HistoryStore) {
		self.history = history;
	}

	function recommend(today as CalendarDay) as Recommendation {
		return Recommender.recommend(history.latest(), today, history.maxWorkoutId());
	}

	function warnings(today as CalendarDay) as Array<Number> {
		return PreRunWarnings.evaluate(history, today);
	}

	function addEntry(date as CalendarDay, workoutId as Number, rating as Number) as Boolean {
		if (!history.add(date, workoutId, rating)) {
			return false;
		}
		// Logging workout 1 starts a program, so a later completion may show again.
		if (workoutId == FIRST_WORKOUT_ID) {
			history.setProgramCompleteShown(false);
		}
		return true;
	}

	// Logs a finished run. Returns true when the program-complete screen should
	// show now: this rating pushed the recommendation past the last workout and
	// the screen has not been shown for this program. A full history drops its
	// oldest entry as usual. A rejected entry shows nothing.
	function logWorkout(date as CalendarDay, workoutId as Number, rating as Number) as Boolean {
		if (!addEntry(date, workoutId, rating)) {
			return false;
		}
		return shouldShowProgramComplete(date);
	}

	function setRating(index as Number, rating as Number) as Boolean {
		return history.setRating(index, rating);
	}

	// History's rating change. Returns true when the program-complete screen
	// should show now: the entry is the newest, the new rating takes the
	// recommendation past the last workout, and the screen has not been shown
	// for this program. The same rule as logWorkout; the flag is not touched.
	function changeRating(index as Number, rating as Number, today as CalendarDay) as Boolean {
		if (!history.setRating(index, rating)) {
			return false;
		}
		if (index != 0) {
			return false;
		}
		return shouldShowProgramComplete(today);
	}

	// History's Add Workout, on any date up to today. Returns true when the
	// program-complete screen should show now, which needs the added entry to be
	// the newest. A backdated entry behind a newer one changes nothing shown.
	// An entry the cap rejects adds nothing and shows nothing.
	function addWorkout(date as CalendarDay, workoutId as Number, rating as Number, today as CalendarDay) as Boolean {
		if (!addEntry(date, workoutId, rating)) {
			return false;
		}
		if (history.lastAddedIndex != 0) {
			return false;
		}
		return shouldShowProgramComplete(today);
	}

	// Where the latest successful add landed in the newest-first list, or -1.
	function lastAddedIndex() as Number {
		return history.lastAddedIndex;
	}

	function deleteAt(index as Number) as Boolean {
		return history.deleteAt(index);
	}

	function deleteAtAndOlder(index as Number) as Boolean {
		return history.deleteAtAndOlder(index);
	}

	// Removes entries only. The completion-shown flag stays until workout 1 is logged.
	function clear() as Void {
		history.clear();
	}

	function size() as Number {
		return history.size();
	}

	function entryAt(index as Number) as HistoryEntry? {
		return history.entryAt(index);
	}

	function latest() as HistoryEntry? {
		return history.latest();
	}

	function isProgramCompleteShown() as Boolean {
		return history.isProgramCompleteShown();
	}

	function markProgramCompleteShown() as Void {
		history.setProgramCompleteShown(true);
	}

	// True when the latest rating would finish the program and the screen has not been shown.
	function shouldShowProgramComplete(today as CalendarDay) as Boolean {
		return recommend(today).programComplete && !isProgramCompleteShown();
	}
}
