import Toybox.Lang;
import Toybox.WatchUi;

class MainMenuView extends WatchUi.Menu2 {
	function initialize() {
		var title = WatchUi.loadResource(Rez.Strings.AppName) as String;
		var label = WatchUi.loadResource(Rez.Strings.Run) as String;
		Menu2.initialize({:title=>MenuTitle.of(title)});
		addItem(new WatchUi.MenuItem(label, null, :run, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.History) as String, null, :history, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.Instructions) as String, null, :instructions, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.About) as String, null, :about, null));
	}

	function onShow() as Void {
		ScreenStack.atMainMenu();
	}
}
