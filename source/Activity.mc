import Toybox.Lang;

class Activity {
	var type;
	var seconds as Number = 0;
}

function createWarmUpActivity(seconds as Number) as Activity {
	var activity = new Activity();
	activity.type = WarmUp;
	activity.seconds = seconds;
	return activity;
}

function createCoolDownActivity(seconds as Number) as Activity {
	var activity = new Activity();
	activity.type = CoolDown;
	activity.seconds = seconds;
	return activity;
}

function createWalkActivity(seconds as Number) as Activity {
	var activity = new Activity();
	activity.type = Walk;
	activity.seconds = seconds;
	return activity;
}

function createRunActivity(seconds as Number) as Activity {
	var activity = new Activity();
	activity.type = Run;
	activity.seconds = seconds;
	return activity;
}
