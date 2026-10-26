import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// A message alone on the round face, wrapped to fit its wide middle.
// Start or Back closes it.
// Positions are fractions of the display so the text stays inside the circle.
class NoticeView extends WatchUi.View {
	var message as String;

	function initialize(message as String) {
		View.initialize();
		self.message = message;
	}

	function onUpdate(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		var wrapped = TextWrap.wrap(message, width * 80 / 100, new DcTextMeasure(dc, Graphics.FONT_XTINY));
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(width / 2, height / 2, Graphics.FONT_XTINY, wrapped, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
}

// Closes the notice and returns to the History list.
class HistoryNoticeDelegate extends WatchUi.BehaviorDelegate {
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
		ScreenStack.requestReturnToHistory();
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}

// Add workout on a date older than a full history: nothing is added. The notice
// replaces the rating step, and closing it returns to the History list.
function showAddTooOld() as Void {
	ScreenStack.requestReturnToHistory();
	var message = WatchUi.loadResource(Rez.Strings.AddTooOldMessage) as String;
	WatchUi.switchToView(new NoticeView(message), new HistoryNoticeDelegate(), WatchUi.SLIDE_LEFT);
}
