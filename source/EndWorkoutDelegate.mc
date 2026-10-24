import Toybox.Lang;
import Toybox.WatchUi;

// Passes the end-prompt answer to the workout. Back stays paused.
class EndWorkoutDelegate extends WatchUi.Menu2InputDelegate {
	var workoutView as WorkoutView;

	function initialize(workoutView as WorkoutView) {
		Menu2InputDelegate.initialize();
		self.workoutView = workoutView;
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var id = item.getId();
		if (id == WorkoutSession.RESUME) {
			workoutView.resumeFromEnd();
		} else if (id == WorkoutSession.SAVE) {
			workoutView.saveEarly();
		} else if (id == WorkoutSession.DISCARD) {
			workoutView.discard();
		}
	}

	function onBack() as Void {
		workoutView.declineEnd();
	}
}
