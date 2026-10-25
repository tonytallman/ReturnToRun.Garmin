import Toybox.Lang;

// The version shown in About is the AppVersion string resource. The manifest's
// version attribute is not readable at run time on this watch, so
// tools/check-version.sh fails the build check when the two differ.
module AppVersion {
	// "major.minor.patch", each a run of digits, like the manifest.
	function isWellFormed(text as String) as Boolean {
		var parts = TextPages.split(text, ".");
		if (parts.size() != 3) {
			return false;
		}
		for (var i = 0; i < parts.size(); i++) {
			var part = parts[i];
			if (part.length() == 0) {
				return false;
			}
			var chars = part.toCharArray();
			for (var j = 0; j < chars.size(); j++) {
				var c = chars[j];
				if ((c < '0') || (c > '9')) {
					return false;
				}
			}
		}
		return true;
	}

	function label(prefix as String, version as String) as String {
		return prefix + " " + version;
	}
}
