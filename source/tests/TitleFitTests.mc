import Toybox.Lang;
import Toybox.Test;

(:test)
function testTitleFitChord(logger as Test.Logger) as Boolean {
	logger.debug("width of a round display at a height");
	TestSupport.expectEqual(240, TitleFit.chordWidth(240, 120), "full width through the middle");
	TestSupport.expectEqual(0, TitleFit.chordWidth(240, 0), "nothing at the very top");
	TestSupport.expectEqual(0, TitleFit.chordWidth(240, 240), "nothing at the very bottom");
	TestSupport.expectEqual(194, TitleFit.chordWidth(240, 50), "the Program complete title line");
	TestSupport.expectEqual(TitleFit.chordWidth(240, 50), TitleFit.chordWidth(240, 190), "the same above and below the middle");
	return true;
}

(:test)
function testTitleFitFirstFitting(logger as Test.Logger) as Boolean {
	logger.debug("the first font whose width fits, largest first");
	TestSupport.expectEqual(0, TitleFit.firstFitting([100, 80, 60] as Array<Number>, 100), "the largest fits exactly");
	TestSupport.expectEqual(1, TitleFit.firstFitting([150, 80, 60] as Array<Number>, 100), "the next one fits");
	TestSupport.expectEqual(2, TitleFit.firstFitting([150, 120, 110] as Array<Number>, 100), "none fits: the smallest");
	TestSupport.expectEqual(0, TitleFit.firstFitting([150] as Array<Number>, 100), "a single font");
	return true;
}
