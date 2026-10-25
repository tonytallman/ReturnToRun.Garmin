import Toybox.Lang;
import Toybox.WatchUi;

// "End workout?" with Resume first, so a stray press keeps the run going.
class EndWorkoutMenu extends WatchUi.Menu2 {
	function initialize() {
		Menu2.initialize({:title=>WatchUi.loadResource(Rez.Strings.EndWorkoutTitle) as String});
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.Resume) as String, null, WorkoutSession.RESUME, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.Save) as String, null, WorkoutSession.SAVE, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.Discard) as String, null, WorkoutSession.DISCARD, null));
		setFocus(0);
	}
}
