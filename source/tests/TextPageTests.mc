import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

(:test)
function testTextPager(logger as Test.Logger) as Boolean {
	logger.debug("text paging");
	var pager = new TextPager(13, 5);
	TestSupport.expectEqual(3, pager.pageCount(), "13 lines at 5 a page");
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

	var exact = new TextPager(10, 5);
	TestSupport.expectEqual(2, exact.pageCount(), "an exact multiple has no empty page");
	var short = new TextPager(3, 5);
	TestSupport.expectEqual(1, short.pageCount(), "fits on one page");
	TestSupport.expectFalse(short.hasNext(), "no arrow when it fits");
	var empty = new TextPager(0, 5);
	TestSupport.expectEqual(1, empty.pageCount(), "empty text is one page");
	TestSupport.expectEqual(0, empty.endLine(), "with no lines");
	var tiny = new TextPager(3, 0);
	TestSupport.expectEqual(3, tiny.pageCount(), "at least one line a page");
	return true;
}

(:test)
function testTextPages(logger as Test.Logger) as Boolean {
	logger.debug("text pages");
	var measure = new CharacterMeasure();
	var lines = TextPages.lines("aa bb cc|dd||ee", 50, measure);
	TestSupport.expectEqual(5, lines.size(), "wrapped lines, breaks, and a blank line");
	TestSupport.expectEqual("aa bb", lines[0], "wrapped first line");
	TestSupport.expectEqual("cc", lines[1], "wrapped second line");
	TestSupport.expectEqual("dd", lines[2], "| starts a line");
	TestSupport.expectEqual("", lines[3], "|| leaves a blank line");
	TestSupport.expectEqual("ee", lines[4], "after the blank line");
	TestSupport.expectEqual(1, TextPages.lines("one", 100, measure).size(), "no breaks");
	TestSupport.expectEqual("github.com/|tonytallman/|ReturnToRun.Garmin",
		TextPages.breakAfterSlashes("github.com/tonytallman/ReturnToRun.Garmin"), "the link breaks after each slash");
	TestSupport.expectEqual("plain", TextPages.breakAfterSlashes("plain"), "no slash, no break");
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
