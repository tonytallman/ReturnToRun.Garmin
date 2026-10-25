import Toybox.Lang;
import Toybox.Test;

(:test)
function testWorkoutDuration(logger as Test.Logger) as Boolean {
	logger.debug("workout duration");
	var intervals = new Workout(60, 60, 3, 300, 300);
	TestSupport.expectEqual(960, WorkoutDuration.totalSeconds(intervals), "warm-up, three runs, three walks, cool-down");
	TestSupport.expectEqual(16, WorkoutDuration.roundedMinutes(960), "16 min");
	TestSupport.expectEqual(960, WorkoutDuration.remainingSeconds(intervals, 0, 300), "full warm-up is the full workout");
	TestSupport.expectEqual(959, WorkoutDuration.remainingSeconds(intervals, 0, 299), "one second into warm-up");
	TestSupport.expectEqual(600, WorkoutDuration.remainingSeconds(intervals, 2, 60), "first walk still full");
	TestSupport.expectEqual(360, WorkoutDuration.remainingSeconds(intervals, 6, 60), "the walk before cool-down");
	TestSupport.expectEqual(10, WorkoutDuration.remainingSeconds(intervals, 7, 10), "ten seconds of cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingSeconds(intervals, 7, 0), "cool-down just finished");
	TestSupport.expectEqual(0, WorkoutDuration.remainingSeconds(intervals, 8, 10), "past the last segment");
	TestSupport.expectEqual(0, WorkoutDuration.remainingSeconds(intervals, -1, 10), "negative index");
	TestSupport.expectEqual(660, WorkoutDuration.remainingSeconds(intervals, 0, -5), "negative time left does not subtract");

	var continuous = new Workout(1800, 0, 1, 300, 300);
	TestSupport.expectEqual(2400, WorkoutDuration.totalSeconds(continuous), "warm-up, 30 min run, cool-down, no walk");
	TestSupport.expectEqual(40, WorkoutDuration.roundedMinutes(2400), "40 min");
	TestSupport.expectEqual(2100, WorkoutDuration.remainingSeconds(continuous, 1, 1800), "the run, then cool-down is still ahead");

	var single = new Workout(540, 60, 1, 300, 300);
	TestSupport.expectEqual(1200, WorkoutDuration.totalSeconds(single), "one run, then the walk before cool-down");

	var two = new Workout(540, 60, 2, 300, 300);
	TestSupport.expectEqual(1800, WorkoutDuration.totalSeconds(two), "a walk after each of two runs");
	TestSupport.expectEqual(30, WorkoutDuration.roundedMinutes(1800), "30 min");

	TestSupport.expectEqual(0, WorkoutDuration.roundedMinutes(0), "zero");
	TestSupport.expectEqual(0, WorkoutDuration.roundedMinutes(-1), "negative");
	TestSupport.expectEqual(0, WorkoutDuration.roundedMinutes(29), "29 seconds rounds down");
	TestSupport.expectEqual(1, WorkoutDuration.roundedMinutes(30), "30 seconds rounds up");
	TestSupport.expectEqual(1, WorkoutDuration.roundedMinutes(89), "89 seconds is still one minute");
	TestSupport.expectEqual(2, WorkoutDuration.roundedMinutes(90), "90 seconds rounds up");
	return true;
}

// The direct total and per-segment lengths must match the full segment
// sequence for every workout in the program.
(:test)
function testWorkoutTotalsMatchSegments(logger as Test.Logger) as Boolean {
	logger.debug("workout totals match segments");
	var program = WorkoutProgram.load();
	TestSupport.expectTrue(program.maxId() > 0, "program has workouts");
	for (var id = FIRST_WORKOUT_ID; id <= program.maxId(); id++) {
		var definition = program.workoutById(id) as WorkoutDefinition;
		var workout = new Workout(definition.runSeconds, definition.walkSeconds, definition.repeatCount, program.warmUpSeconds, program.coolDownSeconds);
		var sum = 0;
		var count = workout.getActivityCount();
		for (var index = 0; index < count; index++) {
			var seconds = (workout.getActivityAtIndex(index) as Activity).seconds;
			TestSupport.expectEqual(seconds, workout.secondsAtIndex(index), "segment " + index.toString() + " of workout " + id.toString());
			sum = sum + seconds;
		}
		TestSupport.expectEqual(sum, WorkoutDuration.totalSeconds(workout), "total of workout " + id.toString());
	}
	var intervals = new Workout(60, 60, 3, 300, 300);
	TestSupport.expectEqual(0, intervals.secondsAtIndex(-1), "negative index");
	TestSupport.expectEqual(0, intervals.secondsAtIndex(8), "past the last segment");
	return true;
}
