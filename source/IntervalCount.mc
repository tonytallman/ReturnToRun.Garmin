import Toybox.Lang;

// Repeat label for a segment index, such as "1/8".
// Index 0 is warm-up. Odd indexes are runs and the following even index is that
// run's walk, so both share (index + 1) / 2. The last index (repeatCount * 2)
// is cool-down, the final walk, and has no count.
module IntervalCount {
	function numberFor(segmentIndex as Number, repeatCount as Number) as Number? {
		if ((repeatCount <= 0) || (segmentIndex <= 0)) {
			return null;
		}
		if (segmentIndex >= (repeatCount * 2)) {
			return null;
		}
		return (segmentIndex + 1) / 2;
	}

	function labelFor(segmentIndex as Number, repeatCount as Number) as String {
		var number = numberFor(segmentIndex, repeatCount);
		if (number == null) {
			return "";
		}
		var repeatNumber = number as Number;
		return repeatNumber.toString() + "/" + repeatCount.toString();
	}
}
