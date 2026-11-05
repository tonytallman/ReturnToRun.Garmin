import Toybox.Lang;
import Toybox.WatchUi;

function openWorkoutList() as Void {
	var view = new WorkoutListView(WatchUi.loadResource(Rez.Strings.Run) as String);
	var delegate = new WorkoutListDelegate();
	appServices().log.note("workout list");
	WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
}

function openWorkout(workoutIndex as Number) as Void {
	var warnings = appServices().warningsForToday();
	if (warnings.size() > 0) {
		noteWarning(warnings[0] as Number);
		var view = new WarningView(workoutIndex, warnings, 0);
		var delegate = new WarningViewDelegate(view, deviceTouchPolicy());
		WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
		return;
	}
	startWorkout(workoutIndex);
}

// Continue on a warning shows the next one in place, or starts the workout
// after the last. Cancel on any of them returns to the list.
function continuePastWarning(workoutIndex as Number, warnings as Array<Number>, position as Number) as Void {
	var next = WarningMessages.nextPosition(position, warnings.size());
	if (next == null) {
		startWorkout(workoutIndex);
		return;
	}
	noteWarning(warnings[next as Number] as Number);
	var view = new WarningView(workoutIndex, warnings, next as Number);
	var delegate = new WarningViewDelegate(view, deviceTouchPolicy());
	WatchUi.switchToView(view, delegate, WatchUi.SLIDE_LEFT);
}

function startWorkout(workoutIndex as Number) as Void {
	appServices().log.note("workout " + (workoutIndex + 1) + " started");
	var view = new WorkoutView(workoutIndex);
	var delegate = new WorkoutViewDelegate(view, deviceTouchPolicy());
	WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
}

function noteWarning(warning as Number) as Void {
	var name = "other";
	if (warning == PreRunWarnings.ALREADY_LOGGED_TODAY) {
		name = "once per day";
	} else if (warning == PreRunWarnings.SEVEN_CONSECUTIVE_DAYS) {
		name = "six per week";
	}
	appServices().log.note("warning: " + name);
}
