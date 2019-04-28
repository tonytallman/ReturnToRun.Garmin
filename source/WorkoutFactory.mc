using Toybox.Graphics;
using Toybox.WatchUi;

class WorkoutFactory extends WatchUi.PickerFactory {

	function initialize() {
		PickerFactory.initialize();
	}

	function getIndex(value) {
		return value;
	}

	function getSize() {
		return getNumberOfWorkouts();
	}

	function getValue(index) {
		return index;
	}

	function getDrawable(index, selected) {
		var text = "#" + (index + 1);
		return new WatchUi.Text({:text=>text, :color=>Graphics.COLOR_WHITE, :font=>Graphics.FONT_SMALL, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER});
	}
}
