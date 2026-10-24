import Toybox.Lang;
import Toybox.WatchUi;

// "End workout?" Yes leaves the session without logging. No stays paused.
class EndWorkoutDelegate extends WatchUi.ConfirmationDelegate {
	var workoutView as WorkoutView;

	function initialize(workoutView as WorkoutView) {
		ConfirmationDelegate.initialize();
		self.workoutView = workoutView;
	}

	function onResponse(response as WatchUi.Confirm) as Boolean {
		if (response == WatchUi.CONFIRM_YES) {
			workoutView.confirmEnd();
		} else {
			workoutView.declineEnd();
		}
		return true;
	}
}
