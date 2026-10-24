import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;

function attentionForNewActivity(activityType) as Void {
	playSegmentAlert(SegmentAlerts.forActivityType(activityType));
}

function attentionForWorkoutComplete() as Void {
	playSegmentAlert(SegmentAlerts.forWorkoutComplete());
}

function playSegmentAlert(alert as Number) as Void {
	if (alert == SegmentAlerts.WORKOUT_COMPLETE) {
		vibrateWorkoutComplete();
		return;
	}
	vibrateSegment();
}

// Connect IQ has no system vibration preset. One strong pulse is the segment cue.
function vibrateSegment() as Void {
	if (!(Attention has :vibrate)) {
		return;
	}
	var vibrateData = [
		new Attention.VibeProfile(100, 1000)
	] as Array<Attention.VibeProfile>;
	Attention.vibrate(vibrateData);
}

// Three pulses so the end of the workout is distinct from a segment change.
function vibrateWorkoutComplete() as Void {
	if (!(Attention has :vibrate)) {
		return;
	}
	var vibrateData = [
		new Attention.VibeProfile(100, 500),
		new Attention.VibeProfile(0, 250),
		new Attention.VibeProfile(100, 500),
		new Attention.VibeProfile(0, 250),
		new Attention.VibeProfile(100, 500)
	] as Array<Attention.VibeProfile>;
	Attention.vibrate(vibrateData);
}

// One short beep for each of the last five seconds. This does not vibrate.
function playCountdownTone() as Void {
	if (!(Attention has :playTone)) {
		return;
	}
	var settings = System.getDeviceSettings();
	if (!settings.tonesOn) {
		return;
	}
	if (!(Attention has :ToneProfile)) {
		return;
	}
	// 150 ms at 2500 Hz is one short beep, so the five countdown tones do not run together.
	var toneProfile = [
		new Attention.ToneProfile(2500, 150)
	] as Array<Attention.ToneProfile>;
	Attention.playTone({:toneProfile=>toneProfile, :repeatCount=>1});
}
