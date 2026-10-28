import Toybox.Lang;

// Text and layout rules for the History list. The words come from the caller
// (resources and the watch's own month names), so these rules are UI-free.
module HistoryFormat {
	// "Oct 24  #5  Good"
	function entryLabel(monthName as String, day as Number, workoutId as Number, ratingWord as String) as String {
		return shortDate(monthName, day) + "  #" + workoutId.toString() + "  " + ratingWord;
	}

	// "Oct 24", using the watch's localized month abbreviation.
	function shortDate(monthName as String, day as Number) as String {
		return monthName + " " + day.toString();
	}

	// The list is every entry, newest first, then Clear history, then Add workout.
	function clearPosition(entryCount as Number) as Number {
		return entryCount;
	}

	function addPosition(entryCount as Number) as Number {
		return entryCount + 1;
	}

	function itemCount(entryCount as Number) as Number {
		return entryCount + 2;
	}

	// Focus after the list is rebuilt: the requested item, kept inside the list.
	function clampFocus(requested as Number, entryCount as Number) as Number {
		if (requested < 0) {
			return 0;
		}
		var last = itemCount(entryCount) - 1;
		if (requested > last) {
			return last;
		}
		return requested;
	}

	// Whether build() should call setFocus. The first time the list is built
	// with the first item selected it does not: Menu2 starts there anyway, and on
	// watches with the white menu style (Venu, vivoactive 5 and similar) setFocus
	// scrolls the item to the top row, hiding the "History" title. When the list
	// is rebuilt the old focus may be anywhere, so it is always set.
	function shouldSetFocus(focus as Number, firstBuild as Boolean) as Boolean {
		return !(firstBuild && focus == 0);
	}

	// Focus after deleting entry index (or it and everything older): the entry
	// that took its place, or the last remaining entry, or Add workout when
	// history is empty.
	function focusAfterDelete(index as Number, remaining as Number) as Number {
		if (remaining <= 0) {
			return addPosition(0);
		}
		if (index >= remaining) {
			return remaining - 1;
		}
		return index;
	}
}
