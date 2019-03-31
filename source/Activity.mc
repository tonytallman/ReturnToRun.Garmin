class Activity {
	var type;
	var seconds;
}

function createWarmUpActivity() {
	var activity = new Activity();
	activity.type = WarmUp;
	activity.seconds = 300;
	return activity;
}

function createCoolDownActivity() {
	var activity = new Activity();
	activity.type = CoolDown;
	activity.seconds = 300;
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
