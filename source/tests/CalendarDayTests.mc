import Toybox.Lang;
import Toybox.Test;

(:test)
function testCalendarDay(logger as Test.Logger) as Boolean {
	logger.debug("calendar day");
	var monday = TestSupport.sampleMonday();
	var thursday = new CalendarDay(2026, 10, 8);
	TestSupport.expectEqual(3, monday.daysUntil(thursday), "Monday to Thursday");
	TestSupport.expectEqual(2, Recommender.daysOffBetween(monday, thursday), "two days off");
	TestSupport.expectEqual(0, monday.compare(thursday.plusDays(-3)), "plusDays back to Monday");
	TestSupport.expectEqual(0, Recommender.daysOffBetween(monday, monday), "same day");
	TestSupport.expectEqual(0, Recommender.daysOffBetween(monday, monday.plusDays(1)), "next day");
	TestSupport.expectEqual(2440588, CalendarDay.julianDay(1970, 1, 1), "unix epoch julian day");

	var leap = new CalendarDay(2024, 2, 28).plusDays(1);
	TestSupport.expectEqual(20240229, leap.toNumber(), "leap day");
	TestSupport.expectEqual(20260301, new CalendarDay(2026, 2, 28).plusDays(1).toNumber(), "non-leap March");
	TestSupport.expectEqual(20240229, new CalendarDay(2024, 3, 1).plusDays(-1).toNumber(), "back onto leap day");
	TestSupport.expectEqual(20251231, new CalendarDay(2026, 1, 1).plusDays(-1).toNumber(), "previous year");
	TestSupport.expectEqual(20260101, new CalendarDay(2025, 12, 31).plusDays(1).toNumber(), "next year");
	TestSupport.expectEqual(2, new CalendarDay(2026, 1, 31).daysUntil(new CalendarDay(2026, 2, 2)), "across a month");
	TestSupport.expectEqual(2, new CalendarDay(2025, 12, 31).daysUntil(new CalendarDay(2026, 1, 2)), "across a year");

	var start = new CalendarDay(2026, 6, 15);
	TestSupport.expectEqual(0, start.compare(start.plusDays(40).plusDays(-40)), "forward round trip");
	TestSupport.expectEqual(0, start.compare(start.plusDays(-40).plusDays(40)), "backward round trip");

	var restored = CalendarDay.fromNumber(20261005);
	TestSupport.expectTrue(restored != null, "round trip parse");
	TestSupport.expectEqual(0, monday.compare(restored as CalendarDay), "parsed Monday");
	TestSupport.expectNull(CalendarDay.fromNumber(20260231), "impossible day");
	TestSupport.expectNull(CalendarDay.fromNumber(20250229), "non-leap February 29");
	TestSupport.expectEqual(29, (CalendarDay.fromNumber(20240229) as CalendarDay).day, "leap February 29");
	TestSupport.expectNull(CalendarDay.fromNumber(20261301), "month 13");
	TestSupport.expectNull(CalendarDay.fromNumber(20260001), "month 0");
	return true;
}
