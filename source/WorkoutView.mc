using Toybox.WatchUi;
using Toybox.Timer;

class WorkoutView extends WatchUi.View {

	var workout;
	var currentActivityIndex;
	var currentActivity;
	
	var timer;
	var timeLeft = 60;
	var countdownLabel;
	var activityNameLabel;

    function initialize(workout) {
        View.initialize();
        
        self.workout = workout;

        setCurrentActivity(0);
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.Countdown(dc));
        countdownLabel = View.findDrawableById("CountdownLabel");
        activityNameLabel = View.findDrawableById("ActivityNameLabel");
        timer = new Timer.Timer();
        timer.start(method(:timerCallback), 1000, true);
        
        showCurrentActivityName();
        showTimeLeft();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
    
    function setCurrentActivity(activityIndex) {
        currentActivityIndex = activityIndex;

    	currentActivity = workout.getActivityAtIndex(currentActivityIndex);
    	if (currentActivity == null) {
    		timer.stop();
    		return;
    	}
    	
    	timeLeft = currentActivity.seconds;
    	showTimeLeft();
    	
    	showCurrentActivityName();
    }

	function showCurrentActivityName() {
		var activityName = "";    	
    	switch (currentActivity.type) {
    		case WarmUp:
    			activityName = "Warm Up";
    			break;
    		case CoolDown:
    			activityName = "Cool Down";
    			break;
    		case Walk:
    			activityName = "Walk";
    			break;
    		case Run:
    			activityName = "Run";
    			break;
    	}
    	if (activityNameLabel != null) {
    		activityNameLabel.setText(activityName);
    	}
    }

    function timerCallback() {
        timeLeft -= 1;
        if (timeLeft == 0) {
        	setCurrentActivity(currentActivityIndex + 1);
        }
        
        showTimeLeft();
    }

	function showTimeLeft() {        
        var minutes = timeLeft / 60;
        var seconds = timeLeft % 60;
        var string = zeroPadded(minutes) + ":" + zeroPadded(seconds);
        
        if (countdownLabel != null) {
	        countdownLabel.setText(string);
	    }
        
        WatchUi.requestUpdate();
    }
    
    function zeroPadded(value) {
    	return ((value < 10) ? "0" : "") + value;
    }
}
