import Toybox.Lang;
import Toybox.Test;

(:test)
function testHistoryFormat(logger as Test.Logger) as Boolean {
	logger.debug("history list text and layout");
	TestSupport.expectEqual("Oct 24  #5  Good", HistoryFormat.entryLabel("Oct", 24, 5, "Good"), "list label");
	TestSupport.expectEqual("Jan 3  #40  Great", HistoryFormat.entryLabel("Jan", 3, 40, "Great"), "single-digit day, two-digit workout");
	TestSupport.expectEqual("Oct 24", HistoryFormat.shortDate("Oct", 24), "short date");
	TestSupport.expectEqual(3, HistoryFormat.clearPosition(3), "Clear history is second to last");
	TestSupport.expectEqual(4, HistoryFormat.addPosition(3), "Add workout is last");
	TestSupport.expectEqual(5, HistoryFormat.itemCount(3), "entries plus two");
	TestSupport.expectEqual(0, HistoryFormat.clearPosition(0), "empty history still has Clear");
	TestSupport.expectEqual(1, HistoryFormat.addPosition(0), "and Add");
	TestSupport.expectEqual(0, HistoryFormat.clampFocus(-1, 3), "focus below the list");
	TestSupport.expectEqual(4, HistoryFormat.clampFocus(9, 3), "focus past the list lands on Add");
	TestSupport.expectEqual(2, HistoryFormat.focusAfterDelete(2, 5), "the next older entry takes its place");
	TestSupport.expectEqual(1, HistoryFormat.focusAfterDelete(2, 2), "deleting the oldest focuses the new oldest");
	TestSupport.expectEqual(1, HistoryFormat.focusAfterDelete(0, 0), "empty history focuses Add");
	return true;
}

(:test)
function testDateStepper(logger as Test.Logger) as Boolean {
	logger.debug("add workout date stepper");
	var stepper = new DateStepper(new CalendarDay(2026, 3, 1));
	TestSupport.expectTrue(stepper.isToday(), "starts at today");
	TestSupport.expectEqual(20260301, stepper.date().toNumber(), "today's date");
	TestSupport.expectFalse(stepper.later(), "never past today");
	TestSupport.expectEqual(20260301, stepper.date().toNumber(), "still today");
	stepper.earlier();
	TestSupport.expectTrue(stepper.isYesterday(), "one day back");
	TestSupport.expectEqual(20260228, stepper.date().toNumber(), "across a month end");
	stepper.earlier();
	stepper.earlier();
	TestSupport.expectEqual(20260226, stepper.date().toNumber(), "a day at a time");
	TestSupport.expectTrue(stepper.later(), "forward again");
	TestSupport.expectEqual(20260227, stepper.date().toNumber(), "one day forward");
	return true;
}

(:test)
function testHistoryEditsOrderAndDelete(logger as Test.Logger) as Boolean {
	logger.debug("history edits: order and delete");
	var today = new CalendarDay(2026, 10, 24);
	var progress = TestSupport.openStore(100).progress;
	progress.addWorkout(today.plusDays(-2), 3, Rating.GOOD, today);
	progress.addWorkout(today, 5, Rating.GOOD, today);
	TestSupport.expectEqual(0, progress.lastAddedIndex(), "today's entry is newest");
	progress.addWorkout(today.plusDays(-1), 4, Rating.OK, today);
	TestSupport.expectEqual(1, progress.lastAddedIndex(), "a backdated entry sorts between");
	progress.addWorkout(today.plusDays(-5), 1, Rating.GOOD, today);
	TestSupport.expectEntry(progress.entryAt(0), 2026, 10, 24, 5, Rating.GOOD, "newest first");
	TestSupport.expectEntry(progress.entryAt(1), 2026, 10, 23, 4, Rating.OK, "then yesterday");
	TestSupport.expectEntry(progress.entryAt(2), 2026, 10, 22, 3, Rating.GOOD, "then two days ago");
	TestSupport.expectEntry(progress.entryAt(3), 2026, 10, 19, 1, Rating.GOOD, "oldest last");
	TestSupport.expectEqual(6, progress.recommend(today).workoutId, "Good on 5 recommends 6");
	TestSupport.expectEqual(1, progress.warnings(today).size(), "already ran today");

	// Deleting the newest entry re-derives the recommendation and warnings.
	TestSupport.expectTrue(progress.deleteAt(0), "delete the newest");
	TestSupport.expectEqual(4, progress.recommend(today).workoutId, "OK on 4 yesterday repeats 4");
	TestSupport.expectEqual(0, progress.warnings(today).size(), "no run today any more");

	// Delete this and older keeps only the newer entries.
	TestSupport.expectTrue(progress.deleteAtAndOlder(1), "delete the second and older");
	TestSupport.expectEqual(1, progress.size(), "one entry left");
	TestSupport.expectEntry(progress.entryAt(0), 2026, 10, 23, 4, Rating.OK, "the newest stays");
	TestSupport.expectFalse(progress.deleteAtAndOlder(5), "out of range does nothing");
	TestSupport.expectTrue(progress.deleteAtAndOlder(0), "delete the newest and older");
	TestSupport.expectEqual(0, progress.size(), "empty");
	TestSupport.expectEqual(1, progress.recommend(today).workoutId, "empty history recommends 1");
	return true;
}

