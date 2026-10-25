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
	ScreenStack.requestReturnToHistory();
	TestSupport.expectTrue(ScreenStack.shouldLeave(), "a History edit asks the screens above the list to leave");
	ScreenStack.atHistory();
	TestSupport.expectFalse(ScreenStack.shouldLeave(), "arriving at the History list clears it");
	ScreenStack.requestReturnToMain();
	ScreenStack.requestReturnToHistory();
	ScreenStack.atHistory();
	TestSupport.expectTrue(ScreenStack.shouldLeave(), "a return to the main menu passes through History");
	ScreenStack.atMainMenu();
	TestSupport.expectFalse(ScreenStack.shouldLeave(), "and stops at the menu");
	return true;
}
