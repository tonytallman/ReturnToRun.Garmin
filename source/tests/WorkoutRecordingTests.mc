import Toybox.Lang;
import Toybox.Test;

// Records each port call as one letter: o open, s start, p stop, l lap, v save, d discard.
(:test)
class FakeRecordingPort extends RecordingPort {
	var calls as String;

	function initialize() {
		RecordingPort.initialize();
		calls = "";
	}

	function open() as Void {
		calls = calls + "o";
	}

	function start() as Void {
		calls = calls + "s";
	}

	function stop() as Void {
		calls = calls + "p";
	}

	function addLap() as Void {
		calls = calls + "l";
	}

	function save() as Void {
		calls = calls + "v";
	}

	function discard() as Void {
		calls = calls + "d";
	}
}

(:test)
function testRecordingSaveAfterCompletion(logger as Test.Logger) as Boolean {
	logger.debug("recording saved after the last segment");
	var port = new FakeRecordingPort();
	var recorder = new WorkoutRecording.Recorder(port);
	TestSupport.expectFalse(recorder.isOpen(), "not open before start");
	TestSupport.expectFalse(recorder.lap(), "no lap before start");
	TestSupport.expectFalse(recorder.save(), "nothing to save before start");
	TestSupport.expectTrue(recorder.start(), "start");
	TestSupport.expectFalse(recorder.start(), "start twice");
	TestSupport.expectTrue(recorder.lap(), "lap while recording");
	TestSupport.expectTrue(recorder.pause(), "pause");
	TestSupport.expectFalse(recorder.pause(), "pause twice");
	TestSupport.expectFalse(recorder.lap(), "no lap while paused");
	TestSupport.expectTrue(recorder.start(), "resume");
	TestSupport.expectTrue(recorder.pause(), "the last segment stops the timer");
	TestSupport.expectTrue(recorder.isOpen(), "stopped and waiting for the rating");
	TestSupport.expectTrue(recorder.save(), "rating saves");
	TestSupport.expectEqual(WorkoutRecording.SAVED, recorder.state, "saved");
	TestSupport.expectFalse(recorder.save(), "a second save does nothing");
	TestSupport.expectFalse(recorder.discard(), "a saved run cannot be discarded");
	TestSupport.expectFalse(recorder.start(), "a saved run cannot restart");
	TestSupport.expectEqual("oslpspv", port.calls, "port calls");
	return true;
}

(:test)
function testRecordingEndEarly(logger as Test.Logger) as Boolean {
	logger.debug("recording ended early");
	var savedPort = new FakeRecordingPort();
	var saved = new WorkoutRecording.Recorder(savedPort);
	saved.start();
	TestSupport.expectTrue(saved.save(), "save while recording");
	TestSupport.expectEqual("ospv", savedPort.calls, "save stops the timer first");
	TestSupport.expectFalse(saved.save(), "the rating screen's save does nothing after an early save");
	TestSupport.expectEqual("ospv", savedPort.calls, "no second save");

	var discardedPort = new FakeRecordingPort();
	var discarded = new WorkoutRecording.Recorder(discardedPort);
	discarded.start();
	discarded.pause();
	TestSupport.expectTrue(discarded.discard(), "discard while paused");
	TestSupport.expectEqual(WorkoutRecording.DISCARDED, discarded.state, "discarded");
	TestSupport.expectFalse(discarded.isOpen(), "closed");
	TestSupport.expectFalse(discarded.save(), "a discarded run cannot be saved");
	TestSupport.expectEqual("ospd", discardedPort.calls, "port calls");

	var neverStarted = new WorkoutRecording.Recorder(new FakeRecordingPort());
	TestSupport.expectFalse(neverStarted.discard(), "nothing to discard");
	return true;
}
