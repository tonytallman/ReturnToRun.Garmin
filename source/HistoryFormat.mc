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

	// Watches with little memory (resources-low-memory) show the history a page
	// at a time, with Newer workouts first on every page but the first and Older
	// workouts after the entries when there are more. A page size of 0 shows every
	// entry on one page. Focus is kept as a position in the whole list (entries,
	// then Clear history, then Add workout), and the page follows the focused entry.
	function lastPage(entryCount as Number, pageSize as Number) as Number {
		if ((pageSize <= 0) || (entryCount <= 0)) {
			return 0;
		}
		return (entryCount - 1) / pageSize;
	}

	// The page to show for a focus: the focused entry's page, or for Clear
	// history and Add workout the current page, kept inside the list.
	function pageFor(focus as Number, entryCount as Number, pageSize as Number, currentPage as Number) as Number {
		if (pageSize <= 0) {
			return 0;
		}
		if ((focus >= 0) && (focus < entryCount)) {
			return focus / pageSize;
		}
		var last = lastPage(entryCount, pageSize);
		if (currentPage > last) {
			return last;
		}
		if (currentPage < 0) {
			return 0;
		}
		return currentPage;
	}

	function pageFirst(page as Number, pageSize as Number) as Number {
		if (pageSize <= 0) {
			return 0;
		}
		return page * pageSize;
	}

	function pageEnd(page as Number, entryCount as Number, pageSize as Number) as Number {
		if (pageSize <= 0) {
			return entryCount;
		}
		var end = (page + 1) * pageSize;
		if (end < entryCount) {
			return end;
		}
		return entryCount;
	}

	function hasNewer(page as Number) as Boolean {
		return page > 0;
	}

	function hasOlder(page as Number, entryCount as Number, pageSize as Number) as Boolean {
		return pageEnd(page, entryCount, pageSize) < entryCount;
	}

	function pageItemCount(page as Number, entryCount as Number, pageSize as Number) as Number {
		var count = pageEnd(page, entryCount, pageSize) - pageFirst(page, pageSize) + 2;
		if (hasNewer(page)) {
			count += 1;
		}
		if (hasOlder(page, entryCount, pageSize)) {
			count += 1;
		}
		return count;
	}

	// Where a focus (a position in the whole list) sits on the page shown.
	function pagePosition(focus as Number, page as Number, entryCount as Number, pageSize as Number) as Number {
		var first = pageFirst(page, pageSize);
		var newer = hasNewer(page) ? 1 : 0;
		if (focus < entryCount) {
			return newer + focus - first;
		}
		var older = hasOlder(page, entryCount, pageSize) ? 1 : 0;
		return newer + pageEnd(page, entryCount, pageSize) - first + older + focus - entryCount;
	}

	// Focus after Older workouts (step 1) or Newer workouts (step -1): the
	// entry next to the one before the turn, so the first entry of the older
	// page or the last entry of the newer page.
	function focusAfterTurn(page as Number, step as Number, entryCount as Number, pageSize as Number) as Number {
		var target = page + step;
		if (step > 0) {
			return pageFirst(target, pageSize);
		}
		return pageEnd(target, entryCount, pageSize) - 1;
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
