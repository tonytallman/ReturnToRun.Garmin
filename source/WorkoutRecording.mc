import Toybox.Lang;

// Port for the device's activity recording. FitRecordingPort is the real one.
// Tests pass a fake so the lifecycle rules run without a FIT session.
class RecordingPort {
	function initialize() {
	}

	// Creates the session and turns on GPS and heart rate. Called once, before the first start.
	function open() as Void {
	}

	function start() as Void {
	}

	function stop() as Void {
	}

	function addLap() as Void {
	}

	// Saves or discards the session and turns GPS and heart rate back off.
	function save() as Void {
	}

	function discard() as Void {
	}
}

// The recording lifecycle for one workout. Each call is safe in any state:
// a call that does not apply does nothing, so the screens can call save
// without knowing whether the end-early prompt already saved.
module WorkoutRecording {
	const IDLE = 0;
	const RECORDING = 1;
	const STOPPED = 2;
	const SAVED = 3;
	const DISCARDED = 4;

	class Recorder {
		var state as Number;
		private var port as RecordingPort;

		function initialize(port as RecordingPort) {
			self.port = port;
			state = IDLE;
		}

		// Starts the first time, and resumes after pause.
		function start() as Boolean {
			if (state == IDLE) {
				port.open();
			} else if (state != STOPPED) {
				return false;
			}
			port.start();
			state = RECORDING;
			return true;
		}

		// Stops the activity timer. The session stays open for resume or save.
		function pause() as Boolean {
			if (state != RECORDING) {
				return false;
			}
			port.stop();
			state = STOPPED;
			return true;
		}

		function lap() as Boolean {
			if (state != RECORDING) {
				return false;
			}
			port.addLap();
			return true;
		}

		// Stops if needed and writes the FIT file. Only the first save does anything.
		function save() as Boolean {
			if (!isOpen()) {
				return false;
			}
			pause();
			port.save();
			state = SAVED;
			return true;
		}

		function discard() as Boolean {
			if (!isOpen()) {
				return false;
			}
			pause();
			port.discard();
			state = DISCARDED;
			return true;
		}

		// Started and not yet saved or discarded.
		function isOpen() as Boolean {
			return (state == RECORDING) || (state == STOPPED);
		}
	}
}
