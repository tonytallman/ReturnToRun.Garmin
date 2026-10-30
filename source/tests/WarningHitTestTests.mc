import Toybox.Lang;
import Toybox.Test;

(:test)
function testWarningRowCenters(logger as Test.Logger) as Boolean {
	logger.debug("Continue and Cancel center lines");
	TestSupport.expectEqual(317, WarningLayout.continueY(454), "Continue at 70%");
	TestSupport.expectEqual(381, WarningLayout.cancelY(454), "Cancel at 84%");
	TestSupport.expectEqual(168, WarningLayout.continueY(240), "Continue on a 240 screen");
	TestSupport.expectEqual(201, WarningLayout.cancelY(240), "Cancel on a 240 screen");
	return true;
}

(:test)
function testWarningHitTest(logger as Test.Logger) as Boolean {
	logger.debug("which action a tap hits");
	// 454 high: Continue at 317, Cancel at 381, half the gap is 32.
	TestSupport.expectEqual(WarningLayout.ROW_NONE, WarningLayout.rowAt(0, 454), "top edge");
	TestSupport.expectEqual(WarningLayout.ROW_NONE, WarningLayout.rowAt(168, 454), "the message");
	TestSupport.expectEqual(WarningLayout.ROW_NONE, WarningLayout.rowAt(284, 454), "just above Continue");
	TestSupport.expectEqual(WarningLayout.ROW_CONTINUE, WarningLayout.rowAt(285, 454), "top of Continue");
	TestSupport.expectEqual(WarningLayout.ROW_CONTINUE, WarningLayout.rowAt(317, 454), "on Continue");
	TestSupport.expectEqual(WarningLayout.ROW_CONTINUE, WarningLayout.rowAt(348, 454), "bottom of Continue");
	TestSupport.expectEqual(WarningLayout.ROW_CANCEL, WarningLayout.rowAt(349, 454), "top of Cancel");
	TestSupport.expectEqual(WarningLayout.ROW_CANCEL, WarningLayout.rowAt(381, 454), "on Cancel");
	TestSupport.expectEqual(WarningLayout.ROW_CANCEL, WarningLayout.rowAt(453, 454), "bottom edge");

	// 240 high: Continue at 168, Cancel at 201, half the gap is 16.
	TestSupport.expectEqual(WarningLayout.ROW_NONE, WarningLayout.rowAt(151, 240), "small: above Continue");
	TestSupport.expectEqual(WarningLayout.ROW_CONTINUE, WarningLayout.rowAt(152, 240), "small: Continue");
	TestSupport.expectEqual(WarningLayout.ROW_CONTINUE, WarningLayout.rowAt(183, 240), "small: bottom of Continue");
	TestSupport.expectEqual(WarningLayout.ROW_CANCEL, WarningLayout.rowAt(184, 240), "small: Cancel");
	return true;
}
