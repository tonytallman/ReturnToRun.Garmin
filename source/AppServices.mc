import Toybox.Application;
import Toybox.Lang;

// Composition root for the screens.
class AppServices {
	var program as WorkoutProgram;
	var trainingProgress as Progress;

	function initialize(program as WorkoutProgram, trainingProgress as Progress) {
		self.program = program;
		self.trainingProgress = trainingProgress;
	}

	static function production() as AppServices {
		var program = WorkoutProgram.load();
		var gateway = new ApplicationStorageGateway();
		var history = new HistoryStore(gateway, HISTORY_ENTRY_CAP, program.maxId());
		history.load();
		return new AppServices(program, new Progress(history));
	}

	function currentDay() as CalendarDay {
		return CalendarDay.today();
	}

	function recommendedWorkoutIndex() as Number {
		return trainingProgress.recommend(currentDay()).workoutId - 1;
	}

	function workoutCount() as Number {
		return program.maxId();
	}

	function workoutAtIndex(zeroBasedIndex as Number) as Workout? {
		var definition = program.workoutById(zeroBasedIndex + 1);
		if (definition == null) {
			return null;
		}
		var workoutDefinition = definition as WorkoutDefinition;
		return new Workout(workoutDefinition.runSeconds, workoutDefinition.walkSeconds, workoutDefinition.repeatCount, program.warmUpSeconds, program.coolDownSeconds);
	}

	// The current UI has no rating screen. Reaching cool-down records Good, which
	// advances the recommendation by one, matching the old stored-index increment.
	function recordCompletedWorkout(zeroBasedIndex as Number) as Void {
		var today = currentDay();
		trainingProgress.addEntry(today, zeroBasedIndex + 1, Rating.GOOD);
	}

	function warningsForToday() as Array<Number> {
		return trainingProgress.warnings(currentDay());
	}

	function shouldShowProgramComplete() as Boolean {
		return trainingProgress.shouldShowProgramComplete(currentDay());
	}

	function markProgramCompleteShown() as Void {
		trainingProgress.markProgramCompleteShown();
	}
}

function appServices() as AppServices {
	return (Application.getApp() as ReturnToRunApp).getServices();
}
