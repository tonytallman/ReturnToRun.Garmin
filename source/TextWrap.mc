import Toybox.Graphics;
import Toybox.Lang;

// Width of a piece of text. The wrap rule depends on this port, not on a Dc,
// so it can be tested with a fake measure.
class TextMeasure {
	function initialize() {
	}

	function widthOf(text as String) as Number {
		return 0;
	}
}

// Measures with dc.getTextWidthInPixels, which every Connect IQ version has.
class DcTextMeasure extends TextMeasure {
	private var dc as Graphics.Dc;
	private var font as Graphics.FontType;

	function initialize(dc as Graphics.Dc, font as Graphics.FontType) {
		TextMeasure.initialize();
		self.dc = dc;
		self.font = font;
	}

	function widthOf(text as String) as Number {
		return dc.getTextWidthInPixels(text, font);
	}
}

// Greedy word wrap. Lines are joined with "\n" for one centered drawText.
// A single word wider than maxWidth stays on its own line rather than being split.
// Used instead of Graphics.fitTextToArea, out of caution about the watch firmware.
module TextWrap {
	function wrap(text as String, maxWidth as Number, measure as TextMeasure) as String {
		var result = "";
		var line = "";
		var rest = text;
		while (rest.length() > 0) {
			var space = rest.find(" ");
			var word = (space == null) ? rest : rest.substring(0, space as Number) as String;
			rest = (space == null) ? "" : rest.substring((space as Number) + 1, rest.length()) as String;
			if (word.length() == 0) {
				continue;
			}
			var candidate = (line.length() == 0) ? word : line + " " + word;
			if ((line.length() > 0) && (measure.widthOf(candidate) > maxWidth)) {
				result = (result.length() == 0) ? line : result + "\n" + line;
				line = word;
			} else {
				line = candidate;
			}
		}
		if (line.length() > 0) {
			result = (result.length() == 0) ? line : result + "\n" + line;
		}
		return result;
	}
}
