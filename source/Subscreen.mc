import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The small round display in the top-right corner of most Instinct watches.
// Text is kept out of it: a title on its rows is centered in the room to its
// left, and other text starts below it. During a workout it shows the time of
// day. On watches without one, nothing changes.
module Subscreen {
	// Clear of the frame drawn around the subscreen.
	const GAP = 6;

	function box() as Graphics.BoundingBox? {
		if (WatchUi has :getSubscreen) {
			return WatchUi.getSubscreen();
		}
		return null;
	}

	// The right edge of the room for a line centered at y that is lineHeight
	// tall: the subscreen's left edge (less GAP) when the line reaches the
	// subscreen's rows, otherwise width.
	function rightEdge(width as Number, y as Number, lineHeight as Number, boxLeft as Number, boxBottom as Number) as Number {
		if (y - lineHeight / 2 >= boxBottom) {
			return width;
		}
		return boxLeft - GAP;
	}

	// The first row below the subscreen, or y if that is already below it.
	function below(y as Number) as Number {
		var found = box();
		if (found == null) {
			return y;
		}
		var under = found.y + found.height + GAP;
		return y > under ? y : under;
	}

	// The left edge of the display at row y: the round edge, or the cut-off
	// corner of the Instinct's semi-octagon top (about 45 degrees, measured on
	// the instinct2 simulator).
	function leftEdge(width as Number, y as Number) as Number {
		var shape = System.getDeviceSettings().screenShape;
		if (shape == System.SCREEN_SHAPE_ROUND) {
			return (width - TitleFit.chordWidth(width, y)) / 2;
		}
		if (shape == System.SCREEN_SHAPE_SEMI_OCTAGON) {
			var corner = width * 24 / 100 - y;
			return corner > 0 ? corner : 0;
		}
		return 0;
	}

	function lineCount(text as String) as Number {
		var lines = 1;
		var rest = text;
		var at = rest.find("\n");
		while (at != null) {
			lines += 1;
			rest = rest.substring((at as Number) + 1, rest.length()) as String;
			at = rest.find("\n");
		}
		return lines;
	}

	// Most lines a message can have on these small screens.
	const MAX_LINES = 9;

	// Draws text wrapped to widthPercent of the screen in FONT_XTINY, as a
	// block centered at y. On the Instinct, the block starts no higher than
	// minTop, and each line is wrapped to the room it has: left of the
	// subscreen on its rows, and inside the cut-off top corner and the round
	// bottom. On the Instinct Crossover the lines skip the band of the
	// parked hands (HandsBand). Returns the bottom of the block.
	function drawMessage(dc as Graphics.Dc, text as String, y as Number, widthPercent as Number, minTop as Number, maxBottom as Number) as Number {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var font = Graphics.FONT_XTINY;
		var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
		var lineHeight = dc.getFontHeight(font);
		var measure = new DcTextMeasure(dc, font);
		var maxWidth = width * widthPercent / 100;
		var wrapped = TextWrap.wrap(text, maxWidth, measure);
		var lines = lineCount(wrapped);
		var found = box();
		if ((found == null) && (HandsBand.halfHeight() == 0)) {
			dc.drawText(width / 2, y, font, wrapped, center);
			return y + lines * lineHeight / 2;
		}
		// Where the lines would run past maxBottom, they cross the hands instead.
		var tops = [] as Array<Number>;
		var widths = [] as Array<Number>;
		var centers = [] as Array<Number>;
		for (var pass = 0; pass < 2; pass++) {
			var skipHands = (pass == 0) && (HandsBand.halfHeight() > 0);
			var top = y - lines * lineHeight / 2;
			if (skipHands) {
				top = HandsBand.centered(top, lines * lineHeight, height);
			}
			if (top < minTop) {
				top = minTop;
			}
			tops = [] as Array<Number>;
			widths = [] as Array<Number>;
			centers = [] as Array<Number>;
			for (var index = 0; index < MAX_LINES; index++) {
				var lineTop = skipHands ? HandsBand.clear(top, lineHeight, height) : top;
				tops.add(lineTop);
				top = lineTop + lineHeight;
				var left = rowLeft(width, height, lineTop, lineHeight);
				var right = width - left;
				if ((found != null) && (lineTop < found.y + found.height + GAP)) {
					right = found.x - GAP;
				}
				var room = right - left - 2 * TitleFit.MARGIN;
				widths.add(room < maxWidth ? room : maxWidth);
				centers.add((left + right) / 2);
			}
			wrapped = TextWrap.wrapLines(text, widths, measure);
			lines = lineCount(wrapped);
			if (lines > MAX_LINES) {
				lines = MAX_LINES;
			}
			if (!skipHands || (tops[lines - 1] + lineHeight <= maxBottom)) {
				break;
			}
		}
		var rest = wrapped;
		for (var index = 0; index < lines; index++) {
			var at = rest.find("\n");
			var line = (at == null) ? rest : rest.substring(0, at as Number) as String;
			rest = (at == null) ? "" : rest.substring((at as Number) + 1, rest.length()) as String;
			dc.drawText(centers[index], tops[index] + lineHeight / 2, font, line, center);
		}
		return tops[lines - 1] + lineHeight;
	}

	// The left edge of a row lineHeight tall whose top is at lineTop: inside
	// the cut-off top corner or the round top, and the round bottom.
	function rowLeft(width as Number, height as Number, lineTop as Number, lineHeight as Number) as Number {
		var left = leftEdge(width, lineTop);
		var lineBottom = lineTop + lineHeight;
		if (lineBottom > height / 2) {
			var bottomLeft = (width - TitleFit.chordWidth(height, lineBottom)) / 2;
			if (bottomLeft > left) {
				left = bottomLeft;
			}
		}
		return left;
	}

	// The time of day in the subscreen, in the watch's 12- or 24-hour format.
	function drawClock(dc as Graphics.Dc) as Void {
		var found = box();
		if (found == null) {
			return;
		}
		var clock = System.getClockTime();
		var hour = clock.hour;
		if (!System.getDeviceSettings().is24Hour) {
			hour = hour % 12;
			if (hour == 0) {
				hour = 12;
			}
		}
		var text = hour.toString() + ":" + clock.min.format("%02d");
		var font = TitleFit.fontWithin(dc, text, found.width, [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<Graphics.FontType>);
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(found.x + found.width / 2, found.y + found.height / 2, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
}
