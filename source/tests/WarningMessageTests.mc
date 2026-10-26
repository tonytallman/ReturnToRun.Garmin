import Toybox.Lang;
import Toybox.Test;

(:test)
function testWarningMessages(logger as Test.Logger) as Boolean {
	logger.debug("warning messages");
	var daily = "Running more than once a day is not recommended.";
	var weekly = "Running more than six days a week is not recommended.";
	TestSupport.expectEqual(daily, WarningMessages.messageFor(PreRunWarnings.ALREADY_LOGGED_TODAY, daily, weekly), "already ran");
	TestSupport.expectEqual(weekly, WarningMessages.messageFor(PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, daily, weekly), "seven days");
	TestSupport.expectNull(WarningMessages.messageFor(0, daily, weekly), "unknown code");
	TestSupport.expectNull(WarningMessages.messageFor(3, daily, weekly), "removed frequency code");

	TestSupport.expectEqual(1, WarningMessages.nextPosition(0, 2), "first of two leads to the second");
	TestSupport.expectNull(WarningMessages.nextPosition(1, 2), "second of two starts the workout");
	TestSupport.expectNull(WarningMessages.nextPosition(0, 1), "a single warning starts the workout");
	TestSupport.expectNull(WarningMessages.nextPosition(0, 0), "no warnings");
	return true;
}
