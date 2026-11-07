import Toybox.Application.Storage;
import Toybox.Lang;

// Which workout is being run, and on what day. Set when the recording starts
// and cleared once the workout is rated or discarded. If the watch restarts
// before then, the next launch finds it and asks how the run felt.
class InProgressNote {
	static const STORAGE_KEY = "inProgress";

	private var gateway as StorageGateway;

	function initialize(gateway as StorageGateway) {
		self.gateway = gateway;
	}

	function set(workoutId as Number, date as CalendarDay) as Void {
		gateway.set(STORAGE_KEY, [workoutId, date.toNumber()] as Array<Storage.ValueType>);
	}

	function clear() as Void {
		if (gateway.get(STORAGE_KEY) != null) {
			gateway.remove(STORAGE_KEY);
		}
	}

	// The unfinished workout as a history entry with no rating, or null.
	// Anything stored that does not read as one is treated as none.
	function read() as HistoryEntry? {
		var stored = gateway.get(STORAGE_KEY);
		if (!(stored instanceof Array) || (stored as Array).size() != 2) {
			return null;
		}
		var pair = stored as Array;
		if (!(pair[0] instanceof Number) || !(pair[1] instanceof Number)) {
			return null;
		}
		var date = CalendarDay.fromNumber(pair[1] as Number);
		if (date == null) {
			return null;
		}
		return new HistoryEntry(date as CalendarDay, pair[0] as Number, 0);
	}
}
