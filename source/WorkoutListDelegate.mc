import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutListDelegate extends WatchUi.Menu2InputDelegate {
	function initialize() {
		Menu2InputDelegate.initialize();
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var id = item.getId();
		if (id instanceof Number) {
			openWorkout(id as Number);
		}
	}
}
