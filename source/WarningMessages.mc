import Toybox.Lang;

// Maps pre-run warning codes to the lines shown on the warning screen.
// The phrases are passed in from string resources.
module WarningMessages {
	function lineFor(warning as Number, alreadyRan as String, restDay as String, tooFew as String) as String? {
		if (warning == PreRunWarnings.ALREADY_LOGGED_TODAY) {
			return alreadyRan;
		}
		if (warning == PreRunWarnings.SEVEN_CONSECUTIVE_DAYS) {
			return restDay;
		}
		if (warning == PreRunWarnings.TOO_FEW_RECENT_RUNS) {
			return tooFew;
		}
		return null;
	}

	// Every known warning, in the order given. Unknown codes are skipped.
	function textFor(warnings as Array<Number>, alreadyRan as String, restDay as String, tooFew as String) as String {
		var text = "";
		var written = 0;
		for (var index = 0; index < warnings.size(); index++) {
			var line = lineFor(warnings[index] as Number, alreadyRan, restDay, tooFew);
			if (line == null) {
				continue;
			}
			if (written > 0) {
				text = text + "\n";
			}
			text = text + (line as String);
			written = written + 1;
		}
		return text;
	}
}
