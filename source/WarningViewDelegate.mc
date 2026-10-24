import Toybox.Lang;
import Toybox.WatchUi;

class WarningViewDelegate extends WatchUi.BehaviorDelegate {
	var warningView as WarningView;

	function initialize(warningView as WarningView) {
		BehaviorDelegate.initialize();
		self.warningView = warningView;
	}

	function onSelect() as Boolean {
		warningView.activate();
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
