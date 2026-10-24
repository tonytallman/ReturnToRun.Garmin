import Toybox.Lang;
import Toybox.Test;

(:test)
function testLegacyMigration(logger as Test.Logger) as Boolean {
	logger.debug("legacy migration");
	var today = new CalendarDay(2026, 10, 8);
	var migration = new LegacyMigration(40);

	var absent = TestSupport.openStore(100);
	TestSupport.expectFalse(migration.apply(absent.gateway, absent.progress, today), "no key");
	TestSupport.expectEqual(0, absent.progress.size(), "no key adds nothing");

	var zero = TestSupport.openStore(100);
	zero.gateway.set(LEGACY_WORKOUT_INDEX_KEY, 0);
	TestSupport.expectFalse(migration.apply(zero.gateway, zero.progress, today), "index 0");
	TestSupport.expectEqual(0, zero.progress.size(), "index 0 adds nothing");
	TestSupport.expectTrue(zero.gateway.get(LEGACY_WORKOUT_INDEX_KEY) == null, "index 0 removes the key");
	TestSupport.expectRecommendation(zero.progress.latest(), today, 1, false, "index 0 recommends 1");

	var five = TestSupport.openStore(100);
	five.gateway.set(LEGACY_WORKOUT_INDEX_KEY, 5);
	TestSupport.expectTrue(migration.apply(five.gateway, five.progress, today), "index 5");
	TestSupport.expectEntry(five.progress.latest(), 2026, 10, 7, 5, Rating.GOOD, "index 5 becomes yesterday");
	TestSupport.expectTrue(five.gateway.get(LEGACY_WORKOUT_INDEX_KEY) == null, "index 5 removes the key");
	TestSupport.expectRecommendation(five.progress.latest(), today, 6, false, "index 5 recommends 6");
	TestSupport.expectFalse(migration.apply(five.gateway, five.progress, today), "second apply");
	TestSupport.expectEqual(1, five.progress.size(), "second apply adds nothing");

	var floated = TestSupport.openStore(100);
	floated.gateway.set(LEGACY_WORKOUT_INDEX_KEY, 5.0);
	TestSupport.expectTrue(migration.apply(floated.gateway, floated.progress, today), "float index");
	TestSupport.expectEqual(5, (floated.progress.latest() as HistoryEntry).workoutId, "float index value");

	var last = TestSupport.openStore(100);
	last.gateway.set(LEGACY_WORKOUT_INDEX_KEY, 39);
	migration.apply(last.gateway, last.progress, today);
	TestSupport.expectRecommendation(last.progress.latest(), today, 40, false, "index 39 recommends 40");

	var clamped = TestSupport.openStore(100);
	clamped.gateway.set(LEGACY_WORKOUT_INDEX_KEY, 100);
	migration.apply(clamped.gateway, clamped.progress, today);
	TestSupport.expectEntry(clamped.progress.latest(), 2026, 10, 7, 39, Rating.GOOD, "index 100 clamps to 39");
	TestSupport.expectRecommendation(clamped.progress.latest(), today, 40, false, "clamped index recommends 40");

	var atCap = TestSupport.openStore(100);
	atCap.gateway.set(LEGACY_WORKOUT_INDEX_KEY, 40);
	migration.apply(atCap.gateway, atCap.progress, today);
	TestSupport.expectEqual(39, (atCap.progress.latest() as HistoryEntry).workoutId, "index 40 clamps to 39");

	var negative = TestSupport.openStore(100);
	negative.gateway.set(LEGACY_WORKOUT_INDEX_KEY, -4);
	TestSupport.expectFalse(migration.apply(negative.gateway, negative.progress, today), "negative index");
	TestSupport.expectEqual(0, negative.progress.size(), "negative index adds nothing");
	TestSupport.expectTrue(negative.gateway.get(LEGACY_WORKOUT_INDEX_KEY) == null, "negative index removes the key");

	var text = TestSupport.openStore(100);
	text.gateway.set(LEGACY_WORKOUT_INDEX_KEY, "5");
	TestSupport.expectFalse(migration.apply(text.gateway, text.progress, today), "text index");
	TestSupport.expectEqual(0, text.progress.size(), "text index adds nothing");
	TestSupport.expectTrue(text.gateway.get(LEGACY_WORKOUT_INDEX_KEY) == null, "text index removes the key");

	var existing = TestSupport.openStore(100);
	existing.progress.addEntry(today, 8, Rating.OK);
	existing.gateway.set(LEGACY_WORKOUT_INDEX_KEY, 5);
	TestSupport.expectFalse(migration.apply(existing.gateway, existing.progress, today), "history wins");
	TestSupport.expectEqual(1, existing.progress.size(), "no synthetic entry");
	TestSupport.expectEqual(8, (existing.progress.latest() as HistoryEntry).workoutId, "existing entry kept");
	TestSupport.expectTrue(existing.gateway.get(LEGACY_WORKOUT_INDEX_KEY) == null, "leftover key removed");
	existing.progress.clear();
	TestSupport.expectFalse(migration.apply(existing.gateway, existing.progress, today), "cleared history does not replay the key");
	TestSupport.expectEqual(0, existing.progress.size(), "still empty");
	return true;
}
