import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;

// Colors that stay visible on every screen. The black-and-white Instinct
// screens (resources-mono turns Monochrome on) show green and blue as black and
// gray and yellow as white, so there titles, the paused countdown, and dim text
// are white, and the focused Warning action is drawn black on a white bar.
module Palette {
	var mono as Boolean? = null;

	function isMono() as Boolean {
		if (mono == null) {
			var setting = Application.loadResource(Rez.JsonData.Monochrome);
			mono = setting instanceof Dictionary && setting["mono"] == true;
		}
		return mono as Boolean;
	}

	function title() as Graphics.ColorType {
		return isMono() ? Graphics.COLOR_WHITE : Graphics.COLOR_GREEN;
	}

	function paused() as Graphics.ColorType {
		return isMono() ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW;
	}

	function dim() as Graphics.ColorType {
		return isMono() ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
	}

	function focusBar() as Graphics.ColorType {
		return isMono() ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_BLUE;
	}

	function focusText() as Graphics.ColorType {
		return isMono() ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
	}
}
