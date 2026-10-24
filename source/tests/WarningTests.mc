import Toybox.Lang;
import Toybox.Test;

(:test)
function testPreRunWarnings(logger as Test.Logger) as Boolean {
	logger.debug("pre-run warnings");
	var today = new CalendarDay(2026, 10, 8);
	TestSupport.expectEqual(1, PreRunWarnings.ALREADY_LOGGED_TODAY, "already code");
	TestSupport.expectEqual(2, PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, "streak code");

	var empty = TestSupport.openStore(100).progress;
	TestSupport.expectWarnings(empty.warnings(today), null, null, "empty history has no warning");

	var already = TestSupport.openStore(100).progress;
	already.addEntry(today, 4, Rating.OK);
	already.addEntry(today, 4, Rating.GOOD);
	TestSupport.expectWarnings(already.warnings(today), PreRunWarnings.ALREADY_LOGGED_TODAY, null, "two logs today are one warning");

	var yesterday = TestSupport.openStore(100).progress;
	yesterday.addEntry(today.plusDays(-1), 4, Rating.OK);
	TestSupport.expectWarnings(yesterday.warnings(today), null, null, "a run yesterday is fine");

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
	TestSupport.expectWarnings(both.warnings(today), PreRunWarnings.ALREADY_LOGGED_TODAY, PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, "both apply, already ran today first");
	return true;
}
