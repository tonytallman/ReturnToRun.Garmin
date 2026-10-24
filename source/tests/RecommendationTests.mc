import Toybox.Lang;
import Toybox.Test;

(:test)
function testRecommendationRatings(logger as Test.Logger) as Boolean {
	logger.debug("recommendation ratings");
	var today = TestSupport.sampleMonday();
	TestSupport.expectEqual(0, Rating.BAD, "bad");
	TestSupport.expectEqual(1, Rating.OK, "ok");
	TestSupport.expectEqual(2, Rating.GOOD, "good");
	TestSupport.expectEqual(3, Rating.GREAT, "great");
	TestSupport.expectEqual(-1, Rating.step(Rating.BAD), "bad step");
	TestSupport.expectEqual(0, Rating.step(Rating.OK), "ok step");
	TestSupport.expectEqual(1, Rating.step(Rating.GOOD), "good step");
	TestSupport.expectEqual(2, Rating.step(Rating.GREAT), "great step");
	TestSupport.expectFalse(Rating.isValid(4), "rating 4");
	TestSupport.expectFalse(Rating.isValid(-1), "rating -1");

	TestSupport.expectRecommendation(null, today, 1, false, "empty history");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.BAD), today, 9, false, "bad");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.OK), today, 10, false, "ok");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.GOOD), today, 11, false, "good");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.GREAT), today, 12, false, "great");
	TestSupport.expectRecommendation(new HistoryEntry(today.plusDays(1), 10, Rating.OK), today, 10, false, "future run has no days off");
	return true;
}

(:test)
function testRecommendationDaysOff(logger as Test.Logger) as Boolean {
	logger.debug("recommendation days off");
	var monday = TestSupport.sampleMonday();
	var logged = new HistoryEntry(monday, 10, Rating.OK);
	TestSupport.expectRecommendation(logged, monday, 10, false, "0 days off");
	TestSupport.expectRecommendation(logged, monday.plusDays(1), 10, false, "next day is 0 days off");
	TestSupport.expectRecommendation(logged, monday.plusDays(3), 10, false, "2 days off");
	TestSupport.expectEqual(2, Recommender.daysOffBetween(monday, new CalendarDay(2026, 10, 8)), "Monday to Thursday");
	TestSupport.expectRecommendation(logged, monday.plusDays(4), 9, false, "3 days off");
	TestSupport.expectRecommendation(logged, monday.plusDays(5), 8, false, "4 days off");
	TestSupport.expectRecommendation(logged, monday.plusDays(6), 7, false, "5 days off");
	TestSupport.expectRecommendation(logged, monday.plusDays(7), 1, false, "6 days off restarts");
	TestSupport.expectRecommendation(logged, monday.plusDays(8), 1, false, "7 days off restarts");
	TestSupport.expectRecommendation(logged, monday.plusDays(31), 1, false, "30 days off restarts");
	TestSupport.expectRecommendation(new HistoryEntry(monday, 40, Rating.GREAT), monday.plusDays(7), 1, false, "restart beats a completing rating");
	return true;
}

(:test)
function testRecommendationClamping(logger as Test.Logger) as Boolean {
	logger.debug("recommendation clamping");
	var today = TestSupport.sampleMonday();
	TestSupport.expectRecommendation(new HistoryEntry(today, 1, Rating.BAD), today, 1, false, "bad on 1");
	TestSupport.expectRecommendation(new HistoryEntry(today, 2, Rating.BAD), today.plusDays(6), 1, false, "bad plus five days off");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.BAD), today, 39, false, "bad on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.OK), today, 40, false, "ok on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.GOOD), today, 40, true, "good on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.GREAT), today, 40, true, "great on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 39, Rating.GOOD), today, 40, false, "good on 39");
	TestSupport.expectRecommendation(new HistoryEntry(today, 39, Rating.GREAT), today, 40, true, "great on 39");
	TestSupport.expectRecommendation(new HistoryEntry(today, 38, Rating.GREAT), today, 40, false, "great on 38");

	var finished = new HistoryEntry(today, 40, Rating.GREAT);
	TestSupport.expectRecommendation(finished, today.plusDays(4), 40, true, "3 days off still clears 40");
	TestSupport.expectRecommendation(finished, today.plusDays(5), 40, false, "4 days off lands on 40");
	TestSupport.expectRecommendation(finished, today.plusDays(6), 39, false, "5 days off steps back from 40");
	return true;
}

(:test)
function testRecommendationUsesLatestEntry(logger as Test.Logger) as Boolean {
	logger.debug("recommendation uses the latest entry");
	var monday = TestSupport.sampleMonday();
	var progress = TestSupport.openStore(100).progress;
	progress.addEntry(monday, 10, Rating.OK);
	progress.addEntry(monday, 12, Rating.BAD);
	TestSupport.expectEqual(12, (progress.latest() as HistoryEntry).workoutId, "same-day add is newest");
	TestSupport.expectRecommendation(progress.latest(), monday, 11, false, "latest same-day rating");

	progress.addEntry(monday.plusDays(-3), 30, Rating.GREAT);
	TestSupport.expectEqual(12, (progress.latest() as HistoryEntry).workoutId, "older date stays behind");
	TestSupport.expectRecommendation(progress.latest(), monday, 11, false, "older entry is not the recommendation");
	return true;
}
