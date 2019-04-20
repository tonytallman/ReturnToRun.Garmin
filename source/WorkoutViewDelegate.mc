using Toybox.WatchUi;

class WorkoutViewDelegate extends WatchUi.BehaviorDelegate {

    var workoutView;

    function initialize(workoutView) {
        BehaviorDelegate.initialize();
        self.workoutView = workoutView;
    }

    function onBack() {
        workoutView.dispose();
    }
}