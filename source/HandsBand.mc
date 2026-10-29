import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The Instinct Crossover's analog hands stay on the screen while an app runs,
// parked across the middle (9:15), so text keeps out of a band around the
// middle row. resources-hands-* gives each Crossover the band's half height.
// monkey.jungle builds this module only for the Crossovers (the :hands
// annotation); other watches get the stub below, which moves nothing and
// keeps the 96 KB watches' code small. The *Of functions are pure.
(:hands)
module HandsBand {
	var half as Number? = null;

	function halfHeight() as Number {
		if (half == null) {
			var setting = Application.loadResource(Rez.JsonData.HandsBand);
			half = (setting instanceof Dictionary && setting["half"] instanceof Number) ? setting["half"] as Number : 0;
		}
		return half as Number;
	}

	function top(height as Number) as Number {
		return height / 2 - halfHeight();
	}

	function bottom(height as Number) as Number {
		return height / 2 + halfHeight();
	}

	// The top of a row lineHeight tall starting at y, moved below the band if
	// it would reach into it.
	function clear(y as Number, lineHeight as Number, height as Number) as Number {
		return clearOf(y, lineHeight, top(height), bottom(height));
	}

	function clearOf(y as Number, lineHeight as Number, bandTop as Number, bandBottom as Number) as Number {
		return ((y + lineHeight > bandTop) && (y < bandBottom)) ? bandBottom : y;
	}

	// The top of a block size tall whose centered top is blockTop: raised by
	// half the band when the block would cross it, so it stays centered with
	// the band inside it.
	function centered(blockTop as Number, size as Number, height as Number) as Number {
		return centeredOf(blockTop, size, top(height), bottom(height));
	}

	function centeredOf(blockTop as Number, size as Number, bandTop as Number, bandBottom as Number) as Number {
		return ((blockTop + size > bandTop) && (blockTop < bandBottom)) ? blockTop - (bandBottom - bandTop) / 2 : blockTop;
	}

	// The tops of items of these heights spread evenly from top to bottom, with
	// equal gaps before, between, and after them; packed from top if they do
	// not fit.
	function spreadOf(heights as Array<Number>, top as Number, bottom as Number) as Array<Number> {
		var total = 0;
		for (var index = 0; index < heights.size(); index++) {
			total += heights[index];
		}
		var gap = (bottom - top - total) / (heights.size() + 1);
		if (gap < 0) {
			gap = 0;
		}
		var result = [] as Array<Number>;
		var y = top + gap;
		for (var index = 0; index < heights.size(); index++) {
			result.add(y);
			y += heights[index] + gap;
		}
		return result;
	}

	// The workout screen: the name and the countdown, in the largest number
	// font that fits, above the band; Paused, the time left, and the interval
	// count below it. labels are the name, countdown, Paused, time left, and
	// interval count.
	function layoutWorkout(dc as Graphics.Dc, labels as Array<WatchUi.Text>) as Void {
		var height = dc.getHeight();
		var margin = height * 4 / 100;
		var numbers = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD] as Array<Graphics.FontType>;
		var numberHeights = [] as Array<Number>;
		for (var index = 0; index < numbers.size(); index++) {
			numberHeights.add(dc.getFontHeight(numbers[index]));
		}
		var nameHeight = dc.getFontHeight(Graphics.FONT_SMALL);
		var number = numbers[TitleFit.firstFitting(numberHeights, top(height) - margin - nameHeight)];
		var fonts = [Graphics.FONT_SMALL, number, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_SMALL] as Array<Graphics.FontType>;
		if (2 * nameHeight + dc.getFontHeight(Graphics.FONT_TINY) > height - margin - bottom(height)) {
			fonts = [Graphics.FONT_SMALL, number, Graphics.FONT_TINY, Graphics.FONT_XTINY, Graphics.FONT_TINY] as Array<Graphics.FontType>;
		}
		var heights = [] as Array<Number>;
		for (var index = 0; index < fonts.size(); index++) {
			heights.add(dc.getFontHeight(fonts[index]));
		}
		var tops = spreadOf(heights.slice(0, 2), margin, top(height));
		tops.addAll(spreadOf(heights.slice(2, null), bottom(height), height - margin));
		for (var index = 0; index < labels.size(); index++) {
			labels[index].setFont(fonts[index]);
			labels[index].setLocation(labels[index].locX, tops[index]);
		}
	}

	// Add workout's date screen: the middles of the date (FONT_LARGE) and the
	// day word (FONT_TINY), and the tip of the down arrow, below the band.
	function dateRows(dc as Graphics.Dc, arrow as Number) as Array<Number>? {
		var height = dc.getHeight();
		var dateHeight = dc.getFontHeight(Graphics.FONT_LARGE);
		var dayHeight = dc.getFontHeight(Graphics.FONT_TINY);
		var tops = spreadOf([dateHeight, dayHeight, arrow] as Array<Number>, bottom(height), height * 96 / 100);
		return [tops[0] + dateHeight / 2, tops[1] + dayHeight / 2, tops[2] + arrow] as Array<Number>;
	}
}

// Every other watch: no hands, so nothing moves.
(:noHands)
module HandsBand {
	function halfHeight() as Number {
		return 0;
	}

	function clear(y as Number, lineHeight as Number, height as Number) as Number {
		return y;
	}

	function centered(blockTop as Number, size as Number, height as Number) as Number {
		return blockTop;
	}

	function layoutWorkout(dc as Graphics.Dc, labels as Array<WatchUi.Text>) as Void {
	}

	function dateRows(dc as Graphics.Dc, arrow as Number) as Array<Number>? {
		return null;
	}
}
