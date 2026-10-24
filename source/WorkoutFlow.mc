import Toybox.Lang;
import Toybox.WatchUi;

function openWorkoutList() as Void {
	var view = new WorkoutListView();
	var delegate = new WorkoutListDelegate();
	WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
}

function openWorkout(workoutIndex as Number) as Void {
	var warning = appServices().warningForToday();
	if (warning != null) {
		var view = new WarningView(workoutIndex, warning as Number);
		var delegate = new WarningViewDelegate(view);
		WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
		return;
	}
	startWorkout(workoutIndex);
}

function startWorkout(workoutIndex as Number) as Void {
	var view = new WorkoutView(workoutIndex);
	var delegate = new WorkoutViewDelegate(view);
	WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
}
