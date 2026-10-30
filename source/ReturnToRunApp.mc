import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ReturnToRunApp extends Application.AppBase {
	var services as AppServices?;
	var breadcrumbs as Breadcrumbs?;

	function initialize() {
		AppBase.initialize();
	}

	// onStart() is called on application start up
	function onStart(state) {
		getBreadcrumbs().note("start v" + (WatchUi.loadResource(Rez.Strings.AppVersion) as String));
	}

	// onStop() is called when your application is exiting.
	// A run still in progress is saved rather than lost.
	function onStop(state) {
		var open = false;
		if (services != null) {
			open = (services as AppServices).finishActiveRecording();
		}
		getBreadcrumbs().note(open ? "stop, unfinished run saved" : "stop");
	}

	function getBreadcrumbs() as Breadcrumbs {
		if (breadcrumbs == null) {
			breadcrumbs = RingBreadcrumbs.production();
		}
		return breadcrumbs as Breadcrumbs;
	}

	function getServices() as AppServices {
		if (services == null) {
			var created = AppServices.production(getBreadcrumbs());
			services = created;
			return created;
		}
		return services as AppServices;
	}

	// Return the initial view of your application here.
	// The program and history load here so pressing Run only builds the list.
	// The watch stops an app whose single callback runs too long.
	function getInitialView() {
		startTour(self);
		getServices();
		var view = new MainMenuView();
		var delegate = new MainMenuDelegate();
		return [view, delegate];
	}
}
