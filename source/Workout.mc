class Workout {
	var runSeconds;
	var walkSeconds;
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
			return createWarmUpActivity();
		}
		
		if (index == getActivityCount() - 1) {
			return createCoolDownActivity();
		}
		
		if ((index % 2) == 1) {
			return createRunActivity(runSeconds);
		} else {
			return createWalkActivity(walkSeconds);
		}
	}
}
