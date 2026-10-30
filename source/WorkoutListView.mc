import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutListView extends WatchUi.Menu2 {
	var leaveTimer as LeaveTimer;

	// Run uses this list, and so does History's Add workout with its own title.
	function initialize(title as String) {
		Menu2.initialize({:title=>MenuTitle.of(title)});
		leaveTimer = new LeaveTimer();

		var services = appServices();
		var count = services.workoutCount();
		var focus = services.recommendedWorkoutIndex();
		if (focus < 0) {
			focus = 0;
		}
		if ((count > 0) && (focus >= count)) {
			focus = count - 1;
		}

		var runMark = WatchUi.loadResource(Rez.Strings.RunAbbrev) as String;
		var walkMark = WatchUi.loadResource(Rez.Strings.WalkAbbrev) as String;
		var timesMark = WatchUi.loadResource(Rez.Strings.TimesMark) as String;
		var minuteWord = WatchUi.loadResource(Rez.Strings.MinuteAbbrev) as String;
		var withWalksWord = WatchUi.loadResource(Rez.Strings.WithWalks) as String;
		var marker = WatchUi.loadResource(Rez.Strings.RecommendedMark) as String;
		var menuFocus = 0;
		var added = 0;

		for (var index = 0; index < count; index++) {
			var loaded = services.workoutAtIndex(index);
			if (loaded == null) {
				continue;
			}
			var workout = loaded as Workout;
			var label = WorkoutListFormat.title(index + 1, workout.runSeconds, workout.walkSeconds, workout.repeatCount, runMark, walkMark, timesMark);
			var withWalks = WorkoutListFormat.includesWalk(workout.walkSeconds, workout.repeatCount);
			var total = WorkoutDuration.totalSeconds(workout);
			var sub = WorkoutListFormat.subtitle(total, withWalks, minuteWord, withWalksWord);
			var recommended = index == focus;
			sub = WorkoutListFormat.withRecommendation(sub, recommended, marker);
			if (recommended) {
				menuFocus = added;
			}
			addItem(new WatchUi.MenuItem(label, sub, index, null));
			added = added + 1;
		}
		if (added > 0) {
			setFocus(menuFocus);
		}
	}

	function onShow() as Void {
		leaveTimer.schedule();
	}
}
