import Toybox.Lang;
import Toybox.Test;

(:test)
module InProgressTestSupport {
	function services(gateway as MemoryStorageGateway) as AppServices {
		var program = WorkoutProgram.load();
		var store = new HistoryStore(gateway, HISTORY_ENTRY_CAP, program.maxId());
		return new AppServices(program, new Progress(store), new Breadcrumbs(), new InProgressNote(gateway));
	}
}

(:test)
function testInProgressNoteRoundTrip(logger as Test.Logger) as Boolean {
	var note = new InProgressNote(new MemoryStorageGateway());
	TestSupport.expectNull(note.read(), "empty at first");
	note.set(6, new CalendarDay(2026, 11, 8));
	var read = note.read() as HistoryEntry;
	TestSupport.expectEqual(6, read.workoutId, "workout id");
	TestSupport.expectEqual(20261108, read.date.toNumber(), "day");
	note.clear();
	TestSupport.expectNull(note.read(), "cleared");
	return true;
}

(:test)
function testInProgressBadStorage(logger as Test.Logger) as Boolean {
	var gateway = new MemoryStorageGateway();
	var note = new InProgressNote(gateway);
	gateway.set(InProgressNote.STORAGE_KEY, 5);
	TestSupport.expectNull(note.read(), "a number is not a note");
	gateway.set(InProgressNote.STORAGE_KEY, [6, 20261399] as Array<Number>);
	TestSupport.expectNull(note.read(), "a bad day is not a note");
	return true;
}

(:test)
function testUnfinishedWorkoutLogged(logger as Test.Logger) as Boolean {
	var gateway = new MemoryStorageGateway();
	var services = InProgressTestSupport.services(gateway);
	TestSupport.expectNull(services.unfinishedWorkout(), "none without a note");
	services.inProgress.set(5, new CalendarDay(2026, 11, 5));
	var entry = services.unfinishedWorkout() as HistoryEntry;
	TestSupport.expectEqual(5, entry.workoutId, "found workout 5");
	services.logWorkoutOn(entry.date, entry.workoutId, 2);
	TestSupport.expectEqual(1, services.historySize(), "logged once");
	var logged = services.historyEntryAt(0) as HistoryEntry;
	TestSupport.expectEqual(20261105, logged.date.toNumber(), "on the day it was run");
	TestSupport.expectNull(services.unfinishedWorkout(), "note cleared after rating");
	return true;
}

(:test)
function testUnfinishedWorkoutAlreadyInHistory(logger as Test.Logger) as Boolean {
	var gateway = new MemoryStorageGateway();
	var services = InProgressTestSupport.services(gateway);
	services.logWorkoutOn(new CalendarDay(2026, 11, 5), 5, 2);
	services.inProgress.set(5, new CalendarDay(2026, 11, 5));
	TestSupport.expectNull(services.unfinishedWorkout(), "already in history, so not asked again");
	TestSupport.expectNull(services.inProgress.read(), "and the note is cleared");
	TestSupport.expectEqual(1, services.historySize(), "history unchanged");
	return true;
}
