using Toybox.Lang;
using Toybox.WatchUi;

class WorkoutSelectionViewDelegate extends WatchUi.BehaviorDelegate {
	var workoutSelectionView;

	function initialize(workoutSelectionView) {
		BehaviorDelegate.initialize();
		self.workoutSelectionView = workoutSelectionView;
	}

	function onKey(evt) as Lang.Boolean {
		if (evt.getKey() == KEY_ENTER) {
			var view = new WorkoutView(workoutSelectionView.workoutIndex);
			var delegate = new WorkoutViewDelegate(view);
			WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
			return true;
		}
		return false;
	}

	function onMenu() {
		var view = new Rez.Menus.MainMenu();
		var delegate = new MainMenuDelegate(workoutSelectionView);
		WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
		return true;
	}
}
