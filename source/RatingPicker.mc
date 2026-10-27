import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// "How did it feel?" as the built-in Picker, so the title is always shown.
// Up and Down change the rating and Start picks it. The choices, their order,
// and the starting one come from RatingChoices.
class RatingPicker extends WatchUi.Picker {
	function initialize(rating as Number?) {
		var title = new RatingPickerText(WatchUi.loadResource(Rez.Strings.RatingTitle) as String, Graphics.FONT_SMALL);
		title.fitToScreen = true;
		Picker.initialize({
			:title=>title,
			:pattern=>[new RatingPickerFactory()],
			:defaults=>[RatingChoices.defaultIndex(rating)]
		});
	}

	// Black behind the white words, like the app's other screens. The watch
	// honors this. Simulators since SDK 8.3 paint the Picker white anyway, so
	// the title and the words also paint their own black boxes.
	function onUpdate(dc as Graphics.Dc) as Void {
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		dc.clear();
		Picker.onUpdate(dc);
	}
}

// The four rating words. Each word is loaded once.
class RatingPickerFactory extends WatchUi.PickerFactory {
	var words as Array<String>;

	function initialize() {
		PickerFactory.initialize();
		words = [];
		for (var index = 0; index < RatingChoices.count(); index++) {
			words.add(WatchUi.loadResource(RatingChoices.labelId(RatingChoices.ratingAt(index) as Number) as ResourceId) as String);
		}
	}

	function getSize() as Number {
		return RatingChoices.count();
	}

	function getValue(index as Number) as Object? {
		return RatingChoices.ratingAt(index);
	}

	function getDrawable(index as Number, selected as Boolean) as Drawable? {
		return new RatingPickerText(words[index], Graphics.FONT_MEDIUM);
	}
}

// White words on their own black box, so they read the same on the watch and
// in the simulator. Used for the title and for each rating word. The title
// sits at the top of the screen, so it steps down a font size where it would
// run past the edge of the circle.
class RatingPickerText extends WatchUi.Drawable {
	var text as String;
	var font as Graphics.FontType;
	var fitToScreen as Boolean = false;

	function initialize(text as String, font as Graphics.FontType) {
		Drawable.initialize({});
		self.text = text;
		self.font = font;
	}

	function draw(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		dc.fillRectangle(0, 0, width, height);
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		var drawFont = font;
		if (fitToScreen) {
			drawFont = TitleFit.font(dc, text, height / 2, [font, Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<Graphics.FontType>);
		}
		dc.drawText(width / 2, height / 2, drawFont, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
}

// After a run a rating is required. Back keeps the picker up, so a finished
// run is never left unlogged.
class RatingDelegate extends WatchUi.PickerDelegate {
	var workoutView as WorkoutView;

	function initialize(workoutView as WorkoutView) {
		PickerDelegate.initialize();
		self.workoutView = workoutView;
	}

	function onAccept(values as Array) as Boolean {
		var rating = RatingChoices.fromPicked(values);
		if (rating != null) {
			workoutView.rate(rating as Number);
		}
		return true;
	}

	function onCancel() as Boolean {
		return true;
	}
}
