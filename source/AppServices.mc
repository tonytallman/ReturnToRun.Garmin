import Toybox.Application;
import Toybox.Lang;

// Composition root for the screens.
class AppServices {
	var program as WorkoutProgram;
	var trainingProgress as Progress;
	var activeRecorder as WorkoutRecording.Recorder?;
	var log as Breadcrumbs;
	// Bumped on every History edit so the History list knows to rebuild.
	var historyVersion as Number = 0;
	// The item the History list focuses after its next rebuild.
	var historyFocus as Number = 0;

	function initialize(program as WorkoutProgram, trainingProgress as Progress, log as Breadcrumbs) {
		self.log = log;
		self.program = program;
		self.trainingProgress = trainingProgress;
	}

	static function production(log as Breadcrumbs) as AppServices {
		var program = WorkoutProgram.load();
		var gateway = new ApplicationStorageGateway();
		var history = new HistoryStore(gateway, HISTORY_ENTRY_CAP, program.maxId());
		history.load();
		return new AppServices(program, new Progress(history), log);
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
		historyFocus = 0;
		historyChanged();
		return trainingProgress.logWorkout(currentDay(), zeroBasedIndex + 1, rating);
	}

	// One recorder per workout. The app keeps the latest so it can save an
	// unfinished run if the app is stopped.
	function newRecorder(workoutId as Number) as WorkoutRecording.Recorder {
		var name = RecordingActivityName.forWorkout(workoutId);
		var recorder = new WorkoutRecording.Recorder(new FitRecordingPort(name, log));
		activeRecorder = recorder;
		return recorder;
	}

	// Returns true when a run was still open and has been saved.
	function finishActiveRecording() as Boolean {
		if (activeRecorder != null) {
			return (activeRecorder as WorkoutRecording.Recorder).save();
		}
		return false;
	}

	function historySize() as Number {
		return trainingProgress.size();
	}

	function historyEntryAt(index as Number) as HistoryEntry? {
		return trainingProgress.entryAt(index);
	}

	// Returns true when the program-complete screen should show now.
	function changeHistoryRating(index as Number, rating as Number) as Boolean {
		var show = trainingProgress.changeRating(index, rating, currentDay());
		historyFocus = index;
		historyChanged();
		return show;
	}

	function deleteHistoryAt(index as Number) as Void {
		trainingProgress.deleteAt(index);
		historyFocus = HistoryFormat.focusAfterDelete(index, trainingProgress.size());
		historyChanged();
	}

	function deleteHistoryAtAndOlder(index as Number) as Void {
		trainingProgress.deleteAtAndOlder(index);
		historyFocus = HistoryFormat.focusAfterDelete(index, trainingProgress.size());
		historyChanged();
	}

	function clearHistory() as Void {
		trainingProgress.clear();
		historyFocus = HistoryFormat.addPosition(0);
		historyChanged();
	}

	// Returns true when the program-complete screen should show now.
	function addHistoryWorkout(date as CalendarDay, zeroBasedIndex as Number, rating as Number) as Boolean {
		var show = trainingProgress.addWorkout(date, zeroBasedIndex + 1, rating, currentDay());
		var added = trainingProgress.lastAddedIndex();
		if (added >= 0) {
			historyFocus = added;
		}
		historyChanged();
		return show;
	}

	function isTooOldForHistory(date as CalendarDay) as Boolean {
		return trainingProgress.isTooOldToAdd(date);
	}

	function historyChanged() as Void {
		historyVersion = historyVersion + 1;
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
