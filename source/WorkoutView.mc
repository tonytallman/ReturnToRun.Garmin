import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class WorkoutView extends WatchUi.View {
	var workout as Workout;
	var workoutIndex as Number;
	var currentActivityIndex as Number;
	var currentActivity as Activity?;
	var session as WorkoutSession.Machine;
	var recorder as WorkoutRecording.Recorder;
	var leaveTimer as LeaveTimer;
	var timer as Timer.Timer?;
	var visible as Boolean;
	var timeLeft as Number;
	var pausedText as String;
	var timeLeftSuffix as String;
	var countdownLabel as WatchUi.Text?;
	var activityNameLabel as WatchUi.Text?;
	var intervalCountLabel as WatchUi.Text?;
	var remainingLabel as WatchUi.Text?;
	var pausedLabel as WatchUi.Text?;

	function initialize(workoutIndex as Number) {
		View.initialize();
		self.workoutIndex = workoutIndex;
		session = new WorkoutSession.Machine();
		recorder = appServices().newRecorder(workoutIndex + 1);
		leaveTimer = new LeaveTimer();
		pausedText = "";
		timeLeftSuffix = "";
		visible = false;
		timeLeft = 0;
		currentActivityIndex = 0;
		currentActivity = null;
		var loaded = appServices().workoutAtIndex(workoutIndex);
		if (loaded == null) {
			workout = new Workout(0, 0, 1, 0, 0);
		} else {
			workout = loaded as Workout;
		}
		setCurrentActivity(0);
		recorder.start();
	}

	function onLayout(dc as Graphics.Dc) as Void {
		setLayout(Rez.Layouts.WorkoutView(dc));
		countdownLabel = View.findDrawableById("CountdownLabel") as WatchUi.Text?;
		activityNameLabel = View.findDrawableById("ActivityNameLabel") as WatchUi.Text?;
		intervalCountLabel = View.findDrawableById("IntervalCountLabel") as WatchUi.Text?;
		remainingLabel = View.findDrawableById("RemainingLabel") as WatchUi.Text?;
		pausedLabel = View.findDrawableById("PausedLabel") as WatchUi.Text?;
		pausedText = WatchUi.loadResource(Rez.Strings.Paused) as String;
		timeLeftSuffix = WatchUi.loadResource(Rez.Strings.TimeLeftSuffix) as String;
		showCurrentActivityName();
		showIntervalCount();
		showTimeLeft();
	}

	function onShow() as Void {
		visible = true;
		if (leaveTimer.schedule()) {
			stopTicking();
			return;
		}
		if (session.isTiming()) {
			startTicking();
		}
		showTimeLeft();
	}

	function onHide() as Void {
		visible = false;
		stopTicking();
	}

	// Resume on "End workout?".
	function resumeFromEnd() as Void {
		if (session.onResumeFromEnd() != WorkoutSession.RESUME) {
			return;
		}
		recorder.start();
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
	}

	// Back on "End workout?". The workout stays paused.
	function declineEnd() as Void {
		if (session.onDeclineEnd() != WorkoutSession.KEEP_PAUSED) {
			return;
		}
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
	}

	// Save on "End workout?". The rating replaces the prompt, and this view
	// leaves after the rating, through the return to the main menu.
	function saveEarly() as Void {
		if (session.onSaveEarly() != WorkoutSession.SAVE) {
			return;
		}
		recorder.save();
		WatchUi.switchToView(new RatingMenu(Rating.GOOD), new RatingDelegate(self), WatchUi.SLIDE_LEFT);
	}

	// Discard on "End workout?". Nothing is saved or logged. Closing the prompt
	// shows this view again, and its onShow pops it.
	function discard() as Void {
		if (session.onDiscard() != WorkoutSession.DISCARD) {
			return;
		}
		recorder.discard();
		ScreenStack.requestReturnToMain();
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
	}

	// A choice on "How did it go?". Saves the run if the end prompt did not,
	// logs it, then shows program complete once or returns to the main menu.
	function rate(rating as Number) as Void {
		if (session.onRated() != WorkoutSession.LOG) {
			return;
		}
		recorder.save();
		var services = appServices();
		if (services.logWorkout(workoutIndex, rating)) {
			services.markProgramCompleteShown();
			WatchUi.switchToView(new ProgramCompleteView(), new ProgramCompleteDelegate(false), WatchUi.SLIDE_LEFT);
			return;
		}
		ScreenStack.requestReturnToMain();
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}

	function onSelectPressed() as Void {
		apply(session.onSelect());
	}

	function onBackPressed() as Void {
		apply(session.onBack());
	}

	function apply(action as Number) as Void {
		if (action == WorkoutSession.PAUSE) {
			recorder.pause();
			stopTicking();
			showTimeLeft();
			return;
		}
		if (action == WorkoutSession.RESUME) {
			recorder.start();
			startTicking();
			showTimeLeft();
			return;
		}
		if (action == WorkoutSession.ASK_TO_END) {
			stopTicking();
			showTimeLeft();
			WatchUi.pushView(new EndWorkoutMenu(), new EndWorkoutDelegate(self), WatchUi.SLIDE_IMMEDIATE);
		}
	}

	function setCurrentActivity(activityIndex as Number) as Void {
		currentActivityIndex = activityIndex;
		currentActivity = workout.getActivityAtIndex(currentActivityIndex);
		if (currentActivity == null) {
			finish();
			return;
		}

		var activity = currentActivity as Activity;
		timeLeft = activity.seconds;
		showCurrentActivityName();
		showIntervalCount();
		showTimeLeft();
		attentionForNewActivity(activity.type);
		// Each segment after the warm-up starts a new lap in the activity.
		if (activityIndex > 0) {
			recorder.lap();
		}
	}

	// The last segment finished. The recording stops and waits for the rating,
	// which replaces this view.
	function finish() as Void {
		if (session.onCompleted() != WorkoutSession.COMPLETE) {
			return;
		}
		stopTicking();
		recorder.pause();
		attentionForWorkoutComplete();
		WatchUi.switchToView(new RatingMenu(Rating.GOOD), new RatingDelegate(self), WatchUi.SLIDE_LEFT);
	}

	function showCurrentActivityName() as Void {
		if ((activityNameLabel == null) || (currentActivity == null)) {
			return;
		}
		var activity = currentActivity as Activity;
		var activityName = "";
		if (activity.type == WarmUp) {
			activityName = WatchUi.loadResource(Rez.Strings.WarmUp) as String;
		} else if (activity.type == CoolDown) {
			activityName = WatchUi.loadResource(Rez.Strings.CoolDown) as String;
		} else if (activity.type == Walk) {
			activityName = WatchUi.loadResource(Rez.Strings.Walk) as String;
		} else if (activity.type == Run) {
			activityName = WatchUi.loadResource(Rez.Strings.Run) as String;
		}
		(activityNameLabel as WatchUi.Text).setText(activityName);
	}

	function showIntervalCount() as Void {
		if (intervalCountLabel == null) {
			return;
		}
		var label = IntervalCount.labelFor(currentActivityIndex, workout.repeatCount, workout.hasWalks());
		(intervalCountLabel as WatchUi.Text).setText(label);
	}

	function timerCallback() as Void {
		if (!session.isTiming()) {
			return;
		}
		timeLeft = timeLeft - 1;
		if (timeLeft <= 0) {
			setCurrentActivity(currentActivityIndex + 1);
			return;
		}
		if (CountdownTones.shouldPlay(timeLeft)) {
			playCountdownTone();
		}
		showTimeLeft();
	}

	function showTimeLeft() as Void {
		var segment = getTimeAsString(timeLeft);
		if (countdownLabel != null) {
			var countdown = countdownLabel as WatchUi.Text;
			countdown.setText(segment);
			if (session.showsPaused()) {
				countdown.setColor(Graphics.COLOR_YELLOW);
			} else {
				countdown.setColor(Graphics.COLOR_WHITE);
			}
		}
		if (remainingLabel != null) {
			// Time left in the run/walk main set; warm-up and cool-down show none.
			var remainingText = "";
			if (WorkoutDuration.showsRemaining(workout, currentActivityIndex)) {
				var remaining = WorkoutDuration.remainingInMainSet(workout, currentActivityIndex, timeLeft);
				remainingText = getTimeAsString(remaining) + " " + timeLeftSuffix;
			}
			(remainingLabel as WatchUi.Text).setText(remainingText);
		}
		if (pausedLabel != null) {
			var paused = pausedLabel as WatchUi.Text;
			if (session.showsPaused()) {
				paused.setText(pausedText);
			} else {
				paused.setText("");
			}
		}
		WatchUi.requestUpdate();
	}

	function startTicking() as Void {
		if (timer == null) {
			timer = new Timer.Timer();
		}
		var running = timer as Timer.Timer;
		running.stop();
		running.start(method(:timerCallback), 1000, true);
	}

	function stopTicking() as Void {
		if (timer != null) {
			(timer as Timer.Timer).stop();
		}
	}
}
