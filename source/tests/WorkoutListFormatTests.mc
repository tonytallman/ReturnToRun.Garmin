import Toybox.Lang;
import Toybox.Test;

(:test)
function testWorkoutListLabels(logger as Test.Logger) as Boolean {
	logger.debug("workout list labels");
	TestSupport.expectEqual("1", WorkoutListFormat.segmentClock(60), "whole minute");
	TestSupport.expectEqual("30", WorkoutListFormat.segmentClock(1800), "thirty minutes");
	TestSupport.expectEqual("0", WorkoutListFormat.segmentClock(0), "zero");
	TestSupport.expectEqual("0", WorkoutListFormat.segmentClock(-4), "negative becomes zero");
	TestSupport.expectEqual("1:30", WorkoutListFormat.segmentClock(90), "minutes and seconds");
	TestSupport.expectEqual("0:10", WorkoutListFormat.segmentClock(10), "under a minute");
	TestSupport.expectEqual("0:05", WorkoutListFormat.segmentClock(5), "padded seconds");

	TestSupport.expectTrue(WorkoutListFormat.includesWalk(60, 3), "repeats keep a walk");
	TestSupport.expectTrue(WorkoutListFormat.includesWalk(60, 1), "one repeat still walks before cool-down");
	TestSupport.expectFalse(WorkoutListFormat.includesWalk(0, 4), "a zero walk is not a walk");
	TestSupport.expectFalse(WorkoutListFormat.includesWalk(0, 1), "one repeat and no walk");

	TestSupport.expectEqual("#1  R1 W1 ×3", WorkoutListFormat.title(1, 60, 60, 3, "R", "W", "×"), "intervals");
	TestSupport.expectEqual("#40  R30", WorkoutListFormat.title(40, 1800, 0, 1, "R", "W", "×"), "continuous run has no walk or repeat");
	TestSupport.expectEqual("#33  R9 W1", WorkoutListFormat.title(33, 540, 60, 1, "R", "W", "×"), "nine minute run, then a walk");
	TestSupport.expectEqual("#34  R9 W1 ×2", WorkoutListFormat.title(34, 540, 60, 2, "R", "W", "×"), "two repeats, each with a walk");
	TestSupport.expectEqual("#8  R1:30 W0:45 ×2", WorkoutListFormat.title(8, 90, 45, 2, "R", "W", "×"), "partial minutes");
	TestSupport.expectEqual("#5  R2 ×4", WorkoutListFormat.title(5, 120, 0, 4, "R", "W", "×"), "repeats without a walk");

	TestSupport.expectEqual("15 min with walks", WorkoutListFormat.subtitle(900, true, "min", "with walks"), "intervals subtitle");
	TestSupport.expectEqual("40 min", WorkoutListFormat.subtitle(2400, false, "min", "with walks"), "continuous subtitle");
	TestSupport.expectEqual("2 min", WorkoutListFormat.subtitle(90, false, "min", "with walks"), "rounds to the nearest minute");
	TestSupport.expectEqual("★ 15 min with walks", WorkoutListFormat.withRecommendation("15 min with walks", true, "★ "), "recommended marker");
	TestSupport.expectEqual("15 min with walks", WorkoutListFormat.withRecommendation("15 min with walks", false, "★ "), "other workouts are unmarked");
	return true;
}

(:test)
function testCatalogListLabels(logger as Test.Logger) as Boolean {
	logger.debug("catalog list labels");
	var program = WorkoutProgram.load();
	var first = program.workoutById(1) as WorkoutDefinition;
	var wide = program.workoutById(13) as WorkoutDefinition;
	var last = program.workoutById(40) as WorkoutDefinition;
	TestSupport.expectEqual("#1  R1 W1 ×3", WorkoutListFormat.title(1, first.runSeconds, first.walkSeconds, first.repeatCount, "R", "W", "×"), "workout 1");
	TestSupport.expectEqual("#13  R1 W1 ×15", WorkoutListFormat.title(13, wide.runSeconds, wide.walkSeconds, wide.repeatCount, "R", "W", "×"), "workout 13");
	TestSupport.expectEqual("#40  R30", WorkoutListFormat.title(40, last.runSeconds, last.walkSeconds, last.repeatCount, "R", "W", "×"), "workout 40");

	var firstWorkout = new Workout(first.runSeconds, first.walkSeconds, first.repeatCount, program.warmUpSeconds, program.coolDownSeconds);
	var lastWorkout = new Workout(last.runSeconds, last.walkSeconds, last.repeatCount, program.warmUpSeconds, program.coolDownSeconds);
	var firstTotal = WorkoutDuration.totalSeconds(firstWorkout);
	var lastTotal = WorkoutDuration.totalSeconds(lastWorkout);
	TestSupport.expectEqual(960, firstTotal, "workout 1 is 16 min");
	TestSupport.expectEqual(2400, lastTotal, "workout 40 is 40 min");
	TestSupport.expectEqual("16 min with walks", WorkoutListFormat.subtitle(firstTotal, WorkoutListFormat.includesWalk(first.walkSeconds, first.repeatCount), "min", "with walks"), "workout 1 subtitle");
	TestSupport.expectEqual("40 min", WorkoutListFormat.subtitle(lastTotal, WorkoutListFormat.includesWalk(last.walkSeconds, last.repeatCount), "min", "with walks"), "workout 40 subtitle");
	return true;
}
