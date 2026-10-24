using Toybox.Lang;
using Toybox.WatchUi;

class WorkoutViewDelegate extends WatchUi.BehaviorDelegate {

    var workoutView;

    function initialize(workoutView) {
        BehaviorDelegate.initialize();
        self.workoutView = workoutView;
    }

    function onBack() as Lang.Boolean {
        workoutView.dispose();
        // Let the default back behavior pop the view.
        return false;
    }
}