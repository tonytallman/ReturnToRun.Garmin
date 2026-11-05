import Toybox.Lang;
import Toybox.Timer;

// The three-pulse workout-complete vibration as [duty cycle, milliseconds] steps.
// Attention plays it; RatingHandoff waits this long before the rating screen.
module CompleteVibration {
	const MARGIN_MS = 100;

	function steps() as Array<Array<Number> > {
		return [[100, 500], [0, 250], [100, 500], [0, 250], [100, 500]] as Array<Array<Number> >;
	}

	function durationMs() as Number {
		var total = 0;
		var all = steps();
		for (var index = 0; index < all.size(); index++) {
			total += all[index][1];
		}
		return total;
	}

	// How long after the vibration starts the rating screen slides in.
	function ratingDelayMs() as Number {
		return durationMs() + MARGIN_MS;
	}
}

// Runs one callback once after a delay. TimerScheduler is the real one; tests
// fire the callback by hand.
class OneShotScheduler {
	function initialize() {
	}

	function schedule(delayMs as Number, callback as Method() as Void) as Void {
	}

	function cancel() as Void {
	}
}

class TimerScheduler extends OneShotScheduler {
	private var timer as Timer.Timer?;

	function initialize() {
		OneShotScheduler.initialize();
	}

	function schedule(delayMs as Number, callback as Method() as Void) as Void {
		cancel();
		var created = new Timer.Timer();
		timer = created;
		created.start(callback, delayMs, false);
	}

	function cancel() as Void {
		if (timer != null) {
			(timer as Timer.Timer).stop();
			timer = null;
		}
	}
}

// What the handoff asks of the screen: switch to the rating view, and redraw.
class RatingScreenPort {
	function initialize() {
	}

	function present() as Void {
	}

	function redraw() as Void {
	}
}

// The normal end of a workout: save the run, wait for the complete vibration
// to finish, then show "How did it feel?". If the rating view has not shown
// within WATCHDOG_MS of the switch, the screen is redrawn once.
class RatingHandoff {
	const WATCHDOG_MS = 2000;
	const IDLE = 0;
	const WAITING = 1;
	const HELD = 2;
	const SWITCHED = 3;
	const SHOWN = 4;
	const CANCELLED = 5;

	var state as Number;
	private var log as Breadcrumbs;
	private var scheduler as OneShotScheduler;
	private var screen as RatingScreenPort;

	function initialize(log as Breadcrumbs, scheduler as OneShotScheduler, screen as RatingScreenPort) {
		self.log = log;
		self.scheduler = scheduler;
		self.screen = screen;
		state = IDLE;
	}

	// Saves the recording now, so the rating only updates the history.
	function begin(recorder as WorkoutRecording.Recorder) as Void {
		if (state != IDLE) {
			return;
		}
		log.note("workout complete");
		recorder.save();
		wait();
	}

	function wait() as Void {
		state = WAITING;
		scheduler.schedule(CompleteVibration.ratingDelayMs(), method(:present));
	}

	function present() as Void {
		if (state != WAITING) {
			return;
		}
		state = SWITCHED;
		screen.present();
		screen.redraw();
		scheduler.schedule(WATCHDOG_MS, method(:checkShown));
	}

	// The rating view's onShow.
	function shown() as Void {
		if (state != SWITCHED) {
			return;
		}
		state = SHOWN;
		scheduler.cancel();
		log.note("rating shown");
	}

	function checkShown() as Void {
		if (state != SWITCHED) {
			return;
		}
		log.note("rating redraw forced");
		screen.redraw();
	}

	// The workout view was covered before the rating screen came up.
	function hold() as Void {
		if (state == WAITING) {
			scheduler.cancel();
			state = HELD;
		}
	}

	// The workout view is back; wait the full delay again.
	function release() as Void {
		if (state == HELD) {
			wait();
		}
	}

	// The app is exiting.
	function cancel() as Void {
		scheduler.cancel();
		if (state != SHOWN) {
			state = CANCELLED;
		}
	}
}
