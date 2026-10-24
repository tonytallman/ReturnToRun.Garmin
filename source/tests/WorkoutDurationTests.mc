import Toybox.Lang;
import Toybox.Test;

(:test)
function testWorkoutDuration(logger as Test.Logger) as Boolean {
	logger.debug("workout duration");
	var intervals = new Workout(60, 60, 3, 300, 300);
	TestSupport.expectEqual(900, WorkoutDuration.totalSeconds(intervals), "warm-up, three runs, two walks, cool-down");
	TestSupport.expectEqual(15, WorkoutDuration.roundedMinutes(900), "15 min, the replaced walk is not added again");
	TestSupport.expectEqual(900, WorkoutDuration.remainingSeconds(intervals, 0, 300), "full warm-up is the full workout");
	TestSupport.expectEqual(899, WorkoutDuration.remainingSeconds(intervals, 0, 299), "one second into warm-up");
	TestSupport.expectEqual(540, WorkoutDuration.remainingSeconds(intervals, 2, 60), "first walk still full");
	TestSupport.expectEqual(10, WorkoutDuration.remainingSeconds(intervals, 6, 10), "ten seconds of cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingSeconds(intervals, 6, 0), "cool-down just finished");
	TestSupport.expectEqual(0, WorkoutDuration.remainingSeconds(intervals, 7, 10), "past the last segment");
	TestSupport.expectEqual(0, WorkoutDuration.remainingSeconds(intervals, -1, 10), "negative index");
	TestSupport.expectEqual(600, WorkoutDuration.remainingSeconds(intervals, 0, -5), "negative time left does not subtract");

	var continuous = new Workout(1800, 60, 1, 300, 300);
	TestSupport.expectEqual(2400, WorkoutDuration.totalSeconds(continuous), "warm-up, 30 min run, cool-down");
	TestSupport.expectEqual(40, WorkoutDuration.roundedMinutes(2400), "40 min");
	TestSupport.expectEqual(1800, WorkoutDuration.remainingSeconds(continuous, 1, 1800), "the run, then cool-down is still ahead");

	var two = new Workout(540, 60, 2, 300, 300);
	TestSupport.expectEqual(1740, WorkoutDuration.totalSeconds(two), "one walk between two runs");
	TestSupport.expectEqual(29, WorkoutDuration.roundedMinutes(1740), "29 min");

	TestSupport.expectEqual(0, WorkoutDuration.roundedMinutes(0), "zero");
	TestSupport.expectEqual(0, WorkoutDuration.roundedMinutes(-1), "negative");
	TestSupport.expectEqual(0, WorkoutDuration.roundedMinutes(29), "29 seconds rounds down");
	TestSupport.expectEqual(1, WorkoutDuration.roundedMinutes(30), "30 seconds rounds up");
	TestSupport.expectEqual(1, WorkoutDuration.roundedMinutes(89), "89 seconds is still one minute");
	TestSupport.expectEqual(2, WorkoutDuration.roundedMinutes(90), "90 seconds rounds up");
	return true;
}
