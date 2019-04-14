using Toybox.WatchUi;

class WorkoutSelectionViewDelegate extends WatchUi.BehaviorDelegate {
	var workoutSelectionView;

    function initialize(workoutSelectionView) {
        BehaviorDelegate.initialize();
        self.workoutSelectionView = workoutSelectionView;
    }
    
    function onStart() {
    	var view = new WorkoutView(workoutSelectionView.workout);
    	var delegate = new WorkoutViewDelegate();
		WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    // When a next page behavior occurs, onNextPage() is called.
    // @return [Boolean] true if handled, false otherwise
    function onNextPage() {
    	var workoutView = new WorkoutView(workoutSelectionView.workout);
    	var workoutViewDelegate = new WorkoutViewDelegate();
    	WatchUi.pushView(workoutView, workoutViewDelegate, WatchUi.SLIDE_UP);
    	return true;
    }

    // When a previous page behavior occurs, onPreviousPage() is called.
    // @return [Boolean] true if handled, false otherwise
    function onPreviousPage() {
    }

    // When a menu behavior occurs, onMenu() is called.
    // @return [Boolean] true if handled, false otherwise
    function onMenu() {
    	var workoutView = new WorkoutView(workoutSelectionView.workout);
    	var workoutViewDelegate = new WorkoutViewDelegate();
    	WatchUi.pushView(workoutView, workoutViewDelegate, WatchUi.SLIDE_UP);
    	return true;
    }

    // When a back behavior occurs, onBack() is called.
    // @return [Boolean] true if handled, false otherwise
    function onBack() {
    }

    // When a next mode behavior occurs, onNextMode() is called.
    // @return [Boolean] true if handled, false otherwise
    function onNextMode() {
    }

    // When a previous mode behavior occurs, onPreviousMode() is called.
    // @return [Boolean] true if handled, false otherwise
    function onPreviousMode() {
    }
}
