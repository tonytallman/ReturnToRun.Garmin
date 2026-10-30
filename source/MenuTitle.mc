import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The :title for a Menu2. On most watches it is the text, drawn by the system
// menu. On watches whose system menu wraps a title such as "Return to Run" onto
// a second line and cuts it off, or whose subscreen clips it (the Instincts),
// monkey.jungle adds resources-menu-title, which
// turns DrawnMenuTitles on, and the title is a FittedMenuTitle instead.
module MenuTitle {
	function of(text as String) as String or WatchUi.Drawable {
		var setting = Application.loadResource(Rez.JsonData.DrawnMenuTitles);
		if (setting instanceof Dictionary && setting["drawn"] == true) {
			return new FittedMenuTitle(text);
		}
		return text;
	}
}

// A menu title kept on one line: centered in the title area the system menu
// gives it, in the largest font that fits that area's width (TitleFit). The
// area is narrower than the screen: 114 of 208 pixels on the Forerunner 55.
class FittedMenuTitle extends WatchUi.Drawable {
	const FONTS = [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<Graphics.FontType>;

	var text as String;

	function initialize(text as String) {
		Drawable.initialize({});
		self.text = text;
	}

	function draw(dc as Graphics.Dc) as Void {
		var y = dc.getHeight() / 2;
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();
		if (Subscreen.box() != null) {
			// On the Instinct, left of the subscreen, or on two lines.
			TitleFit.draw(dc, text, y, FONTS);
			return;
		}
		var font = TitleFit.fontWithin(dc, text, dc.getWidth(), FONTS);
		dc.drawText(dc.getWidth() / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
}
