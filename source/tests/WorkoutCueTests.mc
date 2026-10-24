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
	TestSupport.expectNull(IntervalCount.numberFor(0, repeatCount), "warm-up has no repeat");
	TestSupport.expectEqual("", IntervalCount.labelFor(0, repeatCount), "warm-up label");

	for (var repeat = 1; repeat < repeatCount; repeat++) {
		var runIndex = (repeat * 2) - 1;
		var walkIndex = runIndex + 1;
		var label = repeat.toString() + "/" + repeatCount.toString();
		TestSupport.expectEqual(repeat, IntervalCount.numberFor(runIndex, repeatCount), "run " + repeat);
		TestSupport.expectEqual(repeat, IntervalCount.numberFor(walkIndex, repeatCount), "walk after run " + repeat);
		TestSupport.expectEqual(label, IntervalCount.labelFor(runIndex, repeatCount), "run label " + repeat);
		TestSupport.expectEqual(label, IntervalCount.labelFor(walkIndex, repeatCount), "walk label " + repeat);
	}

	var lastRunIndex = (repeatCount * 2) - 1;
	TestSupport.expectEqual(repeatCount, IntervalCount.numberFor(lastRunIndex, repeatCount), "last run");
	TestSupport.expectEqual("8/8", IntervalCount.labelFor(lastRunIndex, repeatCount), "last run label");
	TestSupport.expectNull(IntervalCount.numberFor(lastRunIndex + 1, repeatCount), "cool-down is the final walk");
	TestSupport.expectEqual("", IntervalCount.labelFor(lastRunIndex + 1, repeatCount), "cool-down label");
	TestSupport.expectNull(IntervalCount.numberFor(lastRunIndex + 2, repeatCount), "past the end");

	TestSupport.expectEqual(1, IntervalCount.numberFor(1, 1), "only run");
	TestSupport.expectEqual("1/1", IntervalCount.labelFor(1, 1), "only run label");
	TestSupport.expectNull(IntervalCount.numberFor(0, 1), "single-repeat warm-up");
	TestSupport.expectNull(IntervalCount.numberFor(2, 1), "single-repeat cool-down");
	TestSupport.expectNull(IntervalCount.numberFor(1, 0), "no repeats");
	TestSupport.expectNull(IntervalCount.numberFor(-1, 8), "negative index");

	var workout = new Workout(60, 60, 3, 300, 300);
	TestSupport.expectEqual("", IntervalCount.labelFor(0, workout.repeatCount), "sequence warm-up");
	TestSupport.expectEqual("1/3", IntervalCount.labelFor(1, workout.repeatCount), "sequence first run");
	TestSupport.expectEqual("1/3", IntervalCount.labelFor(2, workout.repeatCount), "sequence first walk");
	TestSupport.expectEqual("3/3", IntervalCount.labelFor(5, workout.repeatCount), "sequence last run");
	TestSupport.expectEqual("", IntervalCount.labelFor(6, workout.repeatCount), "sequence cool-down");
	return true;
}

(:test)
function testSegmentAlerts(logger as Test.Logger) as Boolean {
	logger.debug("segment alerts");
	TestSupport.expectEqual(SegmentAlerts.RUN, SegmentAlerts.forActivityType(Run), "run");
	TestSupport.expectEqual(SegmentAlerts.WALK, SegmentAlerts.forActivityType(WarmUp), "warm-up uses the walk pattern");
	TestSupport.expectEqual(SegmentAlerts.WALK, SegmentAlerts.forActivityType(Walk), "walk");
	TestSupport.expectEqual(SegmentAlerts.WALK, SegmentAlerts.forActivityType(CoolDown), "cool-down uses the walk pattern");
	TestSupport.expectEqual(SegmentAlerts.WORKOUT_COMPLETE, SegmentAlerts.forWorkoutComplete(), "workout complete");
	TestSupport.expectTrue(SegmentAlerts.forActivityType(CoolDown) != SegmentAlerts.WORKOUT_COMPLETE, "cool-down is not completion");

	var repeatCount = 4;
	var workout = new Workout(60, 60, repeatCount, 300, 300);
	var count = workout.getActivityCount();
	for (var index = 0; index < count; index++) {
		var activity = workout.getActivityAtIndex(index) as Activity;
		var alert = SegmentAlerts.forActivityType(activity.type);
		if ((index % 2) == 1) {
			TestSupport.expectEqual(SegmentAlerts.RUN, alert, "odd index is a run");
		} else {
			TestSupport.expectEqual(SegmentAlerts.WALK, alert, "warm-up, walk, and cool-down");
		}
	}
	TestSupport.expectNull(workout.getActivityAtIndex(count), "no segment past cool-down");
	return true;
}
