import Toybox.Lang;
import Toybox.Test;

(:test)
function testWarningMessages(logger as Test.Logger) as Boolean {
	logger.debug("warning messages");
	var already = "You already ran today";
	var rest = "Rest day recommended";
	var few = "Can't reach 4 runs this week";
	TestSupport.expectEqual(already, WarningMessages.lineFor(PreRunWarnings.ALREADY_LOGGED_TODAY, already, rest, few), "already ran");
	TestSupport.expectEqual(rest, WarningMessages.lineFor(PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, already, rest, few), "rest day");
	TestSupport.expectEqual(few, WarningMessages.lineFor(PreRunWarnings.TOO_FEW_RECENT_RUNS, already, rest, few), "weekly frequency");
	TestSupport.expectNull(WarningMessages.lineFor(0, already, rest, few), "unknown code");

	var none = [] as Array<Number>;
	TestSupport.expectEqual("", WarningMessages.textFor(none, already, rest, few), "no warnings");

	var today = [PreRunWarnings.ALREADY_LOGGED_TODAY] as Array<Number>;
	TestSupport.expectEqual(already, WarningMessages.textFor(today, already, rest, few), "one line");

	var both = [PreRunWarnings.ALREADY_LOGGED_TODAY, PreRunWarnings.TOO_FEW_RECENT_RUNS] as Array<Number>;
	TestSupport.expectEqual(already + "\n" + few, WarningMessages.textFor(both, already, rest, few), "keeps the given order");

	var swapped = [PreRunWarnings.TOO_FEW_RECENT_RUNS, PreRunWarnings.ALREADY_LOGGED_TODAY] as Array<Number>;
	TestSupport.expectEqual(few + "\n" + already, WarningMessages.textFor(swapped, already, rest, few), "does not resort");

	var streak = [PreRunWarnings.SEVEN_CONSECUTIVE_DAYS] as Array<Number>;
	TestSupport.expectEqual(rest, WarningMessages.textFor(streak, already, rest, few), "rest day line");

	var noisy = [99, PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, 0] as Array<Number>;
	TestSupport.expectEqual(rest, WarningMessages.textFor(noisy, already, rest, few), "unknown codes are skipped");

	var all = [PreRunWarnings.ALREADY_LOGGED_TODAY, PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, PreRunWarnings.TOO_FEW_RECENT_RUNS] as Array<Number>;
	TestSupport.expectEqual(already + "\n" + rest + "\n" + few, WarningMessages.textFor(all, already, rest, few), "every warning is included");
	return true;
}
