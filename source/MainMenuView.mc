import Toybox.Lang;
import Toybox.WatchUi;

class MainMenuView extends WatchUi.Menu2 {
	function initialize() {
		var title = WatchUi.loadResource(Rez.Strings.AppName) as String;
		var label = WatchUi.loadResource(Rez.Strings.Run) as String;
		Menu2.initialize({:title=>title});
		addItem(new WatchUi.MenuItem(label, null, :run, null));
	}

	function onShow() as Void {
		ScreenStack.atMainMenu();
	}
}
