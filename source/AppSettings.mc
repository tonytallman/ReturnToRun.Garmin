class AppSettings {

	private var workoutIndexKey = "workoutIndex";

	function getWorkoutIndex() {
		var workoutIndex = Application.getApp().getProperty(workoutIndexKey);
		return (workoutIndex != null) ? workoutIndex : 0;
	}

	function setWorkoutIndex(workoutIndex) {
		Application.getApp().setProperty(workoutIndexKey, workoutIndex);
	}
}
