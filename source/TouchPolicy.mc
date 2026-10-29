import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

// Which input runs a screen's Start action, so a tap on a touch screen does
// not. A tap and the Start button both arrive as the Select behavior, so where
// taps are possible the action runs from the Start key (KEY_ENTER) instead.
// On the Venu, Venu D, D2 Air, and D2 Air X10, Start never reaches the Select
// behavior (monkey.jungle adds resources-tap-pause, which turns StartButton's
// "selects" off), so a tap is how the workout pauses and resumes there.
// UI-free, so it is unit tested with each combination.
class TouchPolicy {
	var touchScreen as Boolean;
	var startSelects as Boolean;

	function initialize(touchScreen as Boolean, startSelects as Boolean) {
		self.touchScreen = touchScreen;
		self.startSelects = startSelects;
	}

	// Without a touch screen, Select can only come from the Start button.
	function selectRunsAction() as Boolean {
		return !touchScreen && startSelects;
	}

	// Exactly one of Select and the Start key runs the action, so one press
	// never runs it twice.
	function startKeyRunsAction() as Boolean {
		return !selectRunsAction();
	}

	function tapPausesWorkout() as Boolean {
		return touchScreen && !startSelects;
	}
}

function deviceTouchPolicy() as TouchPolicy {
	var setting = Application.loadResource(Rez.JsonData.StartButton);
	var startSelects = !(setting instanceof Dictionary && setting["selects"] == false);
	return new TouchPolicy(System.getDeviceSettings().isTouchScreen, startSelects);
}
