using Toybox.WatchUi;
using Toybox.System;

class MainMenuDelegate extends WatchUi.MenuInputDelegate {

	var workoutIndexChangedObserver;

    function initialize(workoutIndexChangedObserver) {
        MenuInputDelegate.initialize();
		self.workoutIndexChangedObserver = workoutIndexChangedObserver;
    }

    function onMenuItem(item) {
        if (item == :ChangeWorkout) {
            var view = new WorkoutPicker(workoutIndexChangedObserver.getWorkoutIndex());
            var delegate = new WorkoutPickerDelegate(workoutIndexChangedObserver);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
        } else if (item == :Instructions) {
            System.println("Instructions");
        } else if (item == :About) {
            System.println("About");
        }
    }
}
