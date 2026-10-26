import Toybox.Lang;

// Total and remaining time for a workout, using the same sequence as
// Workout.getActivityAtIndex: warm-up, run/walk repeats including the walk
// before cool-down, and cool-down. The total includes cool-down; the time
// remaining shown during a workout does not.
module WorkoutDuration {
	function totalSeconds(workout as Workout) as Number {
		return workout.totalSeconds();
	}

	// Seconds until cool-down starts: what is left of the current segment plus
	// every segment after it except cool-down. Warm-up counts. During cool-down,
	// or for an index out of range, it is 0.
	function remainingBeforeCoolDown(workout as Workout, segmentIndex as Number, secondsLeftInSegment as Number) as Number {
		var coolDownIndex = workout.getActivityCount() - 1;
		if ((segmentIndex < 0) || (segmentIndex >= coolDownIndex)) {
			return 0;
		}
		var total = secondsLeftInSegment;
		if (total < 0) {
			total = 0;
		}
		for (var index = segmentIndex + 1; index < coolDownIndex; index++) {
			total = total + workout.secondsAtIndex(index);
		}
		return total;
	}

	// The workout screen shows the time left in every segment except cool-down.
	function showsRemaining(workout as Workout, segmentIndex as Number) as Boolean {
		return (segmentIndex >= 0) && (segmentIndex < (workout.getActivityCount() - 1));
	}

	// Nearest minute. 30 seconds and above rounds up.
	function roundedMinutes(totalSeconds as Number) as Number {
		if (totalSeconds <= 0) {
			return 0;
		}
		return (totalSeconds + 30) / 60;
	}
}
