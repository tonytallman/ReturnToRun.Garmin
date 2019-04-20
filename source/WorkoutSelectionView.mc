using Toybox.WatchUi;

class WorkoutSelectionView extends WatchUi.View {

	var workoutIndex;
	var workout;
	
    function initialize(workoutIndex) {
        View.initialize();
        self.workoutIndex = workoutIndex;
		workout = getWorkoutAtIndex(workoutIndex);
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WorkoutSelectionView(dc));
        
        var workoutTitleLabel = View.findDrawableById("WorkoutTitleLabel");
        var workoutTitle = WatchUi.loadResource(Rez.Strings.Workout) + " #" + (workoutIndex + 1);
        workoutTitleLabel.setText(workoutTitle);

        var workoutDescriptionLabel = View.findDrawableById("WorkoutDescriptionLabel");
        var workoutDescription = WatchUi.loadResource(Rez.Strings.WarmUp) + " " + getTimeAsString(workout.warmUpSeconds) + "\n"; 
        workoutDescription += WatchUi.loadResource(Rez.Strings.Run) + " " + getTimeAsString(workout.runSeconds) + " ";
        workoutDescription += WatchUi.loadResource(Rez.Strings.Walk) + " " + getTimeAsString(workout.walkSeconds) + " ";
        workoutDescription += "x" + workout.repeatCount + "\n";
        workoutDescription += WatchUi.loadResource(Rez.Strings.CoolDown) + " " + getTimeAsString(workout.coolDownSeconds) + "\n"; 
	    workoutDescriptionLabel.setText(workoutDescription);
    }
}
