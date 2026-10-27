import Toybox.Lang;
import Toybox.Test;

// Excluded from the app unless the project is built with --unit-test.
// The functions here are helpers, not test cases.
(:test)
module TestSupport {
	class Fixture {
		var gateway as MemoryStorageGateway;
		var progress as Progress;

		function initialize(cap as Number) {
			gateway = new MemoryStorageGateway();
			var store = new HistoryStore(gateway, cap, 40);
			store.load();
			progress = new Progress(store);
		}
	}

	function openStore(cap as Number) as Fixture {
		return new Fixture(cap);
	}

	// Monday 5 October 2026. A run that day and Thursday 8 October is 2 days off.
	function sampleMonday() as CalendarDay {
		return new CalendarDay(2026, 10, 5);
	}

	function expectEqual(expected as Object, actual as Object?, message as String) as Void {
		Test.assertEqualMessage(expected, actual, message);
	}

	function expectTrue(value as Boolean, message as String) as Void {
		Test.assertMessage(value, message);
	}

	function expectFalse(value as Boolean, message as String) as Void {
		Test.assertMessage(!value, message);
	}

	function expectNull(actual as Object?, message as String) as Void {
		Test.assertMessage(actual == null, message);
	}

	function expectRecommendation(latest as HistoryEntry?, today as CalendarDay, workoutId as Number, complete as Boolean, message as String) as Void {
		var result = Recommender.recommend(latest, today, 40);
		Test.assertEqualMessage(workoutId, result.workoutId, message);
		Test.assertMessage(result.programComplete == complete, message + " complete");
	}

	function expectEntry(entry as HistoryEntry?, year as Number, month as Number, day as Number, workoutId as Number, rating as Number, message as String) as Void {
		Test.assertMessage(entry != null, message);
		var item = entry as HistoryEntry;
		Test.assertEqualMessage(year, item.date.year, message + " year");
		Test.assertEqualMessage(month, item.date.month, message + " month");
		Test.assertEqualMessage(day, item.date.day, message + " day");
		Test.assertEqualMessage(workoutId, item.workoutId, message + " workout");
		Test.assertEqualMessage(rating, item.rating, message + " rating");
	}

	// first and second are the warnings that should be present, in order. Pass null for a shorter list.
	function expectWarnings(actual as Array<Number>, first as Number?, second as Number?, message as String) as Void {
		var expectedCount = 0;
		if (first != null) {
			expectedCount = 1;
		}
		if (second != null) {
			expectedCount = 2;
		}
		Test.assertEqualMessage(expectedCount, actual.size(), message);
		if ((first != null) && (actual.size() > 0)) {
			Test.assertEqualMessage(first as Number, actual[0] as Number, message);
		}
		if ((second != null) && (actual.size() > 1)) {
			Test.assertEqualMessage(second as Number, actual[1] as Number, message);
		}
	}

	// The original switch: ids 1-13 run 60 x3..15, 14-21 run 120 x3..10,
	// 22-27 run 180 x3..8, 28-32 run 240 x2..6, 33-35 run 540 x1..3,
	// 36-37 run 840 x1..2, then 1200, 1500, and 1800 once each. Walk is always 60.
	function expectedRunSeconds(id as Number) as Number {
		if (id <= 13) {
			return 60;
		}
		if (id <= 21) {
			return 120;
		}
		if (id <= 27) {
			return 180;
		}
		if (id <= 32) {
			return 240;
		}
		if (id <= 35) {
			return 540;
		}
		if (id <= 37) {
			return 840;
		}
		if (id == 38) {
			return 1200;
		}
		if (id == 39) {
			return 1500;
		}
		return 1800;
	}

	function expectedRepeatCount(id as Number) as Number {
		if (id <= 13) {
			return id + 2;
		}
		if (id <= 21) {
			return id - 11;
		}
		if (id <= 27) {
			return id - 19;
		}
		if (id <= 32) {
			return id - 26;
		}
		if (id <= 35) {
			return id - 32;
		}
		if (id <= 37) {
			return id - 35;
		}
		return 1;
	}

	// A block of n placeholder lines, standing in for one wrapped sentence.
	function textBlock(n as Number) as Array<String> {
		var block = [] as Array<String>;
		for (var i = 0; i < n; i++) {
			block.add("x");
		}
		return block;
	}

	function textBlocks(sizes as Array<Number>) as Array<Array<String> > {
		var blocks = [] as Array<Array<String> >;
		for (var i = 0; i < sizes.size(); i++) {
			blocks.add(textBlock(sizes[i]));
		}
		return blocks;
	}

	function expectStarts(expected as Array<Number>, actual as Array<Number>, message as String) as Void {
		expectEqual(expected.size(), actual.size(), message + ": page count");
		for (var i = 0; i < expected.size() && i < actual.size(); i++) {
			expectEqual(expected[i], actual[i], message + ": page " + (i + 1));
		}
	}

	// The stored history array, value by value.
	function expectStored(gateway as MemoryStorageGateway, expected as Array<Number>, message as String) as Void {
		var stored = gateway.get(HISTORY_STORAGE_KEY);
		Test.assertMessage(stored instanceof Array, message + ": stored as an array");
		var values = stored as Array;
		Test.assertEqualMessage(expected.size(), values.size(), message + ": size");
		for (var i = 0; i < expected.size(); i++) {
			Test.assertEqualMessage(expected[i], values[i], message + ": value " + i);
		}
	}
}
