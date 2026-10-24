import Toybox.Lang;

// Menu labels for one program workout. The words come from the caller so the
// strings stay in resources and these rules can be tested without the UI.
module WorkoutListFormat {
	// A single repeat has no walk interval: that walk is the cool-down.
	function includesWalk(walkSeconds as Number, repeatCount as Number) as Boolean {
		return (walkSeconds > 0) && (repeatCount > 1);
	}

	// Whole minutes are "1" or "30". Anything else is "m:ss", including "0:10".
	function segmentClock(seconds as Number) as String {
		var duration = seconds;
		if (duration < 0) {
			duration = 0;
		}
		var minutes = duration / 60;
		var remainder = duration % 60;
		if (remainder == 0) {
			return minutes.toString();
		}
		return minutes.toString() + ":" + twoDigits(remainder);
	}

	function title(id as Number, runSeconds as Number, walkSeconds as Number, repeatCount as Number, runMark as String, walkMark as String, timesMark as String) as String {
		var text = "#" + id.toString() + "  " + runMark + segmentClock(runSeconds);
		if (includesWalk(walkSeconds, repeatCount)) {
			text = text + " " + walkMark + segmentClock(walkSeconds);
		}
		if (repeatCount > 1) {
			text = text + " " + timesMark + repeatCount.toString();
		}
		return text;
	}

	function subtitle(totalSeconds as Number, withWalks as Boolean, minuteWord as String, withWalksWord as String) as String {
		var text = roundedMinutes(totalSeconds).toString() + " " + minuteWord;
		if (withWalks) {
			text = text + " " + withWalksWord;
		}
		return text;
	}

	function withRecommendation(text as String, recommended as Boolean, marker as String) as String {
		if (!recommended) {
			return text;
		}
		return marker + text;
	}

	function roundedMinutes(totalSeconds as Number) as Number {
		return WorkoutDuration.roundedMinutes(totalSeconds);
	}

	function twoDigits(value as Number) as String {
		if (value < 10) {
			return "0" + value.toString();
		}
		return value.toString();
	}
}
