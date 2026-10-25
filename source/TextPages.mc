import Toybox.Lang;

// Turns a string resource into screen lines. "|" in a resource starts a new
// line, and "||" leaves a blank line. Each piece is word-wrapped with TextWrap.
// UI-free: the width comes from a TextMeasure port.
module TextPages {
	const BREAK = "|";

	function split(text as String, separator as String) as Array<String> {
		var parts = [] as Array<String>;
		var rest = text;
		while (true) {
			var at = rest.find(separator);
			if (at == null) {
				parts.add(rest);
				return parts;
			}
			parts.add(rest.substring(0, at as Number) as String);
			rest = rest.substring((at as Number) + separator.length(), rest.length()) as String;
		}
		return parts;
	}

	function lines(text as String, maxWidth as Number, measure as TextMeasure) as Array<String> {
		var result = [] as Array<String>;
		var pieces = split(text, BREAK);
		for (var i = 0; i < pieces.size(); i++) {
			var wrapped = TextWrap.wrap(pieces[i], maxWidth, measure);
			if (wrapped.length() == 0) {
				result.add("");
				continue;
			}
			var wrappedLines = split(wrapped, "\n");
			for (var j = 0; j < wrappedLines.size(); j++) {
				result.add(wrappedLines[j]);
			}
		}
		return result;
	}

	// A link has no spaces to wrap at, so it breaks after each "/" instead:
	// "github.com/a/b" becomes "github.com/|a/|b".
	function breakAfterSlashes(link as String) as String {
		var parts = split(link, "/");
		var result = "";
		for (var i = 0; i < parts.size(); i++) {
			if (i > 0) {
				result += "/" + BREAK;
			}
			result += parts[i];
		}
		return result;
	}
}
