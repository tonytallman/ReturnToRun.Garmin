import Toybox.Lang;

// Total and remaining time for a workout, using the same sequence as
// Workout.getActivityAtIndex: warm-up, run/walk repeats including the walk
// before cool-down, and cool-down.
module WorkoutDuration {
	function totalSeconds(workout as Workout) as Number {
		var total = 0;
		var count = workout.getActivityCount();
		for (var index = 0; index < count; index++) {
			var activity = workout.getActivityAtIndex(index);
			if (activity != null) {
				total = total + (activity as Activity).seconds;
			}
		}
		return total;
	}

	// Seconds left in the current segment, plus every segment after it.
	function remainingSeconds(workout as Workout, segmentIndex as Number, secondsLeftInSegment as Number) as Number {
		var count = workout.getActivityCount();
		if ((segmentIndex < 0) || (segmentIndex >= count)) {
			return 0;
		}
		var total = secondsLeftInSegment;
		if (total < 0) {
			total = 0;
		}
		for (var index = segmentIndex + 1; index < count; index++) {
			var activity = workout.getActivityAtIndex(index);
			if (activity != null) {
				total = total + (activity as Activity).seconds;
			}
		}
		return total;
	}

	// Nearest minute. 30 seconds and above rounds up.
	function roundedMinutes(totalSeconds as Number) as Number {
		if (totalSeconds <= 0) {
			return 0;
		}
		return (totalSeconds + 30) / 60;
	}
}
