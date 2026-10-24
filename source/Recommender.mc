import Toybox.Lang;

class Recommendation {
	var workoutId as Number;
	var programComplete as Boolean;

	function initialize(workoutId as Number, programComplete as Boolean) {
		self.workoutId = workoutId;
		self.programComplete = programComplete;
	}
}

// Pure recommendation rules. Callers pass today so the rules do not read the clock.
module Recommender {
	const RESTART_DAYS_OFF = 6;

	function recommend(latest as HistoryEntry?, today as CalendarDay, maxWorkoutId as Number) as Recommendation {
		if (latest == null) {
			return new Recommendation(FIRST_WORKOUT_ID, false);
		}
		var latestEntry = latest as HistoryEntry;
		var daysOff = daysOffBetween(latestEntry.date, today);
		if (daysOff >= RESTART_DAYS_OFF) {
			return new Recommendation(FIRST_WORKOUT_ID, false);
		}
		var raw = latestEntry.workoutId + Rating.step(latestEntry.rating) - penalty(daysOff);
		var complete = raw > maxWorkoutId;
		var clamped = raw;
		if (clamped < FIRST_WORKOUT_ID) {
			clamped = FIRST_WORKOUT_ID;
		}
		if (clamped > maxWorkoutId) {
			clamped = maxWorkoutId;
		}
		return new Recommendation(clamped, complete);
	}

	// Full calendar days strictly between the latest run and today.
	// Run Monday, today Thursday => 2. Same day or the next day => 0.
	function daysOffBetween(lastRun as CalendarDay, today as CalendarDay) as Number {
		var delta = lastRun.daysUntil(today);
		if (delta <= 1) {
			return 0;
		}
		return delta - 1;
	}

	function penalty(daysOff as Number) as Number {
		if (daysOff <= 2) {
			return 0;
		}
		if (daysOff == 3) {
			return 1;
		}
		if (daysOff == 4) {
			return 2;
		}
		if (daysOff == 5) {
			return 3;
		}
		return 0;
	}
}
