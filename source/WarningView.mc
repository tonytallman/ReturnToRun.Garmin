import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// All pre-run warnings on one round-screen page, with Continue and Cancel.
// Positions are fractions of the display so the text stays inside the circle.
class WarningView extends WatchUi.View {
	var workoutIndex as Number;
	var message as String;
	var titleText as String;
	var continueText as String;
	var cancelText as String;
	var focusContinue as Boolean;
	var closed as Boolean;
	var leaveTimer as LeaveTimer;
	var titleLabel as WatchUi.Text?;
	var body as WatchUi.TextArea?;
	var continueLabel as WatchUi.Text?;
	var cancelLabel as WatchUi.Text?;

	function initialize(workoutIndex as Number, warnings as Array<Number>) {
		View.initialize();
		self.workoutIndex = workoutIndex;
		focusContinue = true;
		closed = false;
		leaveTimer = new LeaveTimer();
		var alreadyRan = WatchUi.loadResource(Rez.Strings.AlreadyRanToday) as String;
		var restDay = WatchUi.loadResource(Rez.Strings.RestDayRecommended) as String;
		var tooFew = WatchUi.loadResource(Rez.Strings.TooFewRecentRuns) as String;
		message = WarningMessages.textFor(warnings, alreadyRan, restDay, tooFew);
		titleText = WatchUi.loadResource(Rez.Strings.WarningTitle) as String;
		continueText = WatchUi.loadResource(Rez.Strings.Continue) as String;
		cancelText = WatchUi.loadResource(Rez.Strings.Cancel) as String;
	}

	function onLayout(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var textWidth = width * 70 / 100;
		titleLabel = new WatchUi.Text({
			:text=>titleText,
			:color=>Graphics.COLOR_WHITE,
			:font=>Graphics.FONT_TINY,
			:justification=>Graphics.TEXT_JUSTIFY_CENTER,
			:locX=>WatchUi.LAYOUT_HALIGN_CENTER,
			:locY=>height * 8 / 100
		});
		body = new WatchUi.TextArea({
			:text=>message,
			:color=>Graphics.COLOR_WHITE,
			:font=>Graphics.FONT_TINY,
			:justification=>Graphics.TEXT_JUSTIFY_CENTER,
			:locX=>WatchUi.LAYOUT_HALIGN_CENTER,
			:locY=>height * 16 / 100,
			:width=>textWidth,
			:height=>height * 42 / 100
		});
		continueLabel = actionLabel(continueText, height * 66 / 100);
		cancelLabel = actionLabel(cancelText, height * 78 / 100);
	}

	function actionLabel(text as String, locY as Number) as WatchUi.Text {
		return new WatchUi.Text({
			:text=>text,
			:color=>Graphics.COLOR_WHITE,
			:font=>Graphics.FONT_SMALL,
			:justification=>(Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER),
			:locX=>WatchUi.LAYOUT_HALIGN_CENTER,
			:locY=>locY
		});
	}

	function onShow() as Void {
		leaveTimer.schedule();
	}

	function onUpdate(dc as Graphics.Dc) as Void {
		var width = dc.getWidth();
		var height = dc.getHeight();
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		var barWidth = width * 58 / 100;
		var barHeight = height * 12 / 100;
		var barLeft = (width - barWidth) / 2;
		var centerY = height * 66 / 100;
		if (!focusContinue) {
			centerY = height * 78 / 100;
		}
		dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_BLACK);
		dc.fillRectangle(barLeft, centerY - (barHeight / 2), barWidth, barHeight);

		if (titleLabel != null) {
			(titleLabel as WatchUi.Text).draw(dc);
		}
		if (body != null) {
			(body as WatchUi.TextArea).draw(dc);
		}
		if ((continueLabel != null) && (cancelLabel != null)) {
			var continueDraw = continueLabel as WatchUi.Text;
			var cancelDraw = cancelLabel as WatchUi.Text;
			if (focusContinue) {
				continueDraw.setColor(Graphics.COLOR_WHITE);
				cancelDraw.setColor(Graphics.COLOR_LT_GRAY);
			} else {
				continueDraw.setColor(Graphics.COLOR_LT_GRAY);
				cancelDraw.setColor(Graphics.COLOR_WHITE);
			}
			continueDraw.draw(dc);
			cancelDraw.draw(dc);
		}
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
