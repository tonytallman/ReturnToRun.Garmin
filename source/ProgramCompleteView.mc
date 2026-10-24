import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Shown once per program, after the rating that finishes workout 40.
// Positions are fractions of the display so the text stays inside the circle.
class ProgramCompleteView extends WatchUi.View {
	var title as String;
	var message as String;

	function initialize() {
		View.initialize();
		title = WatchUi.loadResource(Rez.Strings.ProgramCompleteTitle) as String;
		message = WatchUi.loadResource(Rez.Strings.ProgramCompleteMessage) as String;
	}

	function onUpdate(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var centerX = width / 2;
		var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, height * 24 / 100, Graphics.FONT_SMALL, title, center);

		var wrapped = TextWrap.wrap(message, width * 80 / 100, new DcTextMeasure(dc, Graphics.FONT_XTINY));
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, height * 58 / 100, Graphics.FONT_XTINY, wrapped, center);
	}
}

// Select or Back closes the screen and returns to the main menu.
class ProgramCompleteDelegate extends WatchUi.BehaviorDelegate {
	var closed as Boolean;

	function initialize() {
		BehaviorDelegate.initialize();
		closed = false;
	}

	function onSelect() as Boolean {
		close();
		return true;
	}

	function onBack() as Boolean {
		close();
		return true;
	}

	function close() as Void {
		if (closed) {
			return;
		}
		closed = true;
		ScreenStack.requestReturnToMain();
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}
