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

	// One block of wrapped lines per sentence, so every sentence starts a line.
	// An empty piece (from "||") is a block of one blank line.
	function blocks(text as String, maxWidth as Number, measure as TextMeasure) as Array<Array<String> > {
		var result = [] as Array<Array<String> >;
		var pieces = split(text, BREAK);
		for (var i = 0; i < pieces.size(); i++) {
			var parts = sentences(pieces[i]);
			var added = false;
			for (var j = 0; j < parts.size(); j++) {
				var wrapped = TextWrap.wrap(parts[j], maxWidth, measure);
				if (wrapped.length() > 0) {
					result.add(split(wrapped, "\n"));
					added = true;
				}
			}
			if (!added) {
				result.add([""] as Array<String>);
			}
		}
		return result;
	}

	function flatten(blocks as Array<Array<String> >) as Array<String> {
		var result = [] as Array<String>;
		for (var i = 0; i < blocks.size(); i++) {
			result.addAll(blocks[i]);
		}
		return result;
	}

	function lines(text as String, maxWidth as Number, measure as TextMeasure) as Array<String> {
		return flatten(blocks(text, maxWidth, measure));
	}

	// The first line of each page. A page takes as many whole blocks as fit,
	// so a sentence is never split across pages. A block taller than a page
	// starts a new page and is split at line boundaries. A blank line that
	// does not fit stays at the end of its page, so no page starts blank.
	function pageStarts(blocks as Array<Array<String> >, linesPerPage as Number) as Array<Number> {
		var perPage = (linesPerPage < 1) ? 1 : linesPerPage;
		var starts = [0] as Array<Number>;
		var line = 0;
		var used = 0;
		for (var i = 0; i < blocks.size(); i++) {
			var block = blocks[i];
			var size = block.size();
			if ((used > 0) && (used + size > perPage)) {
				if ((size == 1) && (block[0].length() == 0)) {
					line += 1;
					continue;
				}
				starts.add(line);
				used = 0;
			}
			while (size > perPage) {
				line += perPage;
				size -= perPage;
				starts.add(line);
			}
			line += size;
			used += size;
		}
		return starts;
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
