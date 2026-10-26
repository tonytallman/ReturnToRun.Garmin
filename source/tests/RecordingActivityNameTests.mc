import Toybox.Lang;
import Toybox.Test;

(:test)
function testRecordingActivityName(logger as Test.Logger) as Boolean {
	logger.debug("recording activity name");
	TestSupport.expectEqual("Return to Run #1", RecordingActivityName.forWorkout(1), "workout 1");
	TestSupport.expectEqual("Return to Run #40", RecordingActivityName.forWorkout(40), "longest id");
	TestSupport.expectTrue(RecordingActivityName.forWorkout(40).length() <= RecordingActivityName.MAX_LENGTH,
		"fits the FIT name limit");
	return true;
}
