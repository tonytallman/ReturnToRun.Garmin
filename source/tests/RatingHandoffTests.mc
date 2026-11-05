import Toybox.Lang;
import Toybox.Test;

(:test)
module RatingHandoffTestSupport {
	// Keeps every note, and the port's saves, in one ordered list.
	class ListBreadcrumbs extends Breadcrumbs {
		var lines as Array<String>;

		function initialize() {
			Breadcrumbs.initialize();
			lines = [] as Array<String>;
		}

		function note(event as String) as Void {
			lines.add(event);
		}
	}

	class SavingPort extends RecordingPort {
		var log as ListBreadcrumbs;
		var saves as Number = 0;

		function initialize(log as ListBreadcrumbs) {
			RecordingPort.initialize();
			self.log = log;
		}

		function save() as Void {
			saves++;
			log.note("save");
		}
	}

	class ManualScheduler extends OneShotScheduler {
		var delayMs as Number?;
		var callback as Method?;

		function initialize() {
			OneShotScheduler.initialize();
		}

		function schedule(delayMs as Number, callback as Method() as Void) as Void {
			self.delayMs = delayMs;
			self.callback = callback;
		}

		function cancel() as Void {
			delayMs = null;
			callback = null;
		}

		function fire() as Void {
			var pending = callback;
			callback = null;
			delayMs = null;
			if (pending != null) {
				(pending as Method).invoke();
			}
		}
	}

	class CountingScreen extends RatingScreenPort {
		var log as ListBreadcrumbs;
		var redraws as Number = 0;

		function initialize(log as ListBreadcrumbs) {
			RatingScreenPort.initialize();
			self.log = log;
		}

		function present() as Void {
			log.note("present");
		}

		function redraw() as Void {
			redraws++;
		}
	}

	class Fixture {
		var log as ListBreadcrumbs;
		var port as SavingPort;
		var recorder as WorkoutRecording.Recorder;
		var scheduler as ManualScheduler;
		var screen as CountingScreen;
		var handoff as RatingHandoff;

		function initialize() {
			log = new ListBreadcrumbs();
			port = new SavingPort(log);
			recorder = new WorkoutRecording.Recorder(port);
			recorder.start();
			scheduler = new ManualScheduler();
			screen = new CountingScreen(log);
			handoff = new RatingHandoff(log, scheduler, screen);
		}

		function order() as String {
			var text = "";
			for (var index = 0; index < log.lines.size(); index++) {
				text += (index > 0 ? ", " : "") + log.lines[index];
			}
			return text;
		}
	}
}

(:test)
function testRatingHandoffOrder(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	TestSupport.expectEqual("workout complete, save", f.order(), "saved at completion, before the rating");
	f.scheduler.fire();
	f.handoff.shown();
	TestSupport.expectEqual("workout complete, save, present, rating shown", f.order(), "complete, save, rating shown");
	TestSupport.expectEqual(1, f.screen.redraws, "one redraw after the switch");
	TestSupport.expectNull(f.scheduler.callback, "watchdog cancelled once shown");
	return true;
}

(:test)
function testRatingHandoffDelay(logger as Test.Logger) as Boolean {
	TestSupport.expectEqual(2000, CompleteVibration.durationMs(), "three 500 ms pulses and two 250 ms gaps");
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	TestSupport.expectEqual(CompleteVibration.durationMs() + CompleteVibration.MARGIN_MS, f.scheduler.delayMs, "waits for the vibration");
	f.scheduler.fire();
	TestSupport.expectEqual(f.handoff.WATCHDOG_MS, f.scheduler.delayMs, "watchdog after the switch");
	return true;
}

(:test)
function testRatingDoesNotSaveAgain(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	f.handoff.begin(f.recorder);
	TestSupport.expectFalse(f.recorder.save(), "rating's save does nothing");
	TestSupport.expectFalse(f.recorder.save(), "exit's save does nothing");
	TestSupport.expectEqual(1, f.port.saves, "one save");
	return true;
}

(:test)
function testRatingRedrawForced(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	f.scheduler.fire();
	f.scheduler.fire();
	TestSupport.expectEqual("workout complete, save, present, rating redraw forced", f.order(), "watchdog logs");
	TestSupport.expectEqual(2, f.screen.redraws, "forced redraw");
	f.handoff.shown();
	TestSupport.expectEqual("workout complete, save, present, rating redraw forced, rating shown", f.order(), "shown after the forced redraw");
	return true;
}

(:test)
function testRatingHandoffHoldAndCancel(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	f.handoff.hold();
	TestSupport.expectNull(f.scheduler.callback, "covered: pending switch cancelled");
	f.handoff.release();
	TestSupport.expectEqual(CompleteVibration.ratingDelayMs(), f.scheduler.delayMs, "shown again: waits again");
	f.handoff.cancel();
	TestSupport.expectNull(f.scheduler.callback, "exit cancels");
	f.handoff.present();
	f.handoff.release();
	TestSupport.expectEqual("workout complete, save", f.order(), "nothing after cancel");
	return true;
}
