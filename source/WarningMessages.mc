import Toybox.Lang;

// Maps a pre-run warning code to the message shown on the warning screen.
// The phrases are passed in from string resources.
module WarningMessages {
	function messageFor(warning as Number, oncePerDay as String, sixPerWeek as String) as String? {
		if (warning == PreRunWarnings.ALREADY_LOGGED_TODAY) {
			return oncePerDay;
		}
		if (warning == PreRunWarnings.SEVEN_CONSECUTIVE_DAYS) {
			return sixPerWeek;
		}
		return null;
	}

	// The warning shown after the one at position, or null when it was the last.
	function nextPosition(position as Number, count as Number) as Number? {
		var next = position + 1;
		if ((next < 0) || (next >= count)) {
			return null;
		}
		return next;
	}
}
