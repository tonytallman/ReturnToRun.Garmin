import Toybox.Lang;
import Toybox.WatchUi;

// Runs onStartAction from the Start button only, as TouchPolicy decides,
// whichever of Select and the key event the device delivers first.
class StartActionDelegate extends WatchUi.BehaviorDelegate {
	var touchPolicy as TouchPolicy;

	function initialize(touchPolicy as TouchPolicy) {
		BehaviorDelegate.initialize();
		self.touchPolicy = touchPolicy;
	}

	function onStartAction() as Void {
	}

	// Returning false lets a tap go on to onTap, and Start to onKey.
	function onSelect() as Boolean {
		if (!touchPolicy.selectRunsAction()) {
			return false;
		}
		onStartAction();
		return true;
	}

	function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
		if (keyEvent.getKey() != WatchUi.KEY_ENTER || !touchPolicy.startKeyRunsAction()) {
			return false;
		}
		onStartAction();
		return true;
	}
}
