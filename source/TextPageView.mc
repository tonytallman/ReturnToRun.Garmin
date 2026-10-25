import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// A title and a body of static text, paged with Up and Down.
// The body is wrapped once, in onLayout, and the lines are kept, so redraws
// and page turns do no text measuring. Positions are fractions of the display
// so every line stays inside the round face.
class TextPageView extends WatchUi.View {
	var title as String;
	var body as String;
	var lines as Array<String>;
	var pager as TextPager;

	function initialize(title as String, body as String) {
		View.initialize();
		self.title = title;
		self.body = body;
		lines = [] as Array<String>;
		pager = new TextPager(0, 1);
	}

	// The body runs from 27% to 85% of the height. At those edges the circle
	// is still wider than 72% of the display, so a line that fits 72% fits.
	function onLayout(dc as Graphics.Dc) as Void {
		var height = dc.getHeight();
		var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY);
		var bodyHeight = height * 58 / 100;
		lines = TextPages.lines(body, dc.getWidth() * 72 / 100, new DcTextMeasure(dc, Graphics.FONT_XTINY));
		pager = new TextPager(lines.size(), bodyHeight / lineHeight);
	}

	function onUpdate(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var centerX = width / 2;
		var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, height * 17 / 100, Graphics.FONT_TINY, title, center);

		var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY);
		var y = height * 27 / 100 + lineHeight / 2;
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		for (var i = pager.firstLine(); i < pager.endLine(); i++) {
			dc.drawText(centerX, y, Graphics.FONT_XTINY, lines[i], center);
			y += lineHeight;
		}

		var size = width * 3 / 100;
		if (pager.hasPrevious()) {
			var top = height * 5 / 100;
			dc.fillPolygon([[centerX - size, top + size], [centerX + size, top + size], [centerX, top]]);
		}
		if (pager.hasNext()) {
			var bottom = height * 95 / 100;
			dc.fillPolygon([[centerX - size, bottom - size], [centerX + size, bottom - size], [centerX, bottom]]);
		}
	}

	function nextPage() as Void {
		if (pager.next()) {
			WatchUi.requestUpdate();
		}
	}

	function previousPage() as Void {
		if (pager.previous()) {
			WatchUi.requestUpdate();
		}
	}
}

// Up and Down turn pages; Back closes. Swipes do the same on touch devices.
class TextPageDelegate extends WatchUi.BehaviorDelegate {
	var view as TextPageView;

	function initialize(view as TextPageView) {
		BehaviorDelegate.initialize();
		self.view = view;
	}

	function onNextPage() as Boolean {
		view.nextPage();
		return true;
	}

	function onPreviousPage() as Boolean {
		view.previousPage();
		return true;
	}
}
