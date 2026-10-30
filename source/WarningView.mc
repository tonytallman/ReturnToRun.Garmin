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
	var screenHeight as Number;

	function initialize(workoutIndex as Number, warnings as Array<Number>, position as Number) {
		View.initialize();
		self.workoutIndex = workoutIndex;
		self.warnings = warnings;
		self.position = position;
		focusContinue = true;
		closed = false;
		leaveTimer = new LeaveTimer();
		screenHeight = 0;
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
		screenHeight = height;
		var centerX = width / 2;
		var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		// The message alone, wrapped to fit the wide middle of the round face.
		// There is no title, so a full sentence has room for four lines.
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		var barHeight = dc.getFontHeight(Graphics.FONT_SMALL) + 4;
		var messageBottom = Subscreen.drawMessage(dc, message, height * 37 / 100, 84, height * 16 / 100, height * 97 / 100 - 2 * barHeight);

		// The highlight bar and the focused action share one center line.
		var continueY = WarningLayout.continueY(height);
		var cancelY = WarningLayout.cancelY(height);
		var barWidth = width * 58 / 100;
		// On the Instinct, a message wrapped beside the subscreen can run longer,
		// so both actions move down below it; on the Instinct Crossover, below a
		// message that continues under the hands. (These watches have no touch.)
		var overlap = messageBottom + barHeight / 2 + 2 - continueY;
		if ((overlap > 0) && ((Subscreen.box() != null) || (HandsBand.halfHeight() > 0))) {
			continueY += overlap;
			cancelY += overlap;
		}
		var focusY = focusContinue ? continueY : cancelY;
		dc.setColor(Palette.focusBar(), Graphics.COLOR_TRANSPARENT);
		dc.fillRectangle((width - barWidth) / 2, focusY - (barHeight / 2), barWidth, barHeight);

		dc.setColor(focusContinue ? Palette.focusText() : Palette.dim(), Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, continueY, Graphics.FONT_SMALL, continueText, center);
		dc.setColor(focusContinue ? Palette.dim() : Palette.focusText(), Graphics.COLOR_TRANSPARENT);
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

	// A tap at height y: Continue or Cancel if it hits one (WarningLayout).
	function chooseAt(y as Number) as Void {
		var row = WarningLayout.rowAt(y, screenHeight);
		if (row == WarningLayout.ROW_CONTINUE) {
			focusContinue = true;
			activate();
		} else if (row == WarningLayout.ROW_CANCEL) {
			cancel();
		}
	}

	function cancel() as Void {
		if (closed) {
			return;
		}
		closed = true;
		appServices().log.note("warning cancelled");
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}
