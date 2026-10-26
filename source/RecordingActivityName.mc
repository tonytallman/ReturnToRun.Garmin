import Toybox.Lang;
import Toybox.WatchUi;

// Garmin suggests 15 characters for ActivityRecording session names; some
// devices allow more. Truncate the app name so " #<id>" always fits.
module RecordingActivityName {
	const MAX_LENGTH = 20;

	function forWorkout(workoutId as Number) as String {
		var base = WatchUi.loadResource(Rez.Strings.AppName) as String;
		var suffix = " #" + workoutId;
		var maxBase = MAX_LENGTH - suffix.length();
		if (maxBase < 1) {
			return suffix.substring(1, suffix.length());
		}
		if (base.length() > maxBase) {
			base = base.substring(0, maxBase);
		}
		return base + suffix;
	}
}
