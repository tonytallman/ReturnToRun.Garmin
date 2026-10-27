import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

// The history is kept in memory as the same flat array that is stored:
// date number, workout id, rating for each entry, newest first. These tests
// pin that stored format, so history saved by earlier versions still loads.

// The exact array an earlier version saved.
(:test)
function testHistoryLoadsEarlierSavedFormat(logger as Test.Logger) as Boolean {
	logger.debug("history saved by an earlier version");
	var gateway = new MemoryStorageGateway();
	gateway.set(HISTORY_STORAGE_KEY, [
		20261026, 19, Rating.GOOD,
		20261024, 18, Rating.OK,
		20261024, 17, Rating.BAD
	] as Array<Storage.ValueType>);
	gateway.set(PROGRAM_COMPLETE_SHOWN_KEY, true);
	var store = new HistoryStore(gateway, 100, 40);
	store.load();
	TestSupport.expectEqual(3, store.size(), "every saved entry loads");
	TestSupport.expectTrue(store.isProgramCompleteShown(), "the flag loads");
	TestSupport.expectEntry(store.entryAt(0), 2026, 10, 26, 19, Rating.GOOD, "newest");
	TestSupport.expectEntry(store.entryAt(1), 2026, 10, 24, 18, Rating.OK, "same day, added later");
	TestSupport.expectEntry(store.entryAt(2), 2026, 10, 24, 17, Rating.BAD, "same day, added earlier");
	TestSupport.expectTrue(store.entryAt(3) == null, "nothing past the end");
	TestSupport.expectTrue(store.entryAt(-1) == null, "nothing before the start");

	// A later save writes the same format back.
	store.add(new CalendarDay(2026, 10, 27), 20, Rating.GREAT);
	TestSupport.expectStored(gateway, [
		20261027, 20, Rating.GREAT,
		20261026, 19, Rating.GOOD,
		20261024, 18, Rating.OK,
		20261024, 17, Rating.BAD
	] as Array<Number>, "add keeps the format");
	return true;
}

// The object store may hand back Long or Float values; they load as Numbers
// and are saved back as Numbers.
(:test)
function testHistoryLoadsOtherNumberTypes(logger as Test.Logger) as Boolean {
	logger.debug("history values stored as Long or Float");
	var gateway = new MemoryStorageGateway();
	gateway.set(HISTORY_STORAGE_KEY, [
		20261005l, 4l, 2l,
		20261003.0d, 2.0, 1.0
	] as Array<Storage.ValueType>);
	var store = new HistoryStore(gateway, 100, 40);
	store.load();
	TestSupport.expectEqual(2, store.size(), "both entries load");
	TestSupport.expectEntry(store.entryAt(0), 2026, 10, 5, 4, Rating.GOOD, "from Long");
	TestSupport.expectEntry(store.entryAt(1), 2026, 10, 3, 2, Rating.OK, "from Double and Float");
	store.setRating(1, Rating.GREAT);
	TestSupport.expectStored(gateway, [20261005, 4, Rating.GOOD, 20261003, 2, Rating.GREAT] as Array<Number>, "saved as Numbers");
	var stored = gateway.get(HISTORY_STORAGE_KEY) as Array;
	for (var i = 0; i < stored.size(); i++) {
		TestSupport.expectTrue(stored[i] instanceof Number, "value " + i + " is a Number");
	}
	return true;
}

// A full history: edits keep the flat layout in step, entry by entry.
(:test)
function testFullHistoryEditsKeepTheLayout(logger as Test.Logger) as Boolean {
	logger.debug("full history edits");
	var gateway = new MemoryStorageGateway();
	var start = new CalendarDay(2026, 10, 27);
	var flat = [] as Array<Storage.ValueType>;
	for (var i = 0; i < 100; i++) {
		flat.add(start.plusDays(-i).toNumber());
		flat.add((i % 40) + 1);
		flat.add(i % 4);
	}
	gateway.set(HISTORY_STORAGE_KEY, flat);
	var store = new HistoryStore(gateway, 100, 40);
	store.load();
	TestSupport.expectEqual(100, store.size(), "a full history loads");
	TestSupport.expectEntry(store.entryAt(99), 2026, 7, 20, 20, 3, "the oldest entry");

	store.deleteAt(50);
	TestSupport.expectEqual(99, store.size(), "one deleted");
	TestSupport.expectEntry(store.entryAt(49), 2026, 9, 8, 10, 1, "the entry before is unchanged");
	TestSupport.expectEntry(store.entryAt(50), 2026, 9, 6, 12, 3, "the next entry moved up");

	TestSupport.expectTrue(store.add(new CalendarDay(2026, 9, 7), 11, Rating.GOOD), "added into the gap");
	TestSupport.expectEqual(50, store.lastAddedIndex, "where it went");
	TestSupport.expectEntry(store.entryAt(50), 2026, 9, 7, 11, Rating.GOOD, "the added entry");
	TestSupport.expectEntry(store.entryAt(51), 2026, 9, 6, 12, 3, "the entry after it");

	TestSupport.expectTrue(store.add(new CalendarDay(2026, 10, 28), 21, Rating.OK), "a newer entry on a full history");
	TestSupport.expectEqual(100, store.size(), "still capped");
	TestSupport.expectEntry(store.entryAt(99), 2026, 7, 21, 19, 2, "the oldest dropped");

	store.deleteAtAndOlder(10);
	TestSupport.expectEqual(10, store.size(), "this and older removed");
	var reloaded = new HistoryStore(gateway, 100, 40);
	reloaded.load();
	TestSupport.expectEqual(10, reloaded.size(), "saved");
	TestSupport.expectEntry(reloaded.entryAt(9), 2026, 10, 19, 9, 0, "the last one kept");
	TestSupport.expectEqual(30, (gateway.get(HISTORY_STORAGE_KEY) as Array).size(), "three values per entry");
	return true;
}
