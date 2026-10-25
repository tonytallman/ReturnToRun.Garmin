import Toybox.Lang;

// The segment sequence for one workout: warm-up, then each run followed by its
// walk, then cool-down. Every run has a walk after it, including the last one,
// so there is always a walk before cool-down. A workout with no walk
// (walkSeconds 0, such as the final continuous runs) goes straight from its
// runs to cool-down.
class Workout {
	var warmUpSeconds as Number;
	var runSeconds as Number;
	var walkSeconds as Number;
	var coolDownSeconds as Number;
	var repeatCount as Number;

	function initialize(runSeconds as Number, walkSeconds as Number, repeatCount as Number, warmUpSeconds as Number, coolDownSeconds as Number) {
		self.runSeconds = runSeconds;
		self.walkSeconds = walkSeconds;
		self.repeatCount = repeatCount;
		self.warmUpSeconds = warmUpSeconds;
		self.coolDownSeconds = coolDownSeconds;
	}

	function hasWalks() as Boolean {
		return walkSeconds > 0;
	}

	function getActivityCount() as Number {
		var segmentsPerRepeat = hasWalks() ? 2 : 1;
		return (repeatCount * segmentsPerRepeat) + 2;
	}

	function getActivityAtIndex(index as Number) as Activity? {
		var count = getActivityCount();
		if ((index < 0) || (index >= count)) {
			return null;
		}

		if (index == 0) {
			return createWarmUpActivity(warmUpSeconds);
		}

		if (index == (count - 1)) {
			return createCoolDownActivity(coolDownSeconds);
		}

		if (!hasWalks() || ((index % 2) == 1)) {
			return createRunActivity(runSeconds);
		}
		return createWalkActivity(walkSeconds);
	}

	// The length of one segment without building an Activity. Out of range is 0.
	function secondsAtIndex(index as Number) as Number {
		var count = getActivityCount();
		if ((index < 0) || (index >= count)) {
			return 0;
		}
		if (index == 0) {
			return warmUpSeconds;
		}
		if (index == (count - 1)) {
			return coolDownSeconds;
		}
		if (!hasWalks() || ((index % 2) == 1)) {
			return runSeconds;
		}
		return walkSeconds;
	}

	// Warm-up, every run, every walk, and cool-down, worked out directly so the
	// workout list stays cheap to build on the watch.
	function totalSeconds() as Number {
		var perRepeat = runSeconds;
		if (hasWalks()) {
			perRepeat = perRepeat + walkSeconds;
		}
		return warmUpSeconds + (repeatCount * perRepeat) + coolDownSeconds;
	}
}
