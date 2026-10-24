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

	function setRating(index as Number, rating as Number) as Boolean {
		return history.setRating(index, rating);
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
