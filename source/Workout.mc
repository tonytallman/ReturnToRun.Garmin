import Toybox.Lang;

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

	function getActivityCount() as Number {
		return (repeatCount * 2) + 1;
	}

	function getActivityAtIndex(index as Number) as Activity? {
		if (index >= getActivityCount()) {
			return null;
		}

		if (index == 0) {
			return createWarmUpActivity(warmUpSeconds);
		}

		if (index == (getActivityCount() - 1)) {
			return createCoolDownActivity(coolDownSeconds);
		}

		if ((index % 2) == 1) {
			return createRunActivity(runSeconds);
		}
		return createWalkActivity(walkSeconds);
	}
}
