using Toybox.WatchUi;

class WorkoutPickerDelegate extends WatchUi.PickerDelegate {

	var workoutIndexChangedObserver;

	function initialize(workoutIndexChangedObserver) {
		PickerDelegate.initialize();
		self.workoutIndexChangedObserver = workoutIndexChangedObserver;
	}

	function onCancel() {
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
	}

	function onAccept(values) {
		var setWorkoutIndex = workoutIndexChangedObserver.method(:setWorkoutIndex);
		setWorkoutIndex.invoke(values[0]);
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
	}
}
