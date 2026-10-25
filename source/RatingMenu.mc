import Toybox.Lang;
import Toybox.WatchUi;

// "How did it go?" The item ids are the Rating values, in that order, so the
// focus index is the rating. After a run focus starts on Good, the rating that
// moves on to the next workout; History starts on the entry's own rating.
class RatingMenu extends WatchUi.Menu2 {
	function initialize(focusRating as Number) {
		Menu2.initialize({:title=>WatchUi.loadResource(Rez.Strings.RatingTitle) as String});
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.RatingBad) as String, null, Rating.BAD, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.RatingOk) as String, null, Rating.OK, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.RatingGood) as String, null, Rating.GOOD, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.RatingGreat) as String, null, Rating.GREAT, null));
		setFocus(Rating.isValid(focusRating) ? focusRating : Rating.GOOD);
	}
}

// A rating is required. Back does nothing, so a finished run is never left unlogged.
class RatingDelegate extends WatchUi.Menu2InputDelegate {
	var workoutView as WorkoutView;

	function initialize(workoutView as WorkoutView) {
		Menu2InputDelegate.initialize();
		self.workoutView = workoutView;
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var id = item.getId();
		if (id instanceof Number) {
			workoutView.rate(id as Number);
		}
	}

	function onBack() as Void {
	}
}
