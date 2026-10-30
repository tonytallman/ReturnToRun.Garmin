import Toybox.Lang;
import Toybox.Test;

(:test)
function testTouchPolicyButtonsOnly(logger as Test.Logger) as Boolean {
	logger.debug("no touch screen: Select is the Start button");
	var policy = new TouchPolicy(false, true);
	TestSupport.expectTrue(policy.selectRunsAction(), "Select runs the action");
	TestSupport.expectFalse(policy.startKeyRunsAction(), "the key event does not run it again");
	TestSupport.expectFalse(policy.tapPausesWorkout(), "no taps");
	return true;
}

(:test)
function testTouchPolicyTouchScreen(logger as Test.Logger) as Boolean {
	logger.debug("touch screen: only the Start key runs the action");
	var policy = new TouchPolicy(true, true);
	TestSupport.expectFalse(policy.selectRunsAction(), "a tap's Select does nothing");
	TestSupport.expectTrue(policy.startKeyRunsAction(), "the Start key runs it");
	TestSupport.expectFalse(policy.tapPausesWorkout(), "taps are ignored");
	return true;
}

(:test)
function testTouchPolicyStartMissesSelect(logger as Test.Logger) as Boolean {
	logger.debug("Venu: Start never reaches Select, so a tap pauses");
	var policy = new TouchPolicy(true, false);
	TestSupport.expectFalse(policy.selectRunsAction(), "Select is only a tap");
	TestSupport.expectTrue(policy.startKeyRunsAction(), "the Start key runs it if it arrives");
	TestSupport.expectTrue(policy.tapPausesWorkout(), "a tap pauses and resumes");

	var touchOff = new TouchPolicy(false, false);
	TestSupport.expectFalse(touchOff.selectRunsAction(), "touch turned off: still not Select");
	TestSupport.expectTrue(touchOff.startKeyRunsAction(), "touch turned off: the Start key");
	TestSupport.expectFalse(touchOff.tapPausesWorkout(), "touch turned off: no taps");
	return true;
}
