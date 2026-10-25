import Toybox.Lang;
import Toybox.Test;

// Ten pixels per character, so widths are easy to reason about.
(:test)
class CharacterMeasure extends TextMeasure {
	function initialize() {
		TextMeasure.initialize();
	}

	function widthOf(text as String) as Number {
		return text.length() * 10;
	}
}

(:test)
function testTextWrap(logger as Test.Logger) as Boolean {
	logger.debug("text wrap");
	var measure = new CharacterMeasure();
	TestSupport.expectEqual("", TextWrap.wrap("", 100, measure), "empty text");
	TestSupport.expectEqual("one two", TextWrap.wrap("one two", 70, measure), "fits exactly");
	TestSupport.expectEqual("one\ntwo", TextWrap.wrap("one two", 60, measure), "one pixel short wraps");
	TestSupport.expectEqual("aa bb\ncc dd\nee", TextWrap.wrap("aa bb cc dd ee", 50, measure), "several lines");
	TestSupport.expectEqual("a\nlongword\nb", TextWrap.wrap("a longword b", 30, measure), "a long word keeps its own line");
	TestSupport.expectEqual("a b", TextWrap.wrap("  a   b  ", 100, measure), "extra spaces collapse");
	return true;
}
