using Toybox.Timer;
using Toybox.WatchUi;

class WorkoutView extends WatchUi.View {
	var workout;
	var workoutIndex;
	var currentActivityIndex;
	var currentActivity;

	var timer;
	var timeLeft;
	var countdownLabel;
	var activityNameLabel;

	function initialize(workoutIndex) {
		View.initialize();
		self.workoutIndex = workoutIndex;
		self.workout = getWorkoutAtIndex(workoutIndex);
		saveWorkoutIndex(workoutIndex);
		setCurrentActivity(0);
	}

	function dispose() {
		timer.stop();
		timer = null;
	}

	// Load your resources here
	function onLayout(dc) {
		setLayout(Rez.Layouts.WorkoutView(dc));
		countdownLabel = View.findDrawableById("CountdownLabel");
		activityNameLabel = View.findDrawableById("ActivityNameLabel");
		timer = new Timer.Timer();
		timer.start(method(:timerCallback), 1000, true);

		showCurrentActivityName();
		showTimeLeft();
	}
    
	function setCurrentActivity(activityIndex) {
		currentActivityIndex = activityIndex;

		currentActivity = workout.getActivityAtIndex(currentActivityIndex);
		if (currentActivity == null) {
			timer.stop();
			attentionForWorkoutComplete();
			return;
		}

		timeLeft = currentActivity.seconds;
		showTimeLeft();

		showCurrentActivityName();

		attentionForNewActivity(currentActivity.type);

		// Reaching the CoolDown activity is good enough to progress to the next workout next time.
		if (currentActivity.type == CoolDown) {
			saveWorkoutIndex(workoutIndex + 1);
		}
	}

	function showCurrentActivityName() {
		var activityName = "";    	
		switch (currentActivity.type) {
			case WarmUp:
				activityName =  WatchUi.loadResource(Rez.Strings.WarmUp);
				break;
			case CoolDown:
				activityName =  WatchUi.loadResource(Rez.Strings.CoolDown);
				break;
			case Walk:
				activityName =  WatchUi.loadResource(Rez.Strings.Walk);
				break;
			case Run:
				activityName =  WatchUi.loadResource(Rez.Strings.Run);
				break;
		}
		if (activityNameLabel != null) {
			activityNameLabel.setText(activityName);
		}
	}

	function timerCallback() {
		timeLeft -= 1;
		if (timeLeft == 0) {
			setCurrentActivity(currentActivityIndex + 1);
		}

		showTimeLeft();
	}

	function showTimeLeft() {        
		var string = getTimeAsString(timeLeft);

		if (countdownLabel != null) {
			countdownLabel.setText(string);
		}

		WatchUi.requestUpdate();
	}
}
