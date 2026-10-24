import Toybox.Lang;
import Toybox.Test;

(:test)
function testScreenStack(logger as Test.Logger) as Boolean {
	logger.debug("screen stack");
	ScreenStack.atMainMenu();
	TestSupport.expectFalse(ScreenStack.shouldLeave(), "the main menu stays");
	ScreenStack.requestReturnToMain();
	TestSupport.expectTrue(ScreenStack.shouldLeave(), "a finished workout asks every screen above the menu to leave");
	ScreenStack.atMainMenu();
	TestSupport.expectFalse(ScreenStack.shouldLeave(), "arriving at the menu clears the request");
	return true;
}
