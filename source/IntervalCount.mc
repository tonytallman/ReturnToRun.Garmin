import Toybox.Lang;

// Repeat label for a segment index, such as "1/8".
// Index 0 is warm-up. With walks, odd indexes are runs and the following even
// index is that run's walk, so both share (index + 1) / 2; the last repeat's
// walk is index repeatCount * 2, just before cool-down. Without walks, index N
// is run N. Warm-up and cool-down have no count.
module IntervalCount {
	function numberFor(segmentIndex as Number, repeatCount as Number, hasWalks as Boolean) as Number? {
		if ((repeatCount <= 0) || (segmentIndex <= 0)) {
			return null;
		}
		if (!hasWalks) {
			return (segmentIndex <= repeatCount) ? segmentIndex : null;
		}
		if (segmentIndex > (repeatCount * 2)) {
			return null;
		}
		return (segmentIndex + 1) / 2;
	}

	function labelFor(segmentIndex as Number, repeatCount as Number, hasWalks as Boolean) as String {
		var number = numberFor(segmentIndex, repeatCount, hasWalks);
		if (number == null) {
			return "";
		}
		var repeatNumber = number as Number;
		return repeatNumber.toString() + "/" + repeatCount.toString();
	}
}
