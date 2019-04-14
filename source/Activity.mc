class Activity {
	var type;
	var seconds;
}

function createWarmUpActivity(seconds) {
	var activity = new Activity();
	activity.type = WarmUp;
	activity.seconds = seconds;
	return activity;
}

function createCoolDownActivity(seconds) {
	var activity = new Activity();
	activity.type = CoolDown;
	activity.seconds = seconds;
	return activity;
}

function createWalkActivity(seconds) {
	var activity = new Activity();
	activity.type = Walk;
	activity.seconds = seconds;
	return activity;
}

function createRunActivity(seconds) {
	var activity = new Activity();
	activity.type = Run;
	activity.seconds = seconds;
	return activity;
}
