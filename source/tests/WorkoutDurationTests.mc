import Toybox.Lang;
import Toybox.Test;

(:test)
function testWorkoutDuration(logger as Test.Logger) as Boolean {
	logger.debug("workout duration");
	var intervals = new Workout(60, 60, 3, 300, 300);
	TestSupport.expectEqual(960, WorkoutDuration.totalSeconds(intervals), "warm-up, three runs, three walks, cool-down");
	TestSupport.expectEqual(16, WorkoutDuration.roundedMinutes(960), "16 min");

	var continuous = new Workout(1800, 0, 1, 300, 300);
	TestSupport.expectEqual(2400, WorkoutDuration.totalSeconds(continuous), "warm-up, 30 min run, cool-down, no walk");
	TestSupport.expectEqual(40, WorkoutDuration.roundedMinutes(2400), "40 min");

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

// The workout screen counts down to cool-down and shows no time left during it.
(:test)
function testTimeRemainingSkipsCoolDown(logger as Test.Logger) as Boolean {
	logger.debug("time remaining skips cool-down");
	var intervals = new Workout(60, 60, 3, 300, 300);
	// 60/60 x3 with 300 s warm-up and cool-down: indexes 0 warm-up, 1-6 run/walk, 7 cool-down.
	TestSupport.expectEqual(660, WorkoutDuration.remainingBeforeCoolDown(intervals, 0, 300), "full warm-up: everything but cool-down");
	TestSupport.expectEqual(659, WorkoutDuration.remainingBeforeCoolDown(intervals, 0, 299), "one second into warm-up");
	TestSupport.expectEqual(300, WorkoutDuration.remainingBeforeCoolDown(intervals, 2, 60), "first walk still full");
	TestSupport.expectEqual(60, WorkoutDuration.remainingBeforeCoolDown(intervals, 6, 60), "the walk before cool-down is all that is left");
	TestSupport.expectEqual(1, WorkoutDuration.remainingBeforeCoolDown(intervals, 6, 1), "last second before cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingBeforeCoolDown(intervals, 7, 300), "start of cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingBeforeCoolDown(intervals, 7, 10), "ten seconds of cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingBeforeCoolDown(intervals, 8, 10), "past the last segment");
	TestSupport.expectEqual(0, WorkoutDuration.remainingBeforeCoolDown(intervals, -1, 10), "negative index");
	TestSupport.expectEqual(360, WorkoutDuration.remainingBeforeCoolDown(intervals, 0, -5), "negative time left does not subtract");
	TestSupport.expectEqual(WorkoutDuration.totalSeconds(intervals) - 300, WorkoutDuration.remainingBeforeCoolDown(intervals, 0, 300), "start: total minus cool-down");
	// Paused: no tick, so the same segment and seconds give the same value.
	TestSupport.expectEqual(WorkoutDuration.remainingBeforeCoolDown(intervals, 3, 42), WorkoutDuration.remainingBeforeCoolDown(intervals, 3, 42), "paused value is stable");

	TestSupport.expectTrue(WorkoutDuration.showsRemaining(intervals, 0), "warm-up shows time left");
	TestSupport.expectTrue(WorkoutDuration.showsRemaining(intervals, 1), "run shows time left");
	TestSupport.expectTrue(WorkoutDuration.showsRemaining(intervals, 6), "walk before cool-down shows time left");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(intervals, 7), "cool-down hides time left");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(intervals, 8), "past the last segment");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(intervals, -1), "negative index");

	var continuous = new Workout(1800, 0, 1, 300, 300);
	TestSupport.expectEqual(1800, WorkoutDuration.remainingBeforeCoolDown(continuous, 1, 1800), "the run is all that is left, no walk");
	TestSupport.expectEqual(2100, WorkoutDuration.remainingBeforeCoolDown(continuous, 0, 300), "warm-up counts");
	TestSupport.expectEqual(0, WorkoutDuration.remainingBeforeCoolDown(continuous, 2, 300), "continuous cool-down");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(continuous, 2), "continuous cool-down hides time left");

	// A program without a cool-down still ends with a zero-length cool-down segment.
	var noCoolDown = new Workout(60, 60, 1, 300, 0);
	TestSupport.expectEqual(420, WorkoutDuration.totalSeconds(noCoolDown), "no cool-down total");
	TestSupport.expectEqual(420, WorkoutDuration.remainingBeforeCoolDown(noCoolDown, 0, 300), "no cool-down: remaining is the total");
	TestSupport.expectEqual(0, WorkoutDuration.remainingBeforeCoolDown(noCoolDown, 3, 0), "zero-length cool-down");

	// Every program workout starts with its total minus cool-down.
	var program = WorkoutProgram.load();
	for (var id = FIRST_WORKOUT_ID; id <= program.maxId(); id++) {
		var definition = program.workoutById(id) as WorkoutDefinition;
		var workout = new Workout(definition.runSeconds, definition.walkSeconds, definition.repeatCount, program.warmUpSeconds, program.coolDownSeconds);
		TestSupport.expectEqual(WorkoutDuration.totalSeconds(workout) - program.coolDownSeconds, WorkoutDuration.remainingBeforeCoolDown(workout, 0, program.warmUpSeconds), "start of workout " + id.toString());
		TestSupport.expectFalse(WorkoutDuration.showsRemaining(workout, workout.getActivityCount() - 1), "cool-down of workout " + id.toString());
	}
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
