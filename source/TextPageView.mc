import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// A title and a body of static text, paged with Up and Down.
// The body is wrapped and paged once, in onLayout, and the lines are kept, so
// redraws and page turns do no text measuring. Positions are fractions of the display
// so every line stays inside the round face.
class TextPageView extends WatchUi.View {
	var title as String;
	var body as String;
	var lines as Array<String>;
	var pager as TextPager;
	var rowTops as Array<Number>;

	function initialize(title as String, body as String) {
		View.initialize();
		self.title = title;
		self.body = body;
		lines = [] as Array<String>;
		pager = new TextPager(0, [0] as Array<Number>);
		rowTops = [] as Array<Number>;
	}

	// The body runs from 27% to 85% of the height. At those edges the circle
	// is still wider than 72% of the display, so a line that fits 72% fits.
	// The Instincts' short screens fit few lines, so there the body runs down
	// to the page-down arrow, each line as wide as the round bottom allows. On
	// the Instinct Crossover the lines skip the band of the parked hands.
	function onLayout(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY);
		var maxWidth = width * 72 / 100;
		var bottom = height * 85 / 100;
		var follow = System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_SEMI_OCTAGON;
		if (follow) {
			bottom = height * 95 / 100 - width * 3 / 100 - 1;
		}
		var widths = [] as Array<Number>;
		rowTops = [] as Array<Number>;
		var y = HandsBand.clear(Subscreen.below(height * 27 / 100), lineHeight, height);
		while (y + lineHeight <= bottom) {
			var room = maxWidth;
			if (follow) {
				room = width - 2 * Subscreen.rowLeft(width, height, y, lineHeight) - 2 * TitleFit.MARGIN;
				if (room < width * 60 / 100) {
					break;
				}
				if (room > maxWidth) {
					room = maxWidth;
				}
			}
			rowTops.add(y);
			widths.add(room);
			y = HandsBand.clear(y + lineHeight, lineHeight, height);
		}
		if (widths.size() == 0) {
			rowTops.add(y);
			widths.add(maxWidth);
		}
		var pages = TextPages.paginate(body, widths, new DcTextMeasure(dc, Graphics.FONT_XTINY));
		lines = pages[0] as Array<String>;
		pager = new TextPager(lines.size(), pages[1] as Array<Number>);
	}

	function onUpdate(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var centerX = width / 2;
		var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		var size = width * 3 / 100;
		dc.setColor(Palette.title(), Graphics.COLOR_TRANSPARENT);
		TitleFit.drawBelow(dc, title, height * 17 / 100, [Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<Graphics.FontType>, height * 5 / 100 + size + 2);

		var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY);
		var first = pager.firstLine();
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		for (var i = first; i < pager.endLine() && i - first < rowTops.size(); i++) {
			dc.drawText(centerX, rowTops[i - first] + lineHeight / 2, Graphics.FONT_XTINY, lines[i], center);
		}

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
