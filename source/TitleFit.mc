import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Picks a title font that fits across a round display at the title's height.
// Devices of the same size use different fonts (the vivoactive 3's are wider),
// so a title that fits on one can run past the edge of the circle on another.
module TitleFit {
	// Space kept clear on each side of the title.
	const MARGIN = 3;

	// Width of a round display of this diameter at this many pixels from its top.
	function chordWidth(diameter as Number, y as Number) as Number {
		var radius = diameter / 2;
		var dy = radius - y;
		if (dy < 0) {
			dy = -dy;
		}
		if (dy >= radius) {
			return 0;
		}
		return (2 * Math.sqrt(radius * radius - dy * dy)).toNumber();
	}

	// The first of the fonts whose text fits at screenY (the middle of the
	// line, measured from the top of the screen), or the last one if none do.
	// The text also has to fit in dc, which can be narrower than the screen
	// (the Venu Sq 2 gives the Picker title 214 of its 320 pixels).
	function font(dc as Graphics.Dc, text as String, screenY as Number, fonts as Array<Graphics.FontType>) as Graphics.FontType {
		var settings = System.getDeviceSettings();
		var room = settings.screenWidth;
		if (settings.screenShape == System.SCREEN_SHAPE_ROUND) {
			room = chordWidth(settings.screenWidth, screenY);
		}
		if (dc.getWidth() < room) {
			room = dc.getWidth();
		}
		return fontWithin(dc, text, room, fonts);
	}

	// The first of the fonts whose text fits in room pixels, keeping MARGIN
	// clear on each side, or the last one if none do.
	function fontWithin(dc as Graphics.Dc, text as String, room as Number, fonts as Array<Graphics.FontType>) as Graphics.FontType {
		var widths = new Array<Number>[fonts.size()];
		for (var index = 0; index < fonts.size(); index++) {
			widths[index] = dc.getTextWidthInPixels(text, fonts[index]);
		}
		return fonts[firstFitting(widths, room - 2 * MARGIN)];
	}

	// The index of the first width that is at most room, or the last index if
	// none is.
	function firstFitting(widths as Array<Number>, room as Number) as Number {
		var last = widths.size() - 1;
		for (var index = 0; index < last; index++) {
			if (widths[index] <= room) {
				return index;
			}
		}
		return last;
	}
}
