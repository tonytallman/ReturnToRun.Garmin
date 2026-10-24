import Toybox.Lang;

// Which attention pattern a segment gets. Warm-up, walk, and cool-down share the
// walk vibration. Workout complete is its own pattern and is not a segment.
module SegmentAlerts {
	const RUN = 1;
	const WALK = 2;
	const WORKOUT_COMPLETE = 3;

	// The activity enum has no type name, so this argument stays untyped.
	// Anything except a run, including warm-up, uses the walk vibration.
	function forActivityType(activityType) as Number {
		if (activityType == Run) {
			return RUN;
		}
		return WALK;
	}

	function forWorkoutComplete() as Number {
		return WORKOUT_COMPLETE;
	}
}
