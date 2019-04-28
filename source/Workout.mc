class Workout {
	var warmUpSeconds = 300;
	var runSeconds;
	var walkSeconds;
	var coolDownSeconds = 300;
	var repeatCount;
	
	function initialize(runSeconds, walkSeconds, repeatCount) {
		self.runSeconds = runSeconds;
		self.walkSeconds = walkSeconds;
		self.repeatCount = repeatCount;
	}
	
	function getActivityCount() {
		return repeatCount * 2 + 2;
	}
	
	function getActivityAtIndex(index) {
		if (index >= getActivityCount()) {
			return null;
		}
		
		if (index == 0) {
			return createWarmUpActivity(warmUpSeconds);
		}
		
		if (index == getActivityCount() - 1) {
			return createCoolDownActivity(coolDownSeconds);
		}
		
		if ((index % 2) == 1) {
			return createRunActivity(runSeconds);
		} else {
			return createWalkActivity(walkSeconds);
		}
	}
}

function getNumberOfWorkouts() {
	return 40;
}

function getWorkoutAtIndex(index) {
	switch (index) {
		case 0: return new Workout(60, 60, 3);
		case 1: return new Workout(60, 60, 4);
		case 2: return new Workout(60, 60, 5);
		case 3: return new Workout(60, 60, 6);
		case 4: return new Workout(60, 60, 7);
		case 5: return new Workout(60, 60, 8);
		case 6: return new Workout(60, 60, 9);
		case 7: return new Workout(60, 60, 10);
		case 8: return new Workout(60, 60, 11);
		case 9: return new Workout(60, 60, 12);
		case 10: return new Workout(60, 60, 13);
		case 11: return new Workout(60, 60, 14);
		case 12: return new Workout(60, 60, 15);

		case 13: return new Workout(120, 60, 3);
		case 14: return new Workout(120, 60, 4);
		case 15: return new Workout(120, 60, 5);
		case 16: return new Workout(120, 60, 6);
		case 17: return new Workout(120, 60, 7);
		case 18: return new Workout(120, 60, 8);
		case 19: return new Workout(120, 60, 9);
		case 20: return new Workout(120, 60, 10);

		case 21: return new Workout(180, 60, 3);
		case 22: return new Workout(180, 60, 4);
		case 23: return new Workout(180, 60, 5);
		case 24: return new Workout(180, 60, 6);
		case 25: return new Workout(180, 60, 7);
		case 26: return new Workout(180, 60, 8);

		case 27: return new Workout(240, 60, 2);
		case 28: return new Workout(240, 60, 3);
		case 29: return new Workout(240, 60, 4);
		case 30: return new Workout(240, 60, 5);
		case 31: return new Workout(240, 60, 6);

		case 32: return new Workout(540, 60, 1);
		case 33: return new Workout(540, 60, 2);
		case 34: return new Workout(540, 60, 3);

		case 35: return new Workout(840, 60, 1);
		case 36: return new Workout(840, 60, 2);

		case 37: return new Workout(1200, 60, 1);

		case 38: return new Workout(1500, 60, 1);

		case 39: return new Workout(1800, 60, 1);
		
		default: return null;
	}
}
