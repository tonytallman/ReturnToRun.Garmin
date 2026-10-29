import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

(:test)
function testTextPager(logger as Test.Logger) as Boolean {
	logger.debug("text paging");
	var pager = new TextPager(13, [0, 5, 10] as Array<Number>);
	TestSupport.expectEqual(3, pager.pageCount(), "three pages");
	TestSupport.expectEqual(0, pager.firstLine(), "starts at the top");
	TestSupport.expectEqual(5, pager.endLine(), "first page");
	TestSupport.expectFalse(pager.hasPrevious(), "nothing above the top");
	TestSupport.expectFalse(pager.previous(), "Up at the top does nothing");
	TestSupport.expectTrue(pager.hasNext(), "more below");
	TestSupport.expectTrue(pager.next(), "Down");
	TestSupport.expectEqual(5, pager.firstLine(), "second page start");
	TestSupport.expectEqual(10, pager.endLine(), "second page end");
	TestSupport.expectTrue(pager.next(), "Down again");
	TestSupport.expectEqual(10, pager.firstLine(), "last page start");
	TestSupport.expectEqual(13, pager.endLine(), "a short last page");
	TestSupport.expectFalse(pager.hasNext(), "nothing below the end");
	TestSupport.expectFalse(pager.next(), "Down at the end does nothing");
	TestSupport.expectTrue(pager.previous(), "Up");
	TestSupport.expectEqual(5, pager.firstLine(), "back to the second page");

	var short = new TextPager(3, [0] as Array<Number>);
	TestSupport.expectEqual(1, short.pageCount(), "fits on one page");
	TestSupport.expectFalse(short.hasNext(), "no arrow when it fits");
	var empty = new TextPager(0, [] as Array<Number>);
	TestSupport.expectEqual(1, empty.pageCount(), "empty text is one page");
	TestSupport.expectEqual(0, empty.firstLine(), "starting at the top");
	TestSupport.expectEqual(0, empty.endLine(), "with no lines");
	return true;
}

(:test)
function testTextPageBreaks(logger as Test.Logger) as Boolean {
	logger.debug("page breaks between sentences");
	var measure = new CharacterMeasure();
	var three = [50, 50, 50] as Array<Number>;
	var pages = TextPages.paginate("Aa. Bb. Cc.", three, measure);
	TestSupport.expectStarts([0], pages[1] as Array<Number>, "three sentences fill one page");
	TestSupport.expectEqual(3, (pages[0] as Array).size(), "one line each");
	pages = TextPages.paginate("aa bb. cc dd.", three, measure);
	TestSupport.expectStarts([0, 2], pages[1] as Array<Number>, "the second sentence moves whole to page two");
	TestSupport.expectEqual("dd.", (pages[0] as Array)[3], "and keeps its lines");
	pages = TextPages.paginate("a b c d e f g", [10, 10, 10] as Array<Number>, measure);
	TestSupport.expectStarts([0, 3, 6], pages[1] as Array<Number>, "a sentence longer than a page splits at full pages");
	TestSupport.expectEqual(7, (pages[0] as Array).size(), "keeping every word");
	pages = TextPages.paginate("aa. bbbb cc", [100, 30] as Array<Number>, measure);
	TestSupport.expectStarts([0, 1], pages[1] as Array<Number>, "too long for the narrow row moves to the next page");
	TestSupport.expectEqual("bbbb cc", (pages[0] as Array)[1], "rewrapped to the wide first row");
	pages = TextPages.paginate("aa||bb", three, measure);
	TestSupport.expectEqual("", (pages[0] as Array)[1], "a blank line that fits stays");
	TestSupport.expectStarts([0], pages[1] as Array<Number>, "on one page");
	pages = TextPages.paginate("aa||bb", [50] as Array<Number>, measure);
	TestSupport.expectStarts([0, 1], pages[1] as Array<Number>, "a blank line never starts a page");
	TestSupport.expectEqual(2, (pages[0] as Array).size(), "it is dropped instead");
	pages = TextPages.paginate("", three, measure);
	TestSupport.expectStarts([0], pages[1] as Array<Number>, "empty text is one page");
	TestSupport.expectEqual(0, (pages[0] as Array).size(), "with no lines");
	return true;
}

