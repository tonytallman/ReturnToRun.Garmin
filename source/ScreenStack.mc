import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Views above the main menu pop themselves after a workout ends, until the
// main menu is the one on screen. History screens do the same to get back to
// the History list after an edit. Popping from onShow is deferred by a timer
// so each transition finishes before the next view leaves.
module ScreenStack {
	const STAY = 0;
	const TO_HISTORY = 1;
	const TO_MAIN = 2;

	var target as Number = STAY;

	function requestReturnToMain() as Void {
		target = TO_MAIN;
	}

	// A return to the main menu already under way is not shortened.
	function requestReturnToHistory() as Void {
		if (target != TO_MAIN) {
			target = TO_HISTORY;
		}
	}

	function atMainMenu() as Void {
		target = STAY;
	}

	function atHistory() as Void {
		if (target == TO_HISTORY) {
			target = STAY;
		}
	}

	function shouldLeave() as Boolean {
		return target != STAY;
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
