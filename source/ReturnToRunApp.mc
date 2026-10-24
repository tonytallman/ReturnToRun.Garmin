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

	// onStop() is called when your application is exiting.
	// A run still in progress is saved rather than lost.
	function onStop(state) {
		if (services != null) {
			(services as AppServices).finishActiveRecording();
		}
	}

	function getServices() as AppServices {
		if (services == null) {
			var created = AppServices.production();
			services = created;
			return created;
		}
		return services as AppServices;
	}

	// Return the initial view of your application here
	function getInitialView() {
		var view = new MainMenuView();
		var delegate = new MainMenuDelegate();
		return [view, delegate];
	}
}
