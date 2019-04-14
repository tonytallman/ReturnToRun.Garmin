using Toybox.Timer;
using Toybox.WatchUi;

class WorkoutView extends WatchUi.View {

	var workout;
	var currentActivityIndex;
	var currentActivity;
	
	var timer;
	var timeLeft;
	var countdownLabel;
	var activityNameLabel;

    function initialize(workout) {
        View.initialize();
        
        self.workout = workout;

        setCurrentActivity(0);
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WorkoutView(dc));
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
			attentionForWorkoutComplete();
    		return;
    	}
    	
    	timeLeft = currentActivity.seconds;
    	showTimeLeft();
    	
    	showCurrentActivityName();
    	
    	attentionForNewActivity(currentActivity.type);
    }

	function showCurrentActivityName() {
		var activityName = "";    	
    	switch (currentActivity.type) {
    		case WarmUp:
    			activityName =  WatchUi.loadResource(Rez.Strings.WarmUp);
    			break;
    		case CoolDown:
    			activityName =  WatchUi.loadResource(Rez.Strings.CoolDown);
    			break;
    		case Walk:
    			activityName =  WatchUi.loadResource(Rez.Strings.Walk);
    			break;
    		case Run:
    			activityName =  WatchUi.loadResource(Rez.Strings.Run);
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
        var string = getTimeAsString(timeLeft);
        
        if (countdownLabel != null) {
	        countdownLabel.setText(string);
	    }
        
        WatchUi.requestUpdate();
    }
}
