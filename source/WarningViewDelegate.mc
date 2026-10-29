import Toybox.Lang;
import Toybox.WatchUi;

class WarningViewDelegate extends StartActionDelegate {
	var warningView as WarningView;

	function initialize(warningView as WarningView, touchPolicy as TouchPolicy) {
		StartActionDelegate.initialize(touchPolicy);
		self.warningView = warningView;
	}

	function onStartAction() as Void {
		warningView.activate();
	}

	// A tap chooses the action under it, whichever one has the focus.
	function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
		warningView.chooseAt(clickEvent.getCoordinates()[1] as Number);
		return true;
	}

	function onBack() as Boolean {
		warningView.cancel();
		return true;
	}

	function onNextPage() as Boolean {
		warningView.focusOnCancel();
		return true;
	}

	function onPreviousPage() as Boolean {
		warningView.focusOnContinue();
		return true;
	}
}
