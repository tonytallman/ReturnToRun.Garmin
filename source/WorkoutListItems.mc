import Toybox.Lang;

// Rules for the Run list's "Go to #1" row. The Add workout list never includes
// it. The row sits just above the recommended workout, so it is one scroll
// away, and only when #1 is not already nearby.
module WorkoutListItems {
	const FIRST_SHORTCUT = :goToFirst;
	// Shown when the recommended workout is #4 or later (0-based index 3).
	const MIN_RECOMMENDED_INDEX = 3;

	function includesFirstShortcut(recommendedIndex as Number) as Boolean {
		return recommendedIndex >= MIN_RECOMMENDED_INDEX;
	}

	// Menu item ids in order: each workout's 0-based index, with FIRST_SHORTCUT
	// inserted immediately after the recommended workout when the shortcut is on.
	function ids(count as Number, recommendedIndex as Number, includeFirstShortcut as Boolean) as Array {
		var items = [] as Array;
		var show = includeFirstShortcut && includesFirstShortcut(recommendedIndex);
		for (var index = 0; index < count; index++) {
			items.add(index);
			if (show && (index == recommendedIndex)) {
				items.add(FIRST_SHORTCUT);
			}
		}
		return items;
	}

	// Which menu row should be focused: the recommended workout. The shortcut
	// is inserted after it, so the focus index is just the clamped workout
	// index. Out-of-range values clamp to the first or last workout, matching
	// the list view.
	function focus(count as Number, recommendedIndex as Number) as Number {
		if (count <= 0) {
			return 0;
		}
		var index = recommendedIndex;
		if (index < 0) {
			index = 0;
		}
		if (index >= count) {
			index = count - 1;
		}
		return index;
	}

	// The real workout 1 row is always the first item; the shortcut is never
	// placed above it.
	function firstWorkoutRow() as Number {
		return 0;
	}
}
