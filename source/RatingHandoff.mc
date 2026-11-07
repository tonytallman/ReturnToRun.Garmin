import Toybox.Lang;
import Toybox.Timer;

// The three-pulse workout-complete vibration as [duty cycle, milliseconds] steps.
// Attention plays it; RatingHandoff waits this long before stopping the session.
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

	// How long after the vibration starts the session is stopped.
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

// The normal end of a workout. Nothing heavy runs while the complete
// vibration plays. Once it has finished, the session is stopped; SETTLE_MS
// later it is saved and "How did it feel?" slides in. If the rating view has
// not shown within WATCHDOG_MS of the switch, the screen is redrawn once.
// GPS and heart rate stay on until the rating is chosen or the app exits.
class RatingHandoff {
	const SETTLE_MS = 1000;
	const WATCHDOG_MS = 2000;
	const IDLE = 0;
	const VIBRATING = 1;
	const STOPPED = 2;
	const SAVED = 3;
	const SWITCHED = 4;
	const SHOWN = 5;
	const CANCELLED = 6;

	var state as Number;
	// The workout view is covered; the switch waits until it is back.
	var held as Boolean;
	private var log as Breadcrumbs;
	private var scheduler as OneShotScheduler;
	private var screen as RatingScreenPort;
	private var recorder as WorkoutRecording.Recorder?;

	function initialize(log as Breadcrumbs, scheduler as OneShotScheduler, screen as RatingScreenPort) {
		self.log = log;
		self.scheduler = scheduler;
		self.screen = screen;
		state = IDLE;
		held = false;
		recorder = null;
	}

	// Called right after the complete vibration starts.
	function begin(recorder as WorkoutRecording.Recorder) as Void {
		if (state != IDLE) {
			return;
		}
		self.recorder = recorder;
		state = VIBRATING;
		scheduler.schedule(CompleteVibration.ratingDelayMs(), method(:stopSession));
	}

	function stopSession() as Void {
		if (state != VIBRATING) {
			return;
		}
		state = STOPPED;
		if (recorder != null) {
			(recorder as WorkoutRecording.Recorder).pause();
		}
		scheduler.schedule(SETTLE_MS, method(:saveSession));
	}

	function saveSession() as Void {
		if (state != STOPPED) {
			return;
		}
		state = SAVED;
		if (recorder != null) {
			(recorder as WorkoutRecording.Recorder).save();
		}
		if (!held) {
			present();
		}
	}

	function present() as Void {
		if (state != SAVED) {
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

	// The workout view was covered. Stop and save still run on time.
	function hold() as Void {
		held = true;
	}

	// The workout view is back.
	function release() as Void {
		held = false;
		if (state == SAVED) {
			present();
		}
	}

	// The app is exiting; it saves an open run itself.
	function cancel() as Void {
		scheduler.cancel();
		if (state != SHOWN) {
			state = CANCELLED;
		}
	}
}
