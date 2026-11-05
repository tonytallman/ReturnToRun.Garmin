import Toybox.Lang;
import Toybox.Test;

(:test)
function testProgramCatalog(logger as Test.Logger) as Boolean {
	logger.debug("program catalog");
	var program = WorkoutProgram.load();
	TestSupport.expectEqual(300, program.warmUpSeconds, "warm-up");
	TestSupport.expectEqual(300, program.coolDownSeconds, "cool-down");
	TestSupport.expectEqual(40, program.maxId(), "workout count");
	TestSupport.expectNull(program.workoutById(0), "id 0");
	TestSupport.expectNull(program.workoutById(41), "id 41");

	for (var id = 1; id <= 40; id++) {
		var definition = program.workoutById(id);
		TestSupport.expectTrue(definition != null, "missing workout");
		var workout = definition as WorkoutDefinition;
		TestSupport.expectEqual(id, workout.id, "id");
		TestSupport.expectEqual((id >= 38) ? 0 : 60, workout.walkSeconds, "walk, none in the final three");
		TestSupport.expectEqual(TestSupport.expectedRunSeconds(id), workout.runSeconds, "run");
		TestSupport.expectEqual(TestSupport.expectedRepeatCount(id), workout.repeatCount, "reps");
	}

	TestSupport.expectEqual(15, (program.workoutById(13) as WorkoutDefinition).repeatCount, "id 13 reps");
	TestSupport.expectEqual(120, (program.workoutById(14) as WorkoutDefinition).runSeconds, "id 14 run");
	TestSupport.expectEqual(10, (program.workoutById(21) as WorkoutDefinition).repeatCount, "id 21 reps");
	TestSupport.expectEqual(180, (program.workoutById(22) as WorkoutDefinition).runSeconds, "id 22 run");
	TestSupport.expectEqual(8, (program.workoutById(27) as WorkoutDefinition).repeatCount, "id 27 reps");
	TestSupport.expectEqual(2, (program.workoutById(28) as WorkoutDefinition).repeatCount, "id 28 reps");
	TestSupport.expectEqual(6, (program.workoutById(32) as WorkoutDefinition).repeatCount, "id 32 reps");
	TestSupport.expectEqual(540, (program.workoutById(33) as WorkoutDefinition).runSeconds, "id 33 run");
	TestSupport.expectEqual(3, (program.workoutById(35) as WorkoutDefinition).repeatCount, "id 35 reps");
	TestSupport.expectEqual(840, (program.workoutById(36) as WorkoutDefinition).runSeconds, "id 36 run");
	TestSupport.expectEqual(2, (program.workoutById(37) as WorkoutDefinition).repeatCount, "id 37 reps");
	TestSupport.expectEqual(1200, (program.workoutById(38) as WorkoutDefinition).runSeconds, "id 38 run");
	TestSupport.expectEqual(1500, (program.workoutById(39) as WorkoutDefinition).runSeconds, "id 39 run");
	TestSupport.expectEqual(1800, (program.workoutById(40) as WorkoutDefinition).runSeconds, "id 40 run");

	var mismatched = {} as Dictionary;
	mismatched.put("id", 5);
	mismatched.put("runSeconds", 60);
	mismatched.put("walkSeconds", 60);
	mismatched.put("repeatCount", 3);
	var incomplete = {} as Dictionary;
	incomplete.put("id", 1);
	var rows = [] as Array<Dictionary>;
	rows.add(mismatched);
	rows.add(incomplete);
	var data = {} as Dictionary;
	data.put("workouts", rows);
	var parsed = WorkoutProgram.fromDictionary(data);
	TestSupport.expectEqual(0, parsed.warmUpSeconds, "missing warm-up is not invented");
	TestSupport.expectEqual(0, parsed.coolDownSeconds, "missing cool-down is not invented");
	TestSupport.expectEqual(1, parsed.maxId(), "incomplete row skipped");
	TestSupport.expectNull(parsed.workoutById(1), "stored id must match its position");
	return true;
}

