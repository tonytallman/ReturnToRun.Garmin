using Toybox.Lang;
using Toybox.WatchUi;

class WorkoutPickerDelegate extends WatchUi.PickerDelegate {

	var workoutIndexChangedObserver;

	function initialize(workoutIndexChangedObserver) {
		PickerDelegate.initialize();
		self.workoutIndexChangedObserver = workoutIndexChangedObserver;
	}

	function onCancel() as Lang.Boolean {
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		return true;
	}

	function onAccept(values) as Lang.Boolean {
		workoutIndexChangedObserver.setWorkoutIndex(values[0]);
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
}
