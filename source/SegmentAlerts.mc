import Toybox.Lang;

// Which attention pattern a segment gets. Every segment shares one pulse.
// Workout complete is its own pattern and is not a segment.
module SegmentAlerts {
	const SEGMENT = 1;
	const WORKOUT_COMPLETE = 2;

	// The activity enum has no type name, so this argument stays untyped.
	// Warm-up, run, walk, and cool-down all return SEGMENT.
	function forActivityType(activityType) as Number {
		if ((activityType == WarmUp) || (activityType == Run) || (activityType == Walk) || (activityType == CoolDown)) {
			return SEGMENT;
		}
		return SEGMENT;
	}

	function forWorkoutComplete() as Number {
		return WORKOUT_COMPLETE;
	}
}