(:test)
function testWorkoutSequence(logger as Test.Logger) as Boolean {
	logger.debug("workout sequence");
	var workout = new Workout(60, 60, 3, 300, 300);
	TestSupport.expectEqual(8, workout.getActivityCount(), "warm-up, 3 runs, 3 walks, cool-down");
	var warmUp = workout.getActivityAtIndex(0) as Activity;
	var firstRun = workout.getActivityAtIndex(1) as Activity;
	var firstWalk = workout.getActivityAtIndex(2) as Activity;
	var thirdRun = workout.getActivityAtIndex(5) as Activity;
	var lastWalk = workout.getActivityAtIndex(6) as Activity;
	var coolDown = workout.getActivityAtIndex(7) as Activity;
	TestSupport.expectTrue(warmUp.type == WarmUp, "index 0 is warm-up");
	TestSupport.expectEqual(300, warmUp.seconds, "warm-up seconds");
	TestSupport.expectTrue(firstRun.type == Run, "index 1 is a run");
	TestSupport.expectEqual(60, firstRun.seconds, "run seconds");
	TestSupport.expectTrue(firstWalk.type == Walk, "index 2 is a walk");
	TestSupport.expectEqual(60, firstWalk.seconds, "walk seconds");
	TestSupport.expectTrue(thirdRun.type == Run, "index 5 is a run");
	TestSupport.expectTrue(lastWalk.type == Walk, "a walk comes before cool-down");
	TestSupport.expectEqual(60, lastWalk.seconds, "one-minute walk before cool-down");
	TestSupport.expectTrue(coolDown.type == CoolDown, "last index is cool-down");
	TestSupport.expectEqual(300, coolDown.seconds, "cool-down seconds");
	TestSupport.expectNull(workout.getActivityAtIndex(8), "past the end");
	TestSupport.expectNull(workout.getActivityAtIndex(-1), "negative index");

	var single = new Workout(540, 60, 1, 300, 300);
	TestSupport.expectEqual(4, single.getActivityCount(), "warm-up, run, walk, cool-down");
	TestSupport.expectTrue((single.getActivityAtIndex(2) as Activity).type == Walk, "single repeat still walks before cool-down");

	var continuous = new Workout(1800, 0, 1, 300, 300);
	TestSupport.expectEqual(3, continuous.getActivityCount(), "warm-up, run, cool-down");
	TestSupport.expectTrue((continuous.getActivityAtIndex(1) as Activity).type == Run, "the run");
	TestSupport.expectTrue((continuous.getActivityAtIndex(2) as Activity).type == CoolDown, "no walk before cool-down");

	var runsOnly = new Workout(120, 0, 3, 300, 300);
	TestSupport.expectEqual(5, runsOnly.getActivityCount(), "warm-up, 3 runs, cool-down");
	TestSupport.expectTrue((runsOnly.getActivityAtIndex(2) as Activity).type == Run, "no walks between runs");
	return true;
}

(:test)
function testCurrentUiMapping(logger as Test.Logger) as Boolean {
	logger.debug("current ui mapping");
	var program = WorkoutProgram.load();
	var gateway = new MemoryStorageGateway();
	var store = new HistoryStore(gateway, 10, program.maxId());
	store.load();
	var services = new AppServices(program, new Progress(store), new Breadcrumbs());
	TestSupport.expectEqual(40, services.workoutCount(), "count");
	TestSupport.expectEqual(0, services.recommendedWorkoutIndex(), "empty history recommends the first");
	var first = services.workoutAtIndex(0) as Workout;
	TestSupport.expectEqual(8, first.getActivityCount(), "first workout length");
	TestSupport.expectEqual(300, (first.getActivityAtIndex(0) as Activity).seconds, "warm-up comes from the program");
	TestSupport.expectEqual(1800, (services.workoutAtIndex(39) as Workout).runSeconds, "last workout");
	TestSupport.expectNull(services.workoutAtIndex(-1), "negative index");
	TestSupport.expectNull(services.workoutAtIndex(40), "past the last workout");

	TestSupport.expectFalse(services.logWorkout(4, Rating.GOOD), "workout 5 does not complete the program");
	var logged = services.trainingProgress.latest() as HistoryEntry;
	TestSupport.expectEqual(5, logged.workoutId, "logs the 1-based id");
	TestSupport.expectEqual(Rating.GOOD, logged.rating, "logs the chosen rating");
	TestSupport.expectEqual(0, logged.date.compare(CalendarDay.today()), "logged on the device's today");
	TestSupport.expectEqual(5, services.recommendedWorkoutIndex(), "Good advances the 0-based index by one");
	return true;
}
