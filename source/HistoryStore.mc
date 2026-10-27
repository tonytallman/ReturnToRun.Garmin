import Toybox.Application.Storage;
import Toybox.Lang;

// Newest-first history. 100 entries is the cap: each entry is three integers in one
// flat array, and Application.Storage limits a single value to 32 KB (the total store
// on older devices is smaller still). 100 triples covers the 40-workout program more
// than twice, including back-offs and manual edits, while staying far under that limit.
// A newer entry that overflows the cap drops the oldest ones. An entry that would
// sort at or beyond the cap is rejected and the store is left unchanged.
const HISTORY_ENTRY_CAP = 100;
const HISTORY_STORAGE_KEY = "history";
const PROGRAM_COMPLETE_SHOWN_KEY = "programCompleteShown";

class HistoryStore {
	// Values per entry in the flat array: date number (yyyymmdd), workout id, rating.
	static const FIELDS = 3;

	private var gateway as StorageGateway;
	// The history kept as the same flat array that is stored, newest first, so a
	// full history is one array of numbers rather than an object per entry.
	// entryAt() builds a HistoryEntry on request; callers hold it only briefly.
	private var packed as Array<Number>;
	private var entryCap as Number;
	private var _maxWorkoutId as Number;
	private var programCompleteShown as Boolean;
	// Position of the entry from the latest successful add, or -1.
	var lastAddedIndex as Number;

	function initialize(gateway as StorageGateway, entryCap as Number, maxWorkoutId as Number) {
		self.gateway = gateway;
		self.packed = [] as Array<Number>;
		self.entryCap = entryCap;
		self._maxWorkoutId = maxWorkoutId;
		self.programCompleteShown = false;
		self.lastAddedIndex = -1;
	}

	// The stored format is the one earlier versions wrote, so history they saved
	// loads as it is. Entries that are not valid are skipped. When every stored
	// value is already a valid whole Number, the loaded array is kept rather than
	// copied; otherwise the valid entries are copied, as Numbers, into a new one.
	function load() as Void {
		packed = [] as Array<Number>;
		programCompleteShown = false;
		var shown = gateway.get(PROGRAM_COMPLETE_SHOWN_KEY);
		if (shown instanceof Boolean) {
			programCompleteShown = shown as Boolean;
		}
		var raw = gateway.get(HISTORY_STORAGE_KEY);
		if (!(raw instanceof Array)) {
			return;
		}
		var flat = raw as Array;
		var count = flat.size() / FIELDS;
		var keepAsIs = (flat.size() == count * FIELDS);
		for (var i = 0; keepAsIs && (i < count); i++) {
			var base = i * FIELDS;
			keepAsIs = (flat[base] instanceof Number) && (flat[base + 1] instanceof Number) && (flat[base + 2] instanceof Number)
				&& isValid(flat[base] as Number, flat[base + 1] as Number, flat[base + 2] as Number);
		}
		if (keepAsIs) {
			packed = flat as Array<Number>;
		} else {
			var cleaned = [] as Array<Number>;
			for (var i = 0; i < count; i++) {
				var base = i * FIELDS;
				var dateNumber = asNumber(flat[base] as Object?);
				var workoutId = asNumber(flat[base + 1] as Object?);
				var rating = asNumber(flat[base + 2] as Object?);
				if ((dateNumber != null) && (workoutId != null) && (rating != null) && isValid(dateNumber as Number, workoutId as Number, rating as Number)) {
					cleaned.add(dateNumber as Number);
					cleaned.add(workoutId as Number);
					cleaned.add(rating as Number);
				}
			}
			packed = cleaned;
		}
		trimToCap();
	}

	// One stored entry: a real calendar date, a workout id of at least 1, and a known rating.
	private function isValid(dateNumber as Number, workoutId as Number, rating as Number) as Boolean {
		return (CalendarDay.fromNumber(dateNumber) != null) && (workoutId >= FIRST_WORKOUT_ID) && Rating.isValid(rating);
	}

	function save() as Void {
		gateway.set(HISTORY_STORAGE_KEY, packed as Array<Storage.ValueType>);
		gateway.set(PROGRAM_COMPLETE_SHOWN_KEY, programCompleteShown);
	}

	function maxWorkoutId() as Number {
		return _maxWorkoutId;
	}

	function size() as Number {
		return packed.size() / FIELDS;
	}

	function entryAt(index as Number) as HistoryEntry? {
		if ((index < 0) || (index >= size())) {
			return null;
		}
		var base = index * FIELDS;
		var date = CalendarDay.fromNumber(packed[base]);
		if (date == null) {
			return null;
		}
		return new HistoryEntry(date as CalendarDay, packed[base + 1], packed[base + 2]);
	}

	function latest() as HistoryEntry? {
		return entryAt(0);
	}

	function isProgramCompleteShown() as Boolean {
		return programCompleteShown;
	}

	function setProgramCompleteShown(shown as Boolean) as Void {
		programCompleteShown = shown;
		save();
	}

	// Inserts by date, newest first. A new entry on a day that already has entries
	// is placed ahead of those older same-day entries, and every one of them is kept.
	// An entry that would be the oldest one past the cap is rejected and the store is unchanged.
	function add(date as CalendarDay, workoutId as Number, rating as Number) as Boolean {
		lastAddedIndex = -1;
		if ((workoutId < FIRST_WORKOUT_ID) || (workoutId > _maxWorkoutId) || !Rating.isValid(rating)) {
			return false;
		}
		var insertionIndex = insertionIndexFor(date);
		if (insertionIndex >= entryCap) {
			return false;
		}
		var base = insertionIndex * FIELDS;
		var updated = packed.slice(0, base);
		updated.add(date.toNumber());
		updated.add(workoutId);
		updated.add(rating);
		updated.addAll(packed.slice(base, null));
		packed = updated;
		trimToCap();
		lastAddedIndex = insertionIndex;
		save();
		return true;
	}

	// Where an entry on this date would go: ahead of the first entry on the
	// same day or older, or at the end.
	function insertionIndexFor(date as CalendarDay) as Number {
		var dateNumber = date.toNumber();
		var count = size();
		for (var i = 0; i < count; i++) {
			if (packed[i * FIELDS] <= dateNumber) {
				return i;
			}
		}
		return count;
	}

	// True when an entry on this date would be the oldest one past the cap, so
	// add() would reject it: the history is full and every entry is newer.
	function isTooOldToAdd(date as CalendarDay) as Boolean {
		return insertionIndexFor(date) >= entryCap;
	}

	function setRating(index as Number, rating as Number) as Boolean {
		if ((index < 0) || (index >= size()) || !Rating.isValid(rating)) {
			return false;
		}
		packed[(index * FIELDS) + 2] = rating;
		save();
		return true;
	}

	function deleteAt(index as Number) as Boolean {
		if ((index < 0) || (index >= size())) {
			return false;
		}
		var base = index * FIELDS;
		var updated = packed.slice(0, base);
		updated.addAll(packed.slice(base + FIELDS, null));
		packed = updated;
		save();
		return true;
	}

	// Newest-first, so this entry and everything after it is this entry and all older ones.
	// Same-day entries that sort after it were added earlier, so they are removed too.
	function deleteAtAndOlder(index as Number) as Boolean {
		if ((index < 0) || (index >= size())) {
			return false;
		}
		packed = packed.slice(0, index * FIELDS);
		save();
		return true;
	}

	function clear() as Void {
		packed = [] as Array<Number>;
		save();
	}

	function trimToCap() as Void {
		if (size() > entryCap) {
			packed = packed.slice(0, entryCap * FIELDS);
		}
	}
}
