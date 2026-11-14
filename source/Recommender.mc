import Toybox.Lang;

class Recommendation {
	var workoutId as Number;
	var programComplete as Boolean;

	function initialize(workoutId as Number, programComplete as Boolean) {
		self.workoutId = workoutId;
		self.programComplete = programComplete;
	}
}

// Pure recommendation rules: the next workout is the latest entry, moved only
// by its rating. Time since that run does not change the result.
module Recommender {
	function recommend(latest as HistoryEntry?, maxWorkoutId as Number) as Recommendation {
		if (latest == null) {
			return new Recommendation(FIRST_WORKOUT_ID, false);
		}
		var latestEntry = latest as HistoryEntry;
		var raw = latestEntry.workoutId + Rating.step(latestEntry.rating);
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
}
