import Toybox.Lang;
import Toybox.Test;

(:test)
function testLogWorkout(logger as Test.Logger) as Boolean {
	logger.debug("log workout");
	var today = new CalendarDay(2026, 10, 8);
	var progress = TestSupport.openStore(100).progress;
	TestSupport.expectFalse(progress.logWorkout(today, 10, Rating.GOOD), "workout 10 does not complete");
	TestSupport.expectEntry(progress.latest(), 2026, 10, 8, 10, Rating.GOOD, "logged with today's date");
	TestSupport.expectFalse(progress.logWorkout(today, 40, Rating.OK), "OK on 40 repeats 40");
	TestSupport.expectFalse(progress.logWorkout(today, 40, Rating.BAD), "Bad on 40 steps back");
	TestSupport.expectTrue(progress.logWorkout(today, 40, Rating.GOOD), "Good on 40 completes");
	TestSupport.expectEqual(40, progress.recommend(today).workoutId, "the recommendation stays at 40");
	progress.markProgramCompleteShown();
	TestSupport.expectFalse(progress.logWorkout(today, 40, Rating.GREAT), "shown once per program");
	TestSupport.expectFalse(progress.logWorkout(today, 1, Rating.GOOD), "workout 1 starts a new program");
	TestSupport.expectFalse(progress.isProgramCompleteShown(), "and clears the flag");
	TestSupport.expectTrue(progress.logWorkout(today, 39, Rating.GREAT), "Great on 39 completes the new program");
	TestSupport.expectEqual(40, progress.recommend(today).workoutId, "still capped at 40");
	return true;
}

(:test)
function testLogWorkoutFullHistory(logger as Test.Logger) as Boolean {
	logger.debug("log workout with a full history");
	var today = new CalendarDay(2026, 10, 8);
	var progress = TestSupport.openStore(3).progress;
	progress.logWorkout(today.plusDays(-3), 37, Rating.GOOD);
	progress.logWorkout(today.plusDays(-2), 38, Rating.GOOD);
	progress.logWorkout(today.plusDays(-1), 39, Rating.GOOD);
	TestSupport.expectTrue(progress.logWorkout(today, 40, Rating.GOOD), "a full history still logs and completes");
	TestSupport.expectEqual(3, progress.size(), "the oldest entry is dropped");
	TestSupport.expectEntry(progress.latest(), 2026, 10, 8, 40, Rating.GOOD, "newest first");
	TestSupport.expectEntry(progress.entryAt(2), 2026, 10, 6, 38, Rating.GOOD, "37 is gone");

	// Future-dated entries fill the store ahead of today, so today's entry
	// would land past the cap and is rejected. Nothing is shown.
	var future = TestSupport.openStore(2).progress;
	future.addEntry(today.plusDays(2), 39, Rating.GOOD);
	future.addEntry(today.plusDays(1), 39, Rating.GOOD);
	TestSupport.expectFalse(future.logWorkout(today, 40, Rating.GREAT), "a rejected entry does not show completion");
	TestSupport.expectEqual(2, future.size(), "nothing added");
	return true;
}
