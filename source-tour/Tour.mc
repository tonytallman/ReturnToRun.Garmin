import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Tour build only (tour.jungle). Uses sample history kept in memory, never
// Application.Storage, and opens each screen in turn on a timer, with no input.
// After each screen has drawn it prints a marker line that tools/device-tour.py
// waits for before capturing the simulator window:
//   TOUR <nn> <name> used=<bytes> total=<bytes>
// The last line is "TOUR END".
function startTour(app as ReturnToRunApp) as Void {
	app.services = Tour.sampleServices();
	Tour.begin();
}

module Tour {
	// Time for a screen to draw before its marker, and for the capture after it.
	const SETTLE_MS = 1500;
	const HOLD_MS = 1500;
	// The sample workout: workout 3, three repeats of run and walk.
	const WORKOUT_INDEX = 2;

	var timer as Timer.Timer?;
	var step as Number = 0;
	var shot as Number = 0;
	var stacked as Boolean = false;
	var workoutView as WorkoutView?;
	var textView as TextPageView?;
	var textName as String = "";
	var textPage as Number = 1;
	var topic as Number = 0;

	// 100 entries, one a day ending today, so the history is full and both
	// pre-run warnings apply (a run today and six days in a row before it).
	// The entries go into the in-memory store as one flat array and load once,
	// as from Application.Storage; adding them one by one saves after each and trips the watchdog.
	function sampleServices() as AppServices {
		var program = WorkoutProgram.load();
		var gateway = new MemoryStorageGateway();
		var today = CalendarDay.today();
		var flat = [] as Array<Number>;
		for (var daysBack = 0; daysBack < HISTORY_ENTRY_CAP; daysBack++) {
			var age = HISTORY_ENTRY_CAP - 1 - daysBack;
			flat.add(today.plusDays(-daysBack).toNumber());
			flat.add((age % program.maxId()) + 1);
			flat.add(age % 4);
		}
		gateway.set(HISTORY_STORAGE_KEY, flat);
		var history = new HistoryStore(gateway, HISTORY_ENTRY_CAP, program.maxId());
		history.load();
		// Keep only what the app itself would keep, so the memory figures compare.
		gateway.remove(HISTORY_STORAGE_KEY);
		return new AppServices(program, new Progress(history));
	}

	function begin() as Void {
		step = 0;
		shot = 0;
		after(SETTLE_MS, :mark);
	}

	function after(ms as Number, name as Symbol) as Void {
		var next = new Timer.Timer();
		timer = next;
		next.start(new Lang.Method(Tour, name), ms, false);
	}

	// Shows a screen above the main menu, replacing the previous tour screen.
	function show(view as WatchUi.Views, delegate as WatchUi.InputDelegates) as Void {
		if (stacked) {
			WatchUi.switchToView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
		} else {
			stacked = true;
			WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
		}
	}

	function showText(name as String, view as TextPageView) as Void {
		textView = view;
		textName = name;
		textPage = 1;
		show(view, new TextPageDelegate(view));
	}

	function stepName() as String {
		if (textView != null) {
			return textName + "-p" + textPage;
		}
		return NAMES[step] as String;
	}

	const NAMES = [
		"main-menu", "workout-list", "warning-1", "warning-2",
		"warm-up", "run", "run-paused", "walk", "cool-down", "rating",
		"history-list", "history-older", "history-details", "add-date", "add-workout", "too-old",
		"program-complete", "instructions", "help", "about"
	] as Array<String>;

	function mark() as Void {
		var stats = System.getSystemStats();
		shot += 1;
		System.println("TOUR " + shot.format("%02d") + " " + stepName() + " used=" + stats.usedMemory + " total=" + stats.totalMemory);
		after(HOLD_MS, :advance);
	}

	function advance() as Void {
		// More pages of the same text first.
		if (textView != null) {
			var view = textView as TextPageView;
			if (view.pager.hasNext()) {
				view.nextPage();
				textPage += 1;
				after(SETTLE_MS, :mark);
				return;
			}
			textView = null;
			if (NAMES[step].equals("help")) {
				topic += 1;
				if (topic < InstructionsMenu.topics().size()) {
					openTopic();
					after(SETTLE_MS, :mark);
					return;
				}
			}
		}
		step += 1;
		if (step >= NAMES.size()) {
			System.println("TOUR END");
			return;
		}
		open(NAMES[step] as String);
		after(SETTLE_MS, :mark);
	}

	function openTopic() as Void {
		var entry = InstructionsMenu.topics()[topic] as Array<ResourceId>;
		var view = new TextPageView(WatchUi.loadResource(entry[0]) as String, WatchUi.loadResource(entry[1]) as String);
		showText("help-" + (topic + 1), view);
	}

	function open(name as String) as Void {
		var services = appServices();
		if (name.equals("workout-list")) {
			show(new WorkoutListView(WatchUi.loadResource(Rez.Strings.Run) as String), new WorkoutListDelegate());
		} else if (name.equals("warning-1") || name.equals("warning-2")) {
			var position = name.equals("warning-1") ? 0 : 1;
			var view = new WarningView(WORKOUT_INDEX, services.warningsForToday(), position);
			show(view, new WarningViewDelegate(view, deviceTouchPolicy()));
		} else if (name.equals("warm-up")) {
			var view = new WorkoutView(WORKOUT_INDEX);
			workoutView = view;
			show(view, new WorkoutViewDelegate(view, deviceTouchPolicy()));
		} else if (name.equals("run")) {
			(workoutView as WorkoutView).setCurrentActivity(1);
		} else if (name.equals("run-paused")) {
			(workoutView as WorkoutView).onSelectPressed();
		} else if (name.equals("walk")) {
			var view = workoutView as WorkoutView;
			view.onSelectPressed();
			view.setCurrentActivity(2);
		} else if (name.equals("cool-down")) {
			var view = workoutView as WorkoutView;
			view.setCurrentActivity(view.workout.getActivityCount() - 1);
		} else if (name.equals("rating")) {
			var view = workoutView as WorkoutView;
			view.stopTicking();
			view.recorder.discard();
			show(new RatingPicker(Rating.GOOD), new RatingDelegate(view));
		} else if (name.equals("history-list")) {
			workoutView = null;
			var list = new HistoryListView();
			show(list, new HistoryListDelegate(list));
		} else if (name.equals("history-older")) {
			// The second page on watches that show the history 30 at a time;
			// elsewhere the same list as history-list.
			var list = new HistoryListView();
			list.turnPage(1);
			show(list, new HistoryListDelegate(list));
		} else if (name.equals("history-details")) {
			show(new HistoryDetailsView(0), new HistoryDetailsDelegate(0));
		} else if (name.equals("add-date")) {
			var view = new AddDateView(new DateStepper(services.currentDay()));
			show(view, new AddDateDelegate(view));
		} else if (name.equals("add-workout")) {
			show(new WorkoutListView(WatchUi.loadResource(Rez.Strings.WorkoutTitle) as String), new AddWorkoutDelegate(services.currentDay()));
		} else if (name.equals("too-old")) {
			show(new NoticeView(WatchUi.loadResource(Rez.Strings.AddTooOldMessage) as String), new HistoryNoticeDelegate());
		} else if (name.equals("program-complete")) {
			show(new ProgramCompleteView(), new ProgramCompleteDelegate(true));
		} else if (name.equals("instructions")) {
			show(new InstructionsMenu(), new InstructionsDelegate());
		} else if (name.equals("help")) {
			topic = 0;
			openTopic();
		} else if (name.equals("about")) {
			var view = aboutView();
			showText("about", view);
		}
	}
}
