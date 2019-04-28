using Toybox.Graphics;
using Toybox.WatchUi;

class WorkoutPicker extends WatchUi.Picker {

	function initialize(workoutIndex) {
		var title = WatchUi.loadResource(Rez.Strings.SelectWorkout);
		var titleDrawable = new WatchUi.Text({:text=>title, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
		var factory = new WorkoutFactory();
		var defaults = [workoutIndex];
		Picker.initialize({:title=>titleDrawable, :pattern=>[factory], :defaults=>defaults});
	}

	function onUpdate(dc) {
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		dc.clear();
		Picker.onUpdate(dc);
	}
}
