import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

(:test)
function testHistoryOperations(logger as Test.Logger) as Boolean {
	logger.debug("history operations");
	TestSupport.expectEqual(100, HISTORY_ENTRY_CAP, "history cap");
	var progress = TestSupport.openStore(100).progress;
	var oct1 = new CalendarDay(2026, 10, 1);
	var oct3 = new CalendarDay(2026, 10, 3);
	var oct5 = new CalendarDay(2026, 10, 5);
	TestSupport.expectTrue(progress.addEntry(oct3, 2, Rating.OK), "add oct 3");
	TestSupport.expectTrue(progress.addEntry(oct1, 1, Rating.BAD), "add oct 1");
	TestSupport.expectTrue(progress.addEntry(oct5, 3, Rating.GOOD), "add oct 5");
	TestSupport.expectTrue(progress.addEntry(oct3, 4, Rating.GREAT), "second oct 3");
	TestSupport.expectEqual(4, progress.size(), "same-day entries are kept");
	TestSupport.expectEntry(progress.entryAt(0), 2026, 10, 5, 3, Rating.GOOD, "newest");
	TestSupport.expectEntry(progress.entryAt(1), 2026, 10, 3, 4, Rating.GREAT, "newer same-day entry");
	TestSupport.expectEntry(progress.entryAt(2), 2026, 10, 3, 2, Rating.OK, "earlier same-day entry");
	TestSupport.expectEntry(progress.entryAt(3), 2026, 10, 1, 1, Rating.BAD, "oldest");

	TestSupport.expectFalse(progress.addEntry(oct5, 0, Rating.OK), "id 0");
	TestSupport.expectFalse(progress.addEntry(oct5, 41, Rating.OK), "id 41");
	TestSupport.expectFalse(progress.addEntry(oct5, 3, 4), "rating 4");
	TestSupport.expectEqual(4, progress.size(), "rejected adds do not change the store");

	TestSupport.expectFalse(progress.setRating(-1, Rating.OK), "negative index");
	TestSupport.expectFalse(progress.setRating(4, Rating.OK), "index past the end");
	TestSupport.expectFalse(progress.setRating(0, 9), "invalid rating");
	TestSupport.expectEqual(Rating.GOOD, (progress.entryAt(0) as HistoryEntry).rating, "rating unchanged");
	TestSupport.expectTrue(progress.setRating(1, Rating.BAD), "change rating");
	TestSupport.expectEqual(Rating.BAD, (progress.entryAt(1) as HistoryEntry).rating, "rating changed");

	TestSupport.expectTrue(progress.deleteAt(1), "delete one");
	TestSupport.expectEqual(3, progress.size(), "after delete");
	TestSupport.expectEqual(2, (progress.entryAt(1) as HistoryEntry).workoutId, "following same-day entry remains");
	TestSupport.expectFalse(progress.deleteAt(3), "delete missing");

	var trimmed = TestSupport.openStore(100).progress;
	trimmed.addEntry(oct1, 1, Rating.OK);
	trimmed.addEntry(new CalendarDay(2026, 10, 2), 2, Rating.OK);
	trimmed.addEntry(oct3, 3, Rating.OK);
	trimmed.addEntry(new CalendarDay(2026, 10, 4), 4, Rating.OK);
	TestSupport.expectTrue(trimmed.deleteAtAndOlder(2), "delete this and older");
	TestSupport.expectEqual(2, trimmed.size(), "two newer entries remain");
	TestSupport.expectEqual(4, (trimmed.entryAt(0) as HistoryEntry).workoutId, "newest kept");
	TestSupport.expectEqual(3, (trimmed.entryAt(1) as HistoryEntry).workoutId, "next kept");
	TestSupport.expectTrue(trimmed.deleteAtAndOlder(0), "delete from the newest");
	TestSupport.expectEqual(0, trimmed.size(), "all gone");
	TestSupport.expectFalse(trimmed.deleteAtAndOlder(0), "empty delete");
	return true;
}

