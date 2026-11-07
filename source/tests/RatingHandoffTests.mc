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

		function stop() as Void {
			log.note("stop");
		}

		function save() as Void {
			saves++;
			log.note("save");
		}

		function shutdown() as Void {
			log.note("sensors off");
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
	TestSupport.expectEqual("", f.order(), "nothing runs while the vibration plays");
	f.scheduler.fire();
	TestSupport.expectEqual("stop", f.order(), "stopped once the vibration is over");
	TestSupport.expectEqual(f.handoff.SETTLE_MS, f.scheduler.delayMs, "save waits a moment after stop");
	f.scheduler.fire();
	f.handoff.shown();
	TestSupport.expectEqual("stop, save, present, rating shown", f.order(), "stop, save, then the rating");
	TestSupport.expectEqual(1, f.screen.redraws, "one redraw after the switch");
	TestSupport.expectNull(f.scheduler.callback, "watchdog cancelled once shown");
	return true;
}

(:test)
function testRatingHandoffDelay(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	TestSupport.expectEqual(CompleteVibration.durationMs() + 100, f.scheduler.delayMs, "stop waits for the vibration");
	TestSupport.expectEqual(2100, f.scheduler.delayMs, "2,100 ms");
	return true;
}

(:test)
function testRatingDoesNotSaveAgain(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	f.scheduler.fire();
	f.scheduler.fire();
	f.recorder.save();
	f.handoff.begin(f.recorder);
	TestSupport.expectEqual(1, f.port.saves, "saved once");
	TestSupport.expectEqual("stop, save, present", f.order(), "GPS and heart rate stay on after the save");
	return true;
}

(:test)
function testRatingRedrawForced(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	f.scheduler.fire();
	f.scheduler.fire();
	TestSupport.expectEqual(f.handoff.WATCHDOG_MS, f.scheduler.delayMs, "watchdog after the switch");
	f.scheduler.fire();
	TestSupport.expectEqual("stop, save, present, rating redraw forced", f.order(), "forced redraw logged");
	TestSupport.expectEqual(2, f.screen.redraws, "redrawn again");
	return true;
}

(:test)
function testRatingHandoffHoldAndCancel(logger as Test.Logger) as Boolean {
	var f = new RatingHandoffTestSupport.Fixture();
	f.handoff.begin(f.recorder);
	f.handoff.hold();
	f.scheduler.fire();
	f.scheduler.fire();
	TestSupport.expectEqual("stop, save", f.order(), "saved on time while covered, no switch");
	f.handoff.release();
	TestSupport.expectEqual("stop, save, present", f.order(), "switch once uncovered");

	var g = new RatingHandoffTestSupport.Fixture();
	g.handoff.begin(g.recorder);
	g.handoff.cancel();
	TestSupport.expectNull(g.scheduler.callback, "exit cancels the pending step");
	g.scheduler.fire();
	TestSupport.expectEqual(0, g.port.saves, "the handoff does not save after exit");
	return true;
}
