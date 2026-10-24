import Toybox.Lang;

// The pre-foundation app stored only the 0-based index of the workout to do next.
const LEGACY_WORKOUT_INDEX_KEY = "WorkoutIndex";

class LegacyMigration {
	private var maxWorkoutId as Number;

	function initialize(maxWorkoutId as Number) {
		self.maxWorkoutId = maxWorkoutId;
	}

	// Converts a leftover WorkoutIndex into one history entry when no history exists,
	// then deletes the key. If history already exists, the key is discarded so a later
	// clear cannot replay the old index. The stored index is the next workout, not a
	// log, so a positive index becomes a Good completion of the previous workout dated
	// yesterday: days off stays 0 (recommendation is unchanged) and today is still free
	// to run. Index 0 means nothing was completed.
	function apply(gateway as StorageGateway, progress as Progress, today as CalendarDay) as Boolean {
		var legacy = gateway.get(LEGACY_WORKOUT_INDEX_KEY);
		if (progress.size() > 0) {
			if (legacy != null) {
				gateway.remove(LEGACY_WORKOUT_INDEX_KEY);
			}
			return false;
		}
		if (legacy == null) {
			return false;
		}
		var index = asNumber(legacy);
		if (index == null) {
			gateway.remove(LEGACY_WORKOUT_INDEX_KEY);
			return false;
		}
		var nextIndex = index as Number;
		if (nextIndex < 0) {
			nextIndex = 0;
		}
		var maxIndex = maxWorkoutId - 1;
		if (nextIndex > maxIndex) {
			nextIndex = maxIndex;
		}
		if (nextIndex == 0) {
			gateway.remove(LEGACY_WORKOUT_INDEX_KEY);
			return false;
		}
		var added = progress.addEntry(today.plusDays(-1), nextIndex, Rating.GOOD);
		if (added) {
			gateway.remove(LEGACY_WORKOUT_INDEX_KEY);
		}
		return added;
	}
}
