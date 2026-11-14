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

	TestSupport.expectRecommendation(null, 1, false, "empty history");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.BAD), 9, false, "bad");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.OK), 10, false, "ok");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.GOOD), 11, false, "good");
	TestSupport.expectRecommendation(new HistoryEntry(today, 10, Rating.GREAT), 12, false, "great");
	TestSupport.expectRecommendation(new HistoryEntry(today.plusDays(1), 10, Rating.OK), 10, false, "an entry dated after today still uses only its rating");
	return true;
}

(:test)
function testRecommendationIgnoresGaps(logger as Test.Logger) as Boolean {
	logger.debug("recommendation ignores time since the last run");
	var monday = TestSupport.sampleMonday();
	TestSupport.expectRecommendation(new HistoryEntry(monday, 10, Rating.GOOD), 11, false, "a recent Good advances");
	TestSupport.expectRecommendation(new HistoryEntry(monday.plusDays(-3), 10, Rating.GOOD), 11, false, "a few days later still advances");
	TestSupport.expectRecommendation(new HistoryEntry(monday.plusDays(-7), 10, Rating.OK), 10, false, "a week later still repeats");
	TestSupport.expectRecommendation(new HistoryEntry(monday.plusDays(-31), 10, Rating.OK), 10, false, "a month later still repeats");
	TestSupport.expectRecommendation(new HistoryEntry(monday.plusDays(-10), 40, Rating.GREAT), 40, true, "a Great on 40 still completes after a gap");
	TestSupport.expectRecommendation(new HistoryEntry(monday.plusDays(-6), 2, Rating.BAD), 1, false, "Bad still steps back after a gap, and stays at 1");
	return true;
}

(:test)
function testRecommendationClamping(logger as Test.Logger) as Boolean {
	logger.debug("recommendation clamping");
	var today = TestSupport.sampleMonday();
	TestSupport.expectRecommendation(new HistoryEntry(today, 1, Rating.BAD), 1, false, "bad on 1");
	TestSupport.expectRecommendation(new HistoryEntry(today, 2, Rating.BAD), 1, false, "bad on 2");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.BAD), 39, false, "bad on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.OK), 40, false, "ok on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.GOOD), 40, true, "good on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 40, Rating.GREAT), 40, true, "great on 40");
	TestSupport.expectRecommendation(new HistoryEntry(today, 39, Rating.GOOD), 40, false, "good on 39");
	TestSupport.expectRecommendation(new HistoryEntry(today, 39, Rating.GREAT), 40, true, "great on 39");
	TestSupport.expectRecommendation(new HistoryEntry(today, 38, Rating.GREAT), 40, false, "great on 38");

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
	TestSupport.expectRecommendation(progress.latest(), 11, false, "latest same-day rating");

	progress.addEntry(monday.plusDays(-3), 30, Rating.GREAT);
	TestSupport.expectEqual(12, (progress.latest() as HistoryEntry).workoutId, "older date stays behind");
	TestSupport.expectRecommendation(progress.latest(), 11, false, "older entry is not the recommendation");
	return true;
}
