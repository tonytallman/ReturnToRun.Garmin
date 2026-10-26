import Toybox.Lang;

// Total and remaining time for a workout, using the same sequence as
// Workout.getActivityAtIndex: warm-up (always index 0), run/walk repeats
// including the walk before cool-down, and cool-down (always the last index).
// Warm-up and cool-down segments always exist, even at zero length. The total
// includes warm-up and cool-down; the time left shown during a workout counts
// only the run/walk main set between them.
module WorkoutDuration {
	function totalSeconds(workout as Workout) as Number {
		return workout.totalSeconds();
	}

	// True for the run/walk segments between warm-up and cool-down. The workout
	// screen shows the time left only there.
	function showsRemaining(workout as Workout, segmentIndex as Number) as Boolean {
		return (segmentIndex > 0) && (segmentIndex < (workout.getActivityCount() - 1));
	}

	// Seconds left in the main set: what is left of the current run/walk segment
	// plus every run/walk segment after it. During warm-up, cool-down, or for an
	// index out of range, it is 0.
	function remainingInMainSet(workout as Workout, segmentIndex as Number, secondsLeftInSegment as Number) as Number {
		if (!showsRemaining(workout, segmentIndex)) {
			return 0;
		}
		var coolDownIndex = workout.getActivityCount() - 1;
		var total = secondsLeftInSegment;
		if (total < 0) {
			total = 0;
		}
		for (var index = segmentIndex + 1; index < coolDownIndex; index++) {
			total = total + workout.secondsAtIndex(index);
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
