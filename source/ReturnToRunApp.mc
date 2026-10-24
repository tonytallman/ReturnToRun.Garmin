import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ReturnToRunApp extends Application.AppBase {
	var services as AppServices?;

	function initialize() {
		AppBase.initialize();
	}

	// onStart() is called on application start up
	function onStart(state) {
	}

	// onStop() is called when your application is exiting
	function onStop(state) {
	}

	function getServices() as AppServices {
		if (services == null) {
			var created = AppServices.production();
			created.start();
			services = created;
			return created;
		}
		return services as AppServices;
	}

	// Return the initial view of your application here
	function getInitialView() {
		var workoutIndex = getServices().recommendedWorkoutIndex();
		var view = new WorkoutSelectionView(workoutIndex);
		var delegate = new WorkoutSelectionViewDelegate(view);
		return [view, delegate];
	}
}
