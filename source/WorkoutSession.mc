import Toybox.Lang;

// The in-progress workout from start to rating. The timer and countdown tones
// run only while the state is RUNNING.
// Back while running pauses. Back while paused asks to end, with Resume, Save,
// and Discard. Save and finishing the last segment both lead to the rating.
// Each answer applies once, so a double press cannot save or log twice.
module WorkoutSession {
	const RUNNING = 1;
	const PAUSED = 2;
	const CONFIRMING_END = 3;
	const RATING = 4;
	const FINISHED = 5;

	const NONE = 0;
	const PAUSE = 10;
	const RESUME = 11;
	const ASK_TO_END = 12;
	const DISCARD = 13;
	const SAVE = 14;
	const COMPLETE = 15;
	const KEEP_PAUSED = 16;
	const LOG = 17;

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

		// Resume on the end prompt.
		function onResumeFromEnd() as Number {
			return answer(RUNNING, RESUME);
		}

		// Back on the end prompt.
		function onDeclineEnd() as Number {
			return answer(PAUSED, KEEP_PAUSED);
		}

		// Save on the end prompt. The run is saved and then rated.
		function onSaveEarly() as Number {
			return answer(RATING, SAVE);
		}

		// Discard on the end prompt. Nothing is saved or logged.
		function onDiscard() as Number {
			return answer(FINISHED, DISCARD);
		}

		// The last segment finished.
		function onCompleted() as Number {
			if ((state != RUNNING) && (state != PAUSED)) {
				return NONE;
			}
			state = RATING;
			return COMPLETE;
		}

		// A rating was chosen.
		function onRated() as Number {
			if (state != RATING) {
				return NONE;
			}
			state = FINISHED;
			return LOG;
		}

		private function answer(next as Number, action as Number) as Number {
			if (state != CONFIRMING_END) {
				return NONE;
			}
			state = next;
			return action;
		}
	}
}