(:test)
function testHistoryCap(logger as Test.Logger) as Boolean {
	logger.debug("history cap");
	var progress = TestSupport.openStore(3).progress;
	TestSupport.expectTrue(progress.addEntry(new CalendarDay(2026, 10, 1), 1, Rating.OK), "day 1");
	TestSupport.expectTrue(progress.addEntry(new CalendarDay(2026, 10, 2), 2, Rating.OK), "day 2");
	TestSupport.expectTrue(progress.addEntry(new CalendarDay(2026, 10, 3), 3, Rating.OK), "day 3");
	TestSupport.expectFalse(progress.addEntry(new CalendarDay(2026, 9, 30), 9, Rating.OK), "older than a full store");
	TestSupport.expectEqual(3, progress.size(), "rejected older entry");
	TestSupport.expectEqual(3, (progress.latest() as HistoryEntry).workoutId, "latest unchanged");
	TestSupport.expectEqual(1, (progress.entryAt(2) as HistoryEntry).workoutId, "oldest unchanged");

	TestSupport.expectTrue(progress.addEntry(new CalendarDay(2026, 10, 4), 4, Rating.GOOD), "newer than a full store");
	TestSupport.expectEqual(3, progress.size(), "cap held");
	TestSupport.expectEqual(4, (progress.entryAt(0) as HistoryEntry).workoutId, "newest inserted");
	TestSupport.expectEqual(3, (progress.entryAt(1) as HistoryEntry).workoutId, "previous newest");
	TestSupport.expectEqual(2, (progress.entryAt(2) as HistoryEntry).workoutId, "oldest dropped");

	var sameDay = TestSupport.openStore(3).progress;
	var day = new CalendarDay(2026, 10, 5);
	sameDay.addEntry(day, 1, Rating.OK);
	sameDay.addEntry(day, 2, Rating.OK);
	sameDay.addEntry(day, 3, Rating.OK);
	TestSupport.expectTrue(sameDay.addEntry(day, 4, Rating.GREAT), "fourth same-day entry");
	TestSupport.expectEqual(3, sameDay.size(), "same-day cap");
	TestSupport.expectEqual(4, (sameDay.entryAt(0) as HistoryEntry).workoutId, "newest same-day kept");
	TestSupport.expectEqual(3, (sameDay.entryAt(1) as HistoryEntry).workoutId, "middle same-day kept");
	TestSupport.expectEqual(2, (sameDay.entryAt(2) as HistoryEntry).workoutId, "oldest same-day dropped");
	return true;
}

(:test)
function testHistoryPersistence(logger as Test.Logger) as Boolean {
	logger.debug("history persistence");
	var world = TestSupport.openStore(100);
	var today = new CalendarDay(2026, 10, 8);
	world.progress.addEntry(today.plusDays(-1), 6, Rating.OK);
	world.progress.addEntry(today, 7, Rating.GOOD);
	world.progress.markProgramCompleteShown();

	var reloaded = new HistoryStore(world.gateway, 100, 40);
	reloaded.load();
	TestSupport.expectEqual(2, reloaded.size(), "round trip size");
	TestSupport.expectTrue(reloaded.isProgramCompleteShown(), "flag round trip");
	TestSupport.expectEntry(reloaded.entryAt(0), 2026, 10, 8, 7, Rating.GOOD, "newest stored");
	TestSupport.expectEntry(reloaded.entryAt(1), 2026, 10, 7, 6, Rating.OK, "older stored");

	world.progress.clear();
	var cleared = new HistoryStore(world.gateway, 100, 40);
	cleared.load();
	TestSupport.expectEqual(0, cleared.size(), "clear removes entries");
	TestSupport.expectTrue(cleared.isProgramCompleteShown(), "clear keeps the flag");

	var corrupt = new MemoryStorageGateway();
	corrupt.set(HISTORY_STORAGE_KEY, [
		20261005, 4, Rating.GOOD,
		"bad", 1, 1,
		20260231, 2, Rating.OK,
		20261001, 0, Rating.OK,
		20261002, 3, 9,
		null, 2, Rating.OK,
		20261003, 2, Rating.OK,
		99
	]);
	var cleaned = new HistoryStore(corrupt, 100, 40);
	cleaned.load();
	TestSupport.expectEqual(2, cleaned.size(), "bad triples skipped");
	TestSupport.expectEntry(cleaned.entryAt(0), 2026, 10, 5, 4, Rating.GOOD, "first valid");
	TestSupport.expectEntry(cleaned.entryAt(1), 2026, 10, 3, 2, Rating.OK, "second valid");

	var overflow = new MemoryStorageGateway();
	var stored = [] as Array<Storage.ValueType>;
	for (var id = 5; id >= 1; id -= 1) {
		var dateValue as Storage.ValueType = 20261000 + id;
		var workoutValue as Storage.ValueType = id;
		var ratingValue as Storage.ValueType = Rating.OK;
		stored.add(dateValue);
		stored.add(workoutValue);
		stored.add(ratingValue);
	}
	overflow.set(HISTORY_STORAGE_KEY, stored);
	var capped = new HistoryStore(overflow, 2, 40);
	capped.load();
	TestSupport.expectEqual(2, capped.size(), "load trims in memory");
	TestSupport.expectEqual(5, (capped.entryAt(0) as HistoryEntry).workoutId, "trim keeps the newest");
	var untouched = new HistoryStore(overflow, 100, 40);
	untouched.load();
	TestSupport.expectEqual(5, untouched.size(), "trim is not written until save");
	capped.setRating(0, Rating.GOOD);
	var persisted = new HistoryStore(overflow, 100, 40);
	persisted.load();
	TestSupport.expectEqual(2, persisted.size(), "the next save writes the trimmed list");
	TestSupport.expectEqual(Rating.GOOD, (persisted.entryAt(0) as HistoryEntry).rating, "saved rating");
	return true;
}

