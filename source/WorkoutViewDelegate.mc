import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutViewDelegate extends WatchUi.BehaviorDelegate {
	var workoutView as WorkoutView;

	function initialize(workoutView as WorkoutView) {
		BehaviorDelegate.initialize();
		self.workoutView = workoutView;
	}

	// Start/Stop pauses or resumes. Returning true keeps the workout on screen.
	function onSelect() as Boolean {
		workoutView.onSelectPressed();
		return true;
	}

	// Back pauses a running workout, and from the paused state asks to end it.
	// It must not pop the view on its own.
	function onBack() as Boolean {
		workoutView.onBackPressed();
		return true;
	}
}