(:test)
function testHistoryAddWithCap(logger as Test.Logger) as Boolean {
	logger.debug("history add with the cap");
	var today = new CalendarDay(2026, 10, 24);
	var progress = TestSupport.openStore(3).progress;
	TestSupport.expectFalse(progress.isTooOldToAdd(today.plusDays(-100)), "an empty history takes any date");
	progress.addWorkout(today.plusDays(-3), 2, Rating.GOOD, today);
	progress.addWorkout(today.plusDays(-2), 3, Rating.GOOD, today);
	progress.addWorkout(today.plusDays(-1), 4, Rating.GOOD, today);
	progress.addWorkout(today, 5, Rating.GOOD, today);
	TestSupport.expectEqual(3, progress.size(), "stays at the cap");
	TestSupport.expectEntry(progress.entryAt(2), 2026, 10, 22, 3, Rating.GOOD, "the oldest dropped");
	TestSupport.expectTrue(progress.isTooOldToAdd(today.plusDays(-10)), "older than a full history is too old");
	TestSupport.expectTrue(progress.isTooOldToAdd(today.plusDays(-3)), "the day before the oldest is too old");
	TestSupport.expectFalse(progress.isTooOldToAdd(today.plusDays(-2)), "the oldest entry's day is not too old");
	TestSupport.expectFalse(progress.isTooOldToAdd(today), "today is not too old");
	TestSupport.expectFalse(progress.addWorkout(today.plusDays(-10), 1, Rating.GOOD, today), "older than a full history");
	TestSupport.expectEqual(-1, progress.lastAddedIndex(), "nothing added");
	TestSupport.expectEqual(3, progress.size(), "still full");
	TestSupport.expectEntry(progress.entryAt(2), 2026, 10, 22, 3, Rating.GOOD, "unchanged");
	return true;
}

(:test)
function testHistoryRatingChangeCompletesProgram(logger as Test.Logger) as Boolean {
	logger.debug("history rating change and program complete");
	var today = new CalendarDay(2026, 10, 24);
	var progress = TestSupport.openStore(100).progress;
	progress.logWorkout(today.plusDays(-1), 39, Rating.GOOD);
	progress.logWorkout(today, 40, Rating.OK);
	TestSupport.expectFalse(progress.changeRating(1, Rating.GREAT, today), "an older entry never completes");
	TestSupport.expectFalse(progress.changeRating(0, Rating.BAD, today), "Bad on 40 does not complete");
	TestSupport.expectTrue(progress.changeRating(0, Rating.GOOD, today), "Good on the newest 40 completes");
	TestSupport.expectEqual(Rating.GOOD, (progress.latest() as HistoryEntry).rating, "the rating changed");
	TestSupport.expectFalse(progress.isProgramCompleteShown(), "detecting completion does not set the flag");
	progress.markProgramCompleteShown();
	TestSupport.expectFalse(progress.changeRating(0, Rating.GREAT, today), "shown once per program");
	TestSupport.expectFalse(progress.changeRating(0, 9, today), "an invalid rating changes nothing");
	TestSupport.expectFalse(progress.changeRating(5, Rating.GOOD, today), "no such entry");

	// Adding: only an entry that becomes the newest can complete the program.
	var added = TestSupport.openStore(100).progress;
	added.logWorkout(today, 10, Rating.GOOD);
	TestSupport.expectFalse(added.addWorkout(today.plusDays(-1), 40, Rating.GREAT, today), "a backdated 40 behind a newer entry");
	TestSupport.expectTrue(added.addWorkout(today, 40, Rating.GOOD, today), "a newest 40 rated Good completes");
	added.markProgramCompleteShown();
	TestSupport.expectFalse(added.addWorkout(today, 40, Rating.GREAT, today), "still once per program");
	TestSupport.expectFalse(added.addWorkout(today.plusDays(-3), 1, Rating.GOOD, today), "a backdated workout 1");
	TestSupport.expectFalse(added.isProgramCompleteShown(), "still resets the flag, as before");
	return true;
}
