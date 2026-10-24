import Toybox.Lang;

// Pause, resume, and confirm-to-end for an in-progress workout.
// The timer and countdown tones run only while the state is RUNNING.
// Back while running pauses. Back while paused asks to end. Ending is DISCARD.
module WorkoutSession {
	const RUNNING = 1;
	const PAUSED = 2;
	const CONFIRMING_END = 3;
	const FINISHED = 4;

	const NONE = 0;
	const PAUSE = 10;
	const RESUME = 11;
	const ASK_TO_END = 12;
	const DISCARD = 13;

	class Machine {
		var state as Number;

		function initialize() {
			state = RUNNING;
		}

		function isTiming() as Boolean {
			return state == RUNNING;
		}

		function showsPaused() as Boolean {
			return (state == PAUSED) || (state == CONFIRMING_END);
		}

		function onSelect() as Number {
			if (state == RUNNING) {
				state = PAUSED;
				return PAUSE;
			}
			if (state == PAUSED) {
				state = RUNNING;
				return RESUME;
			}
			return NONE;
		}

		function onBack() as Number {
			if (state == RUNNING) {
				state = PAUSED;
				return PAUSE;
			}
			if (state == PAUSED) {
				state = CONFIRMING_END;
				return ASK_TO_END;
			}
			return NONE;
		}

		function onConfirmEnd() as Number {
			if (state != CONFIRMING_END) {
				return NONE;
			}
			state = FINISHED;
			return DISCARD;
		}

		function onDeclineEnd() as Number {
			if (state != CONFIRMING_END) {
				return NONE;
			}
			state = PAUSED;
			return NONE;
		}

		function onCompleted() as Void {
			state = FINISHED;
		}
	}
}
