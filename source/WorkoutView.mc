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

	// Yes on "End workout?". If this view is already showing, the confirm dialog
	// closed before the answer was delivered, so pop from here. If the dialog is
	// still up, onShow pops once the flag is set.
	function confirmEnd() as Void {
		if (session.onConfirmEnd() != WorkoutSession.DISCARD) {
			return;
		}
		stopTicking();
		ScreenStack.requestReturnToMain();
		if (visible) {
			leaveTimer.schedule();
		}
	}

	function declineEnd() as Void {
		session.onDeclineEnd();
		showTimeLeft();
	}

	function onSelectPressed() as Void {
		apply(session.onSelect());
	}

	function onBackPressed() as Void {
		apply(session.onBack());
	}

	function apply(action as Number) as Void {
		if (action == WorkoutSession.PAUSE) {
			stopTicking();
			showTimeLeft();
			return;
		}
		if (action == WorkoutSession.RESUME) {
			startTicking();
			showTimeLeft();
			return;
		}
		if (action == WorkoutSession.ASK_TO_END) {
			stopTicking();
			showTimeLeft();
			var message = WatchUi.loadResource(Rez.Strings.EndWorkoutConfirm) as String;
			var dialog = new WatchUi.Confirmation(message);
			var dialogDelegate = new EndWorkoutDelegate(self);
			WatchUi.pushView(dialog, dialogDelegate, WatchUi.SLIDE_IMMEDIATE);
		}
	}

	function setCurrentActivity(activityIndex as Number) as Void {
		currentActivityIndex = activityIndex;
		currentActivity = workout.getActivityAtIndex(currentActivityIndex);
		if (currentActivity == null) {
			session.onCompleted();
			stopTicking();
			attentionForWorkoutComplete();
			ScreenStack.requestReturnToMain();
			WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
			return;
		}

		var activity = currentActivity as Activity;
		timeLeft = activity.seconds;
		showCurrentActivityName();
		showIntervalCount();
		showTimeLeft();
		attentionForNewActivity(activity.type);

		// Reaching cool-down logs the workout as Good. Leaving before that does not.
		if (activity.type == CoolDown) {
			appServices().recordCompletedWorkout(workoutIndex);
		}
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
			var remaining = WorkoutDuration.remainingSeconds(workout, currentActivityIndex, timeLeft);
			var remainingText = getTimeAsString(remaining) + " " + timeLeftSuffix;
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
