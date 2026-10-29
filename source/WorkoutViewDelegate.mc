import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutViewDelegate extends StartActionDelegate {
	var workoutView as WorkoutView;

	function initialize(workoutView as WorkoutView, touchPolicy as TouchPolicy) {
		StartActionDelegate.initialize(touchPolicy);
		self.workoutView = workoutView;
	}

	// Start/Stop pauses or resumes. The workout stays on screen.
	function onStartAction() as Void {
		workoutView.onSelectPressed();
	}

	// Taps are ignored during a workout, so a stray touch never pauses it,
	// except where Start cannot pause it (TouchPolicy.tapPausesWorkout).
	function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
		if (touchPolicy.tapPausesWorkout()) {
			workoutView.onSelectPressed();
		}
		return true;
	}

	// Back pauses a running workout, and from the paused state asks to end it.
	// It must not pop the view on its own.
	function onBack() as Boolean {
		workoutView.onBackPressed();
		return true;
	}
}
