using Toybox.Attention;

function attentionForNewActivity(activityType) {
	switch (activityType) {
		case Run:
			attentionForRunActivity();
			break;
		case Walk:
		case CoolDown:
			attentionForWalkActivity();
			break;
	}
}

function attentionForRunActivity() {
    if (Attention has :vibrate) {
        var vibrateData = [
            new Attention.VibeProfile(75, 250),
            new Attention.VibeProfile( 0, 100),
            new Attention.VibeProfile(75, 250),
            new Attention.VibeProfile( 0, 100),
            new Attention.VibeProfile(75, 250)
        ];

        Attention.vibrate(vibrateData);
    }
}

function attentionForWalkActivity() {
    if (Attention has :vibrate) {
        var vibrateData = [
            new Attention.VibeProfile(40, 750),
            new Attention.VibeProfile( 0, 250),
            new Attention.VibeProfile(40, 750),
            new Attention.VibeProfile( 0, 250)
        ];

        Attention.vibrate(vibrateData);
    }
}

function attentionForWorkoutComplete() {
    if (Attention has :vibrate) {
        var vibrateData = [
            new Attention.VibeProfile(40, 750),
            new Attention.VibeProfile( 0, 250),
            new Attention.VibeProfile(40, 750),
            new Attention.VibeProfile( 0, 250),
            new Attention.VibeProfile(40, 750),
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
