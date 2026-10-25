import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Composition root for the screens.
class AppServices {
	var program as WorkoutProgram;
	var trainingProgress as Progress;
	var activeRecorder as WorkoutRecording.Recorder?;

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

	// Logs a rated run on today's date. Returns true when the program-complete
	// screen should show.
	function logWorkout(zeroBasedIndex as Number, rating as Number) as Boolean {
		return trainingProgress.logWorkout(currentDay(), zeroBasedIndex + 1, rating);
	}

	// One recorder per workout. The app keeps the latest so it can save an
	// unfinished run if the app is stopped.
	function newRecorder() as WorkoutRecording.Recorder {
		var name = WatchUi.loadResource(Rez.Strings.AppName) as String;
		var recorder = new WorkoutRecording.Recorder(new FitRecordingPort(name));
		activeRecorder = recorder;
		return recorder;
	}

	function finishActiveRecording() as Void {
		if (activeRecorder != null) {
			(activeRecorder as WorkoutRecording.Recorder).save();
		}
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
