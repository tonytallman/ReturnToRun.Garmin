import Toybox.Lang;
import Toybox.WatchUi;

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
	function initialize() {
		Menu2InputDelegate.initialize();
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		if (item.getId() == :run) {
			openWorkoutList();
		}
	}

	function onBack() as Void {
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}
