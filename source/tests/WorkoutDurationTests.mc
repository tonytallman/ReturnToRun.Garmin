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

// The workout screen counts down only the run/walk main set and shows no time
// left during warm-up or cool-down.
(:test)
function testTimeRemainingMainSetOnly(logger as Test.Logger) as Boolean {
	logger.debug("time remaining counts only the main set");
	var intervals = new Workout(60, 60, 3, 300, 300);
	// 60/60 x3 with 300 s warm-up and cool-down: indexes 0 warm-up, 1-6 run/walk, 7 cool-down.
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(intervals, 0, 300), "start of warm-up");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(intervals, 0, 1), "end of warm-up");
	TestSupport.expectEqual(360, WorkoutDuration.remainingInMainSet(intervals, 1, 60), "first run: the whole main set");
	TestSupport.expectEqual(359, WorkoutDuration.remainingInMainSet(intervals, 1, 59), "one second into the first run");
	TestSupport.expectEqual(300, WorkoutDuration.remainingInMainSet(intervals, 2, 60), "first walk still full");
	TestSupport.expectEqual(60, WorkoutDuration.remainingInMainSet(intervals, 6, 60), "the walk before cool-down is all that is left");
	TestSupport.expectEqual(1, WorkoutDuration.remainingInMainSet(intervals, 6, 1), "last second before cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(intervals, 7, 300), "start of cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(intervals, 7, 10), "ten seconds of cool-down");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(intervals, 8, 10), "past the last segment");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(intervals, -1, 10), "negative index");
	TestSupport.expectEqual(300, WorkoutDuration.remainingInMainSet(intervals, 1, -5), "negative time left does not subtract");
	// Paused: no tick, so the same segment and seconds give the same value.
	TestSupport.expectEqual(WorkoutDuration.remainingInMainSet(intervals, 3, 42), WorkoutDuration.remainingInMainSet(intervals, 3, 42), "paused value is stable");

	TestSupport.expectFalse(WorkoutDuration.showsRemaining(intervals, 0), "warm-up hides time left");
	TestSupport.expectTrue(WorkoutDuration.showsRemaining(intervals, 1), "first run shows time left");
	TestSupport.expectTrue(WorkoutDuration.showsRemaining(intervals, 6), "walk before cool-down shows time left");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(intervals, 7), "cool-down hides time left");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(intervals, 8), "past the last segment");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(intervals, -1), "negative index");

	var continuous = new Workout(1800, 0, 1, 300, 300);
	TestSupport.expectEqual(1800, WorkoutDuration.remainingInMainSet(continuous, 1, 1800), "continuous: the one run is the main set");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(continuous, 0, 300), "continuous warm-up");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(continuous, 2, 300), "continuous cool-down");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(continuous, 0), "continuous warm-up hides time left");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(continuous, 2), "continuous cool-down hides time left");

	// Zero-length warm-up and cool-down are still segments 0 and last.
	var bare = new Workout(60, 60, 1, 0, 0);
	TestSupport.expectEqual(4, bare.getActivityCount(), "zero-length warm-up and cool-down still exist");
	TestSupport.expectEqual(120, WorkoutDuration.totalSeconds(bare), "bare total");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(bare, 0, 0), "zero-length warm-up");
	TestSupport.expectFalse(WorkoutDuration.showsRemaining(bare, 0), "zero-length warm-up hides time left");
	TestSupport.expectEqual(120, WorkoutDuration.remainingInMainSet(bare, 1, 60), "bare: remaining is the total");
	TestSupport.expectEqual(0, WorkoutDuration.remainingInMainSet(bare, 3, 0), "zero-length cool-down");

	// Every program workout's first run starts with its total minus warm-up and cool-down.
	var program = WorkoutProgram.load();
	for (var id = FIRST_WORKOUT_ID; id <= program.maxId(); id++) {
		var definition = program.workoutById(id) as WorkoutDefinition;
		var workout = new Workout(definition.runSeconds, definition.walkSeconds, definition.repeatCount, program.warmUpSeconds, program.coolDownSeconds);
		var expected = WorkoutDuration.totalSeconds(workout) - program.warmUpSeconds - program.coolDownSeconds;
		TestSupport.expectEqual(expected, WorkoutDuration.remainingInMainSet(workout, 1, workout.secondsAtIndex(1)), "first run of workout " + id.toString());
		TestSupport.expectFalse(WorkoutDuration.showsRemaining(workout, 0), "warm-up of workout " + id.toString());
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
