import Toybox.Lang;
using Toybox.Attention;
using Toybox.System;

function attentionForNewActivity(activityType) {
	playSegmentAlert(SegmentAlerts.forActivityType(activityType));
}

function attentionForWorkoutComplete() {
	playSegmentAlert(SegmentAlerts.forWorkoutComplete());
}

function playSegmentAlert(alert as Number) as Void {
	if (alert == SegmentAlerts.RUN) {
		attentionForRunActivity();
		return;
	}
	if (alert == SegmentAlerts.WALK) {
		attentionForWalkActivity();
		return;
	}
	if (alert == SegmentAlerts.WORKOUT_COMPLETE) {
		attentionForWorkoutCompletePattern();
	}
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

function attentionForRunActivity() {
    if (Attention has :vibrate) {
        var vibrateData = [
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile( 0, 250),
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile( 0, 250),
            new Attention.VibeProfile(100, 500)
        ];

        Attention.vibrate(vibrateData);
    }
}

function attentionForWalkActivity() {
    if (Attention has :vibrate) {
        var vibrateData = [
            new Attention.VibeProfile(75, 1500)
        ];

        Attention.vibrate(vibrateData);
    }
}

function attentionForWorkoutCompletePattern() {
    if (Attention has :vibrate) {
        var vibrateData = [
            new Attention.VibeProfile(75, 750),
            new Attention.VibeProfile( 0, 250),
            new Attention.VibeProfile(75, 750),
            new Attention.VibeProfile( 0, 250),
            new Attention.VibeProfile(75, 750),
            new Attention.VibeProfile( 0, 250)
        ];

        Attention.vibrate(vibrateData);
    }
}

function attentionRampDown() {
    if (Attention has :vibrate) {
        var vibrateData = [
            new Attention.VibeProfile(70, 100),
            new Attention.VibeProfile(60, 100),
            new Attention.VibeProfile(50, 100),
            new Attention.VibeProfile(40, 100),
            new Attention.VibeProfile(30, 100),
            new Attention.VibeProfile(20, 100),
            new Attention.VibeProfile(10, 100)
        ];

        Attention.vibrate(vibrateData);
    }
}
