import Toybox.Lang;
import Toybox.Test;

(:test)
function testWarningMessages(logger as Test.Logger) as Boolean {
	logger.debug("warning messages");
	var daily = "It is recommended that you run no more than once per day.";
	var weekly = "It is recommended that you run no more than six times per week.";
	TestSupport.expectEqual(daily, WarningMessages.messageFor(PreRunWarnings.ALREADY_LOGGED_TODAY, daily, weekly), "already ran");
	TestSupport.expectEqual(weekly, WarningMessages.messageFor(PreRunWarnings.SEVEN_CONSECUTIVE_DAYS, daily, weekly), "seven days");
	TestSupport.expectNull(WarningMessages.messageFor(0, daily, weekly), "unknown code");
	TestSupport.expectNull(WarningMessages.messageFor(3, daily, weekly), "removed frequency code");
	return true;
}
