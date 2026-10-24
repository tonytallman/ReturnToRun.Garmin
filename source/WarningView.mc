import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// All pre-run warnings on one round-screen page, with Continue and Cancel.
// Positions are fractions of the display so the text stays inside the circle.
class WarningView extends WatchUi.View {
	var workoutIndex as Number;
	var lines as Array<String>;
	var titleText as String;
	var continueText as String;
	var cancelText as String;
	var focusContinue as Boolean;
	var closed as Boolean;
	var leaveTimer as LeaveTimer;

	function initialize(workoutIndex as Number, warnings as Array<Number>) {
		View.initialize();
		self.workoutIndex = workoutIndex;
		focusContinue = true;
		closed = false;
		leaveTimer = new LeaveTimer();
		var alreadyRan = WatchUi.loadResource(Rez.Strings.AlreadyRanToday) as String;
		var restDay = WatchUi.loadResource(Rez.Strings.RestDayRecommended) as String;
		var tooFew = WatchUi.loadResource(Rez.Strings.TooFewRecentRuns) as String;
		lines = [] as Array<String>;
		for (var index = 0; index < warnings.size(); index++) {
			var line = WarningMessages.lineFor(warnings[index] as Number, alreadyRan, restDay, tooFew);
			if (line != null) {
				lines.add(line as String);
			}
		}
		titleText = WatchUi.loadResource(Rez.Strings.WarningTitle) as String;
		continueText = WatchUi.loadResource(Rez.Strings.Continue) as String;
		cancelText = WatchUi.loadResource(Rez.Strings.Cancel) as String;
	}

	function onShow() as Void {
		leaveTimer.schedule();
	}

	function onUpdate(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var centerX = width / 2;
		var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		// Title, then one warning per line, each centered on its own row.
		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, height * 17 / 100, Graphics.FONT_XTINY, titleText, center);
		var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY);
		var lineY = (height * 17 / 100) + lineHeight + (lineHeight / 4);
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		for (var index = 0; index < lines.size(); index++) {
			dc.drawText(centerX, lineY, Graphics.FONT_XTINY, lines[index], center);
			lineY = lineY + lineHeight;
		}

		// The highlight bar and the focused action share one center line.
		var continueY = height * 68 / 100;
		var cancelY = height * 82 / 100;
		var focusY = focusContinue ? continueY : cancelY;
		var barWidth = width * 58 / 100;
		var barHeight = dc.getFontHeight(Graphics.FONT_SMALL) + 4;
		dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
		dc.fillRectangle((width - barWidth) / 2, focusY - (barHeight / 2), barWidth, barHeight);

		dc.setColor(focusContinue ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, continueY, Graphics.FONT_SMALL, continueText, center);
		dc.setColor(focusContinue ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, cancelY, Graphics.FONT_SMALL, cancelText, center);
	}

	function focusOnContinue() as Void {
		if (focusContinue) {
			return;
		}
		focusContinue = true;
		WatchUi.requestUpdate();
	}

	function focusOnCancel() as Void {
		if (!focusContinue) {
			return;
		}
		focusContinue = false;
		WatchUi.requestUpdate();
	}

	function activate() as Void {
		if (closed) {
			return;
		}
		if (!focusContinue) {
			cancel();
			return;
		}
		closed = true;
		startWorkout(workoutIndex);
	}

	function cancel() as Void {
		if (closed) {
			return;
		}
		closed = true;
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}
