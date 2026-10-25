import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// One pre-run warning on a round-screen page, with Continue and Cancel.
// Continue moves to the next warning, then to the workout.
// Positions are fractions of the display so the text stays inside the circle.
class WarningView extends WatchUi.View {
	var workoutIndex as Number;
	var warnings as Array<Number>;
	var position as Number;
	var message as String;
	var continueText as String;
	var cancelText as String;
	var focusContinue as Boolean;
	var closed as Boolean;
	var leaveTimer as LeaveTimer;

	function initialize(workoutIndex as Number, warnings as Array<Number>, position as Number) {
		View.initialize();
		self.workoutIndex = workoutIndex;
		self.warnings = warnings;
		self.position = position;
		focusContinue = true;
		closed = false;
		leaveTimer = new LeaveTimer();
		var oncePerDay = WatchUi.loadResource(Rez.Strings.OncePerDayWarning) as String;
		var sixPerWeek = WatchUi.loadResource(Rez.Strings.SixPerWeekWarning) as String;
		var text = WarningMessages.messageFor(warnings[position] as Number, oncePerDay, sixPerWeek);
		message = (text != null) ? text as String : "";
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

		// The message alone, wrapped to fit the wide middle of the round face.
		// There is no title, so a full sentence has room for four lines.
		var wrapped = TextWrap.wrap(message, width * 84 / 100, new DcTextMeasure(dc, Graphics.FONT_XTINY));
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, height * 37 / 100, Graphics.FONT_XTINY, wrapped, center);

		// The highlight bar and the focused action share one center line.
		var continueY = height * 70 / 100;
		var cancelY = height * 84 / 100;
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
		continuePastWarning(workoutIndex, warnings, position);
	}

	function cancel() as Void {
		if (closed) {
			return;
		}
		closed = true;
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}
