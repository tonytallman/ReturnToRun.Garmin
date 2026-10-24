import Toybox.Lang;
import Toybox.Test;

(:test)
function testCountdownTones(logger as Test.Logger) as Boolean {
	logger.debug("countdown tones");
	TestSupport.expectEqual(5, CountdownTones.LAST_SECONDS, "five-second window");
	for (var second = 1; second <= CountdownTones.LAST_SECONDS; second++) {
		TestSupport.expectTrue(CountdownTones.shouldPlay(second), "beep at " + second);
	}
	TestSupport.expectFalse(CountdownTones.shouldPlay(0), "zero is the next segment, not a beep");
	TestSupport.expectFalse(CountdownTones.shouldPlay(6), "six seconds remain");
	TestSupport.expectFalse(CountdownTones.shouldPlay(60), "a full minute");
	TestSupport.expectFalse(CountdownTones.shouldPlay(300), "warm-up length");
	TestSupport.expectFalse(CountdownTones.shouldPlay(-1), "negative remaining time");
	return true;
}

(:test)
function testIntervalCount(logger as Test.Logger) as Boolean {
	logger.debug("interval count");
	var repeatCount = 8;
	TestSupport.expectNull(IntervalCount.numberFor(0, repeatCount, true), "warm-up has no repeat");
	TestSupport.expectEqual("", IntervalCount.labelFor(0, repeatCount, true), "warm-up label");

	for (var repeat = 1; repeat < repeatCount; repeat++) {
		var runIndex = (repeat * 2) - 1;
		var walkIndex = runIndex + 1;
		var label = repeat.toString() + "/" + repeatCount.toString();
		TestSupport.expectEqual(repeat, IntervalCount.numberFor(runIndex, repeatCount, true), "run " + repeat);
		TestSupport.expectEqual(repeat, IntervalCount.numberFor(walkIndex, repeatCount, true), "walk after run " + repeat);
		TestSupport.expectEqual(label, IntervalCount.labelFor(runIndex, repeatCount, true), "run label " + repeat);
		TestSupport.expectEqual(label, IntervalCount.labelFor(walkIndex, repeatCount, true), "walk label " + repeat);
	}

	var lastRunIndex = (repeatCount * 2) - 1;
	TestSupport.expectEqual(repeatCount, IntervalCount.numberFor(lastRunIndex, repeatCount, true), "last run");
	TestSupport.expectEqual("8/8", IntervalCount.labelFor(lastRunIndex, repeatCount, true), "last run label");
	TestSupport.expectEqual("8/8", IntervalCount.labelFor(lastRunIndex + 1, repeatCount, true), "walk before cool-down shares the last count");
	TestSupport.expectNull(IntervalCount.numberFor(lastRunIndex + 2, repeatCount, true), "cool-down has no count");
	TestSupport.expectEqual("", IntervalCount.labelFor(lastRunIndex + 2, repeatCount, true), "cool-down label");

	TestSupport.expectEqual("1/1", IntervalCount.labelFor(1, 1, true), "only run label");
	TestSupport.expectEqual("1/1", IntervalCount.labelFor(2, 1, true), "only walk label");
	TestSupport.expectNull(IntervalCount.numberFor(3, 1, true), "single-repeat cool-down");
	TestSupport.expectEqual("1/1", IntervalCount.labelFor(1, 1, false), "continuous run label");
	TestSupport.expectNull(IntervalCount.numberFor(2, 1, false), "continuous cool-down");
	TestSupport.expectEqual("2/3", IntervalCount.labelFor(2, 3, false), "runs without walks count each run");
	TestSupport.expectNull(IntervalCount.numberFor(0, 1, true), "single-repeat warm-up");
	TestSupport.expectNull(IntervalCount.numberFor(1, 0, true), "no repeats");
	TestSupport.expectNull(IntervalCount.numberFor(-1, 8, true), "negative index");

	var workout = new Workout(60, 60, 3, 300, 300);
	TestSupport.expectEqual("", IntervalCount.labelFor(0, workout.repeatCount, workout.hasWalks()), "sequence warm-up");
	TestSupport.expectEqual("1/3", IntervalCount.labelFor(1, workout.repeatCount, workout.hasWalks()), "sequence first run");
	TestSupport.expectEqual("1/3", IntervalCount.labelFor(2, workout.repeatCount, workout.hasWalks()), "sequence first walk");
	TestSupport.expectEqual("3/3", IntervalCount.labelFor(5, workout.repeatCount, workout.hasWalks()), "sequence last run");
	TestSupport.expectEqual("3/3", IntervalCount.labelFor(6, workout.repeatCount, workout.hasWalks()), "sequence last walk");
	TestSupport.expectEqual("", IntervalCount.labelFor(7, workout.repeatCount, workout.hasWalks()), "sequence cool-down");
	return true;
}

(:test)
function testSegmentAlerts(logger as Test.Logger) as Boolean {
	logger.debug("segment alerts");
	TestSupport.expectEqual(SegmentAlerts.SEGMENT, SegmentAlerts.forActivityType(Run), "run");
	TestSupport.expectEqual(SegmentAlerts.SEGMENT, SegmentAlerts.forActivityType(WarmUp), "warm-up");
	TestSupport.expectEqual(SegmentAlerts.SEGMENT, SegmentAlerts.forActivityType(Walk), "walk");
	TestSupport.expectEqual(SegmentAlerts.SEGMENT, SegmentAlerts.forActivityType(CoolDown), "cool-down");
	TestSupport.expectEqual(SegmentAlerts.WORKOUT_COMPLETE, SegmentAlerts.forWorkoutComplete(), "workout complete");
	TestSupport.expectTrue(SegmentAlerts.forActivityType(CoolDown) != SegmentAlerts.WORKOUT_COMPLETE, "cool-down is not completion");
	TestSupport.expectTrue(SegmentAlerts.forActivityType(Run) == SegmentAlerts.forActivityType(Walk), "segments share one pulse");

	var repeatCount = 4;
	var workout = new Workout(60, 60, repeatCount, 300, 300);
	var count = workout.getActivityCount();
	for (var index = 0; index < count; index++) {
		var activity = workout.getActivityAtIndex(index) as Activity;
		var alert = SegmentAlerts.forActivityType(activity.type);
		TestSupport.expectEqual(SegmentAlerts.SEGMENT, alert, "every segment shares one pulse");
	}
	TestSupport.expectNull(workout.getActivityAtIndex(count), "no segment past cool-down");
	return true;
}
