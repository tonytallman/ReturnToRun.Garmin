using Toybox.WatchUi;

class WorkoutSelectionViewDelegate extends WatchUi.BehaviorDelegate {
	var workoutSelectionView;

    function initialize(workoutSelectionView) {
        BehaviorDelegate.initialize();
        self.workoutSelectionView = workoutSelectionView;
    }

    function onKey(evt) {
        if (evt.getKey() == KEY_ENTER) {
            var view = new WorkoutView(workoutSelectionView.workout);
            var delegate = new WorkoutViewDelegate(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onMenu() {
		var view = new Rez.Menus.MainMenu();
		var delegate = new MainMenuDelegate(workoutSelectionView);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
        return true;
    }
}
