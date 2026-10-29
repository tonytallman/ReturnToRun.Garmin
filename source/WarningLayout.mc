import Toybox.Lang;

// Where WarningView draws Continue and Cancel, and which of them a tap at a
// given height hits. Each action owns the band from halfway to the other
// action's center line, as wide again on its outer side; a tap above Continue's
// band (on the message) hits nothing. UI-free, so it is unit tested.
module WarningLayout {
	const ROW_NONE = 0;
	const ROW_CONTINUE = 1;
	const ROW_CANCEL = 2;

	function continueY(height as Number) as Number {
		return height * 70 / 100;
	}

	function cancelY(height as Number) as Number {
		return height * 84 / 100;
	}

	function rowAt(y as Number, height as Number) as Number {
		var top = continueY(height);
		var bottom = cancelY(height);
		var half = (bottom - top) / 2;
		if (y < top - half) {
			return ROW_NONE;
		}
		if (y < top + half) {
			return ROW_CONTINUE;
		}
		return ROW_CANCEL;
	}
}
