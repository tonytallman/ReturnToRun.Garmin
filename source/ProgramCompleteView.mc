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
		var height = dc.getHeight();
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		dc.setColor(Palette.title(), Graphics.COLOR_TRANSPARENT);
		var titleY = height * 21 / 100;
		TitleFit.draw(dc, title, titleY, [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<Graphics.FontType>);

		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		// Below the subscreen and the title split in two beside it.
		Subscreen.drawMessage(dc, message, height * 60 / 100, 80, Subscreen.below(titleY + dc.getFontHeight(Graphics.FONT_SMALL) + 2));
	}
}

// Select or Back closes the screen. After a run it returns to the main menu;
// after a History edit it returns to the History list.
class ProgramCompleteDelegate extends WatchUi.BehaviorDelegate {
	var closed as Boolean;
	var toHistory as Boolean;

	function initialize(toHistory as Boolean) {
		BehaviorDelegate.initialize();
		closed = false;
		self.toHistory = toHistory;
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
		if (toHistory) {
			ScreenStack.requestReturnToHistory();
		} else {
			ScreenStack.requestReturnToMain();
		}
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}
