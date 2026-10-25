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
	private var gateway as StorageGateway;
	private var entries as Array<HistoryEntry>;
	private var entryCap as Number;
	private var _maxWorkoutId as Number;
	private var programCompleteShown as Boolean;
	// Position of the entry from the latest successful add, or -1.
	var lastAddedIndex as Number;

	function initialize(gateway as StorageGateway, entryCap as Number, maxWorkoutId as Number) {
		self.gateway = gateway;
		self.entries = [] as Array<HistoryEntry>;
		self.entryCap = entryCap;
		self._maxWorkoutId = maxWorkoutId;
		self.programCompleteShown = false;
		self.lastAddedIndex = -1;
	}

	function load() as Void {
		entries = [] as Array<HistoryEntry>;
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
		var count = flat.size() / 3;
		for (var i = 0; i < count; i++) {
			var base = i * 3;
			var dateNumber = asNumber(flat[base] as Object?);
			var workoutId = asNumber(flat[base + 1] as Object?);
			var rating = asNumber(flat[base + 2] as Object?);
			if ((dateNumber == null) || (workoutId == null) || (rating == null)) {
				continue;
			}
			var date = CalendarDay.fromNumber(dateNumber as Number);
			if ((date == null) || ((workoutId as Number) < FIRST_WORKOUT_ID) || !Rating.isValid(rating as Number)) {
				continue;
			}
			entries.add(new HistoryEntry(date as CalendarDay, workoutId as Number, rating as Number));
		}
		trimToCap();
	}

	function save() as Void {
		var flat = [] as Array<Storage.ValueType>;
		for (var i = 0; i < entries.size(); i++) {
			var entry = entries[i] as HistoryEntry;
			var dateValue = (entry.date.toNumber()) as Storage.ValueType;
			var workoutValue = (entry.workoutId) as Storage.ValueType;
			var ratingValue = (entry.rating) as Storage.ValueType;
			flat.add(dateValue);
			flat.add(workoutValue);
			flat.add(ratingValue);
		}
		gateway.set(HISTORY_STORAGE_KEY, flat);
		gateway.set(PROGRAM_COMPLETE_SHOWN_KEY, programCompleteShown);
	}

	function maxWorkoutId() as Number {
		return _maxWorkoutId;
	}

	function size() as Number {
		return entries.size();
	}

	function entryAt(index as Number) as HistoryEntry? {
		if ((index < 0) || (index >= entries.size())) {
			return null;
		}
		return entries[index] as HistoryEntry;
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
		var insertionIndex = entries.size();
		for (var i = 0; i < entries.size(); i++) {
			var existing = entries[i] as HistoryEntry;
			if (existing.date.compare(date) <= 0) {
				insertionIndex = i;
				break;
			}
		}
		if (insertionIndex >= entryCap) {
			return false;
		}
		var entry = new HistoryEntry(date, workoutId, rating);
		var updated = [] as Array<HistoryEntry>;
		for (var index = 0; index < entries.size(); index++) {
			if (index == insertionIndex) {
				updated.add(entry);
			}
			updated.add(entries[index] as HistoryEntry);
		}
		if (insertionIndex == entries.size()) {
			updated.add(entry);
		}
		entries = updated;
		trimToCap();
		lastAddedIndex = insertionIndex;
		save();
		return true;
	}

	function setRating(index as Number, rating as Number) as Boolean {
		var entry = entryAt(index);
		if ((entry == null) || !Rating.isValid(rating)) {
			return false;
		}
		(entry as HistoryEntry).rating = rating;
		save();
		return true;
	}

	function deleteAt(index as Number) as Boolean {
		if ((index < 0) || (index >= entries.size())) {
			return false;
		}
		var updated = [] as Array<HistoryEntry>;
		for (var i = 0; i < entries.size(); i++) {
			if (i != index) {
				updated.add(entries[i] as HistoryEntry);
			}
		}
		entries = updated;
		save();
		return true;
	}

	// Newest-first, so this entry and everything after it is this entry and all older ones.
	// Same-day entries that sort after it were added earlier, so they are removed too.
	function deleteAtAndOlder(index as Number) as Boolean {
		if ((index < 0) || (index >= entries.size())) {
			return false;
		}
		var updated = [] as Array<HistoryEntry>;
		for (var i = 0; i < index; i++) {
			updated.add(entries[i] as HistoryEntry);
		}
		entries = updated;
		save();
		return true;
	}

	function clear() as Void {
		entries = [] as Array<HistoryEntry>;
		save();
	}

	function trimToCap() as Void {
		if (entries.size() > entryCap) {
			entries = entries.slice(0, entryCap) as Array<HistoryEntry>;
		}
	}
}
