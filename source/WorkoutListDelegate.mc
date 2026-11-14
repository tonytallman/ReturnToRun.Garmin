import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutListDelegate extends WatchUi.Menu2InputDelegate {
	var list as WorkoutListView;

	function initialize(list as WorkoutListView) {
		Menu2InputDelegate.initialize();
		self.list = list;
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var id = item.getId();
		if (id == WorkoutListItems.FIRST_SHORTCUT) {
			list.focusFirst();
			return;
		}
		if (id instanceof Number) {
			openWorkout(id as Number);
		}
	}
}