(:test)
function testProgramCompleteFlag(logger as Test.Logger) as Boolean {
	logger.debug("program complete flag");
	var today = new CalendarDay(2026, 10, 8);
	var progress = TestSupport.openStore(100).progress;
	TestSupport.expectFalse(progress.shouldShowProgramComplete(today), "empty");
	progress.addEntry(today, 40, Rating.GOOD);
	TestSupport.expectTrue(progress.recommend(today).programComplete, "good on 40 completes");
	TestSupport.expectEqual(40, progress.recommend(today).workoutId, "recommendation stays on 40");
	TestSupport.expectTrue(progress.shouldShowProgramComplete(today), "show the screen");
	progress.markProgramCompleteShown();
	TestSupport.expectFalse(progress.shouldShowProgramComplete(today), "shown once");
	TestSupport.expectTrue(progress.recommend(today).programComplete, "the signal stays true");

	progress.addEntry(today, 1, Rating.OK);
	TestSupport.expectFalse(progress.isProgramCompleteShown(), "logging workout 1 resets the flag");
	TestSupport.expectEqual(1, progress.recommend(today).workoutId, "workout 1 is now latest");
	TestSupport.expectFalse(progress.shouldShowProgramComplete(today), "workout 1 is not complete");
	progress.addEntry(today, 40, Rating.GREAT);
	TestSupport.expectTrue(progress.shouldShowProgramComplete(today), "a new program can complete again");

	var changed = TestSupport.openStore(100).progress;
	changed.addEntry(today, 39, Rating.GOOD);
	TestSupport.expectFalse(changed.shouldShowProgramComplete(today), "good on 39 is workout 40");
	changed.setRating(0, Rating.GREAT);
	TestSupport.expectTrue(changed.recommend(today).programComplete, "great on the latest entry completes");
	TestSupport.expectTrue(changed.shouldShowProgramComplete(today), "a rating change can show the screen");

	var older = TestSupport.openStore(100).progress;
	older.addEntry(today.plusDays(-1), 39, Rating.GOOD);
	older.addEntry(today, 20, Rating.OK);
	older.setRating(1, Rating.GREAT);
	TestSupport.expectFalse(older.recommend(today).programComplete, "an older rating does not complete the program");
	TestSupport.expectEqual(20, older.recommend(today).workoutId, "latest entry still decides");

	var edited = TestSupport.openStore(100).progress;
	edited.addEntry(today, 40, Rating.GOOD);
	edited.markProgramCompleteShown();
	edited.setRating(0, Rating.OK);
	TestSupport.expectFalse(edited.recommend(today).programComplete, "editing off a completing rating");
	TestSupport.expectTrue(edited.isProgramCompleteShown(), "the shown flag stays set");
	edited.setRating(0, Rating.GOOD);
	TestSupport.expectFalse(edited.shouldShowProgramComplete(today), "editing back does not show it again");

	var backdated = TestSupport.openStore(100).progress;
	backdated.addEntry(today, 40, Rating.GOOD);
	backdated.markProgramCompleteShown();
	TestSupport.expectTrue(backdated.addEntry(today.plusDays(-10), 1, Rating.BAD), "backdated workout 1");
	TestSupport.expectFalse(backdated.isProgramCompleteShown(), "workout 1 resets the flag even when it is not latest");
	TestSupport.expectEqual(40, (backdated.latest() as HistoryEntry).workoutId, "today's workout is still latest");
	TestSupport.expectTrue(backdated.shouldShowProgramComplete(today), "the screen can show again");

	var full = TestSupport.openStore(1).progress;
	full.addEntry(today, 40, Rating.GOOD);
	full.markProgramCompleteShown();
	TestSupport.expectFalse(full.addEntry(today.plusDays(-1), 1, Rating.OK), "workout 1 does not fit");
	TestSupport.expectTrue(full.isProgramCompleteShown(), "a rejected add does not reset the flag");
	TestSupport.expectEqual(40, (full.latest() as HistoryEntry).workoutId, "store unchanged");
	return true;
}
