import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Views above the main menu pop themselves after a workout ends, until the
// main menu is the one on screen. Popping from onShow is deferred by a timer
// so each transition finishes before the next view leaves.
module ScreenStack {
	var returnToMain as Boolean = false;

	function requestReturnToMain() as Void {
		returnToMain = true;
	}

	function atMainMenu() as Void {
		returnToMain = false;
	}

	function shouldLeave() as Boolean {
		return returnToMain;
	}
}

class LeaveTimer {
	var timer as Timer.Timer?;
	var leaving as Boolean;

	function initialize() {
		leaving = false;
	}

	function schedule() as Boolean {
		if (!ScreenStack.shouldLeave() || leaving) {
			return false;
		}
		leaving = true;
		var started = new Timer.Timer();
		timer = started;
		started.start(method(:pop), 100, false);
		return true;
	}

	function pop() as Void {
		if (!ScreenStack.shouldLeave()) {
			return;
		}
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
	}
}
