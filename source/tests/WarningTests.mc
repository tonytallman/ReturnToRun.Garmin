import Toybox.Lang;
import Toybox.Test;

(:test)
function testPreRunWarnings(logger as Test.Logger) as Boolean {
	logger.debug("pre-run warnings");
	var today = new CalendarDay(2026, 10, 8);
	TestSupport.expectEqual(1, PreRunWarnings.ALREADY_LOGGED_TODAY, "already code");
	TestSupport.expectEqual(2, PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, "streak code");
	TestSupport.expectEqual(3, PreRunWarnings.TOO_FEW_RECENT_RUNS, "frequency code");

	var empty = TestSupport.openStore(100).progress;
	TestSupport.expectWarnings(empty.warnings(today), PreRunWarnings.TOO_FEW_RECENT_RUNS, null, "empty history");

	var already = TestSupport.openStore(100).progress;
	already.addEntry(today, 4, Rating.OK);
	already.addEntry(today, 4, Rating.GOOD);
	TestSupport.expectWarnings(already.warnings(today), PreRunWarnings.ALREADY_LOGGED_TODAY, PreRunWarnings.TOO_FEW_RECENT_RUNS, "two logs today are one warning");

	var yesterday = TestSupport.openStore(100).progress;
	yesterday.addEntry(today.plusDays(-1), 4, Rating.OK);
	TestSupport.expectWarnings(yesterday.warnings(today), PreRunWarnings.TOO_FEW_RECENT_RUNS, null, "one recent run");

	var twoOnOneDay = TestSupport.openStore(100).progress;
	twoOnOneDay.addEntry(today.plusDays(-1), 4, Rating.OK);
	twoOnOneDay.addEntry(today.plusDays(-1), 5, Rating.OK);
	TestSupport.expectWarnings(twoOnOneDay.warnings(today), PreRunWarnings.TOO_FEW_RECENT_RUNS, null, "two entries are still too few");

	var threeOnOneDay = TestSupport.openStore(100).progress;
	threeOnOneDay.addEntry(today.plusDays(-1), 4, Rating.OK);
	threeOnOneDay.addEntry(today.plusDays(-1), 5, Rating.OK);
	threeOnOneDay.addEntry(today.plusDays(-1), 6, Rating.OK);
	TestSupport.expectWarnings(threeOnOneDay.warnings(today), null, null, "three entries on one day are enough");

	var tooOld = TestSupport.openStore(100).progress;
	tooOld.addEntry(today.plusDays(-7), 1, Rating.OK);
	tooOld.addEntry(today.plusDays(-7), 2, Rating.OK);
	tooOld.addEntry(today.plusDays(-7), 3, Rating.OK);
	TestSupport.expectWarnings(tooOld.warnings(today), PreRunWarnings.TOO_FEW_RECENT_RUNS, null, "today-7 is outside the window");

	var edge = TestSupport.openStore(100).progress;
	edge.addEntry(today.plusDays(-6), 1, Rating.OK);
	edge.addEntry(today.plusDays(-6), 2, Rating.OK);
	edge.addEntry(today.plusDays(-6), 3, Rating.OK);
	TestSupport.expectWarnings(edge.warnings(today), null, null, "today-6 is inside the window");

	var todayDoesNotCount = TestSupport.openStore(100).progress;
	todayDoesNotCount.addEntry(today, 8, Rating.OK);
	todayDoesNotCount.addEntry(today, 8, Rating.OK);
	todayDoesNotCount.addEntry(today, 8, Rating.OK);
	todayDoesNotCount.addEntry(today.plusDays(-1), 4, Rating.OK);
	todayDoesNotCount.addEntry(today.plusDays(-1), 5, Rating.OK);
	TestSupport.expectWarnings(todayDoesNotCount.warnings(today), PreRunWarnings.ALREADY_LOGGED_TODAY, PreRunWarnings.TOO_FEW_RECENT_RUNS, "today is excluded from the six-day count");

	var streak = TestSupport.openStore(100).progress;
	for (var offset = -6; offset <= -1; offset++) {
		streak.addEntry(today.plusDays(offset), 4, Rating.OK);
	}
	TestSupport.expectWarnings(streak.warnings(today), PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, null, "six previous days");

	var almost = TestSupport.openStore(100).progress;
	for (var recent = -5; recent <= -1; recent++) {
		almost.addEntry(today.plusDays(recent), 4, Rating.OK);
	}
	TestSupport.expectWarnings(almost.warnings(today), null, null, "five previous days is not seven");

	var doubled = TestSupport.openStore(100).progress;
	for (var near = -5; near <= -1; near++) {
		doubled.addEntry(today.plusDays(near), 4, Rating.OK);
	}
	doubled.addEntry(today.plusDays(-1), 5, Rating.OK);
	TestSupport.expectWarnings(doubled.warnings(today), null, null, "six entries over five days is not seven days");

	var broken = TestSupport.openStore(100).progress;
	broken.addEntry(today.plusDays(-1), 4, Rating.OK);
	for (var older = -6; older <= -3; older++) {
		broken.addEntry(today.plusDays(older), 4, Rating.OK);
	}
	TestSupport.expectWarnings(broken.warnings(today), null, null, "a gap stops the streak");

	var both = TestSupport.openStore(100).progress;
	both.addEntry(today, 9, Rating.OK);
	for (var day = -6; day <= -1; day++) {
		both.addEntry(today.plusDays(day), 4, Rating.OK);
	}
	TestSupport.expectWarnings(both.warnings(today), PreRunWarnings.ALREADY_LOGGED_TODAY, PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, "already logged and seven days");
	return true;
}
