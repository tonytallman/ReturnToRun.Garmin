import Toybox.Lang;
import Toybox.WatchUi;

function openWorkoutList() as Void {
	var view = new WorkoutListView(WatchUi.loadResource(Rez.Strings.Run) as String);
	var delegate = new WorkoutListDelegate();
	WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
}

function openWorkout(workoutIndex as Number) as Void {
	var warnings = appServices().warningsForToday();
	if (warnings.size() > 0) {
		var view = new WarningView(workoutIndex, warnings, 0);
		var delegate = new WarningViewDelegate(view);
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
	var view = new WarningView(workoutIndex, warnings, next as Number);
	var delegate = new WarningViewDelegate(view);
	WatchUi.switchToView(view, delegate, WatchUi.SLIDE_LEFT);
}

function startWorkout(workoutIndex as Number) as Void {
	var view = new WorkoutView(workoutIndex);
	var delegate = new WorkoutViewDelegate(view);
	WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
}
