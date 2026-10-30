import Toybox.Lang;

// Turns a string resource into screen lines and pages. "|" in a resource
// starts a new line, and "||" leaves a blank line. Each sentence starts a new
// line and is word-wrapped with TextWrap.
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

	// Ends of sentences inside one "|" piece. Only ". " ends a sentence, so
	// "End workout? menu" stays whole.
	const SENTENCE_END = ". ";

	function sentences(piece as String) as Array<String> {
		var parts = split(piece, SENTENCE_END);
		for (var i = 0; i < parts.size() - 1; i++) {
			parts[i] = parts[i] + ".";
		}
		return parts;
	}

	// The text as screen lines, and the first line of each page. Line n of a
	// page is wrapped to widths[n], so pages can follow the screen's edge (the
	// widths' count is the lines a page holds). A page takes as many whole
	// sentences as fit, so a sentence is split across pages only when it is
	// longer than a page. A blank line (from "||") that does not fit is dropped,
	// so no page starts blank.
	function paginate(text as String, widths as Array<Number>, measure as TextMeasure) as Array<Array> {
		var perPage = widths.size();
		var lines = [] as Array<String>;
		var starts = [0] as Array<Number>;
		var used = 0;
		var pieces = split(text, BREAK);
		for (var i = 0; i < pieces.size(); i++) {
			var parts = sentences(pieces[i]);
			var blank = true;
			for (var j = 0; j < parts.size(); j++) {
				var rest = parts[j];
				while (rest.length() > 0) {
					var wrapped = TextWrap.wrapLines(rest, widths.slice((used < perPage) ? used : perPage - 1, null), measure);
					rest = "";
					if (wrapped.length() == 0) {
						break;
					}
					blank = false;
					var wrappedLines = split(wrapped, "\n");
					var size = wrappedLines.size();
					if (used + size <= perPage) {
						lines.addAll(wrappedLines);
						used += size;
					} else if (used > 0) {
						starts.add(lines.size());
						used = 0;
						rest = parts[j];
					} else {
						// Longer than a page: a full page, and the rest goes on.
						lines.addAll(wrappedLines.slice(0, perPage));
						starts.add(lines.size());
						for (var k = perPage; k < size; k++) {
							rest += ((k > perPage) ? " " : "") + wrappedLines[k];
						}
					}
				}
			}
			if (blank && (used > 0) && (used < perPage)) {
				lines.add("");
				used += 1;
			}
		}
		return [lines, starts] as Array<Array>;
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