(:test)
function testTextPages(logger as Test.Logger) as Boolean {
	logger.debug("text pages");
	var measure = new CharacterMeasure();
	var five = [50, 50, 50, 50, 50] as Array<Number>;
	var lines = TextPages.paginate("aa bb cc|dd||ee", five, measure)[0] as Array<String>;
	TestSupport.expectEqual(5, lines.size(), "wrapped lines, breaks, and a blank line");
	TestSupport.expectEqual("aa bb", lines[0], "wrapped first line");
	TestSupport.expectEqual("cc", lines[1], "wrapped second line");
	TestSupport.expectEqual("dd", lines[2], "| starts a line");
	TestSupport.expectEqual("", lines[3], "|| leaves a blank line");
	TestSupport.expectEqual("ee", lines[4], "after the blank line");

	lines = TextPages.paginate("Aa bb. Cc dd.|Is it? no.", [1000, 1000, 1000] as Array<Number>, measure)[0] as Array<String>;
	TestSupport.expectEqual(3, lines.size(), "one line per sentence");
	TestSupport.expectEqual("Aa bb.", lines[0], "first sentence keeps its period");
	TestSupport.expectEqual("Cc dd.", lines[1], "second sentence starts a line");
	TestSupport.expectEqual("Is it? no.", lines[2], "only a period ends a sentence");

	TestSupport.expectEqual("github.com/|tonytallman/|ReturnToRun.Garmin",
		TextPages.breakAfterSlashes("github.com/tonytallman/ReturnToRun.Garmin"), "the link breaks after each slash");
	TestSupport.expectEqual("plain", TextPages.breakAfterSlashes("plain"), "no slash, no break");
	return true;
}

// Built only for the Crossovers (see HandsBand); run the tests on instinctcrossover.
(:test :hands)
function testHandsBand(logger as Test.Logger) as Boolean {
	logger.debug("text kept out of the Crossover's hands");
	TestSupport.expectEqual(10, HandsBand.clearOf(10, 10, 66, 110), "a row above the band stays");
	TestSupport.expectEqual(56, HandsBand.clearOf(56, 10, 66, 110), "a row ending at the band stays");
	TestSupport.expectEqual(110, HandsBand.clearOf(60, 10, 66, 110), "a row reaching into the band moves below it");
	TestSupport.expectEqual(120, HandsBand.clearOf(120, 10, 66, 110), "a row below the band stays");
	TestSupport.expectEqual(30, HandsBand.centeredOf(30, 20, 66, 110), "a block clear of the band stays");
	TestSupport.expectEqual(56, HandsBand.centeredOf(78, 20, 66, 110), "a block across the band is centered around it");
	TestSupport.expectStarts([10, 30], HandsBand.spreadOf([10, 20] as Array<Number>, 0, 60), "equal gaps");
	TestSupport.expectStarts([0, 40], HandsBand.spreadOf([40, 40] as Array<Number>, 0, 60), "packed when they do not fit");
	TestSupport.expectEqual(23, HandsBand.halfHeight(), "the Crossover's band");
	return true;
}

(:test)
function testAppVersion(logger as Test.Logger) as Boolean {
	logger.debug("app version");
	var version = WatchUi.loadResource(Rez.Strings.AppVersion) as String;
	TestSupport.expectTrue(AppVersion.isWellFormed(version), "the AppVersion resource is major.minor.patch");
	TestSupport.expectTrue(AppVersion.isWellFormed("1.20.300"), "multi-digit parts");
	TestSupport.expectFalse(AppVersion.isWellFormed("1.2"), "two parts");
	TestSupport.expectFalse(AppVersion.isWellFormed("1.2.3.4"), "four parts");
	TestSupport.expectFalse(AppVersion.isWellFormed("1..3"), "an empty part");
	TestSupport.expectFalse(AppVersion.isWellFormed("1.2.x"), "a letter");
	TestSupport.expectFalse(AppVersion.isWellFormed(""), "empty");
	TestSupport.expectEqual("Version 0.0.1", AppVersion.label("Version", "0.0.1"), "About label");
	return true;
}

// Every word must fit one line, since TextWrap never splits a word.
// 16 characters is well under the 72% line width in FONT_XTINY.
(:test)
function testInstructionWordsFit(logger as Test.Logger) as Boolean {
	logger.debug("instruction words fit a line");
	var topics = InstructionsMenu.topics();
	TestSupport.expectEqual(6, topics.size(), "six topics");
	for (var i = 0; i < topics.size(); i++) {
		var topic = topics[i] as Array<ResourceId>;
		var title = WatchUi.loadResource(topic[0]) as String;
		var body = WatchUi.loadResource(topic[1]) as String;
		TestSupport.expectTrue(title.length() > 0 && title.length() <= 14, "short title " + title);
		var pieces = TextPages.split(body, TextPages.BREAK);
		for (var j = 0; j < pieces.size(); j++) {
			var words = TextPages.split(pieces[j], " ");
			for (var k = 0; k < words.size(); k++) {
				TestSupport.expectTrue((words[k] as String).length() <= 16, title + ": long word " + words[k]);
			}
		}
	}
	return true;
}
