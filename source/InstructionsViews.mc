import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

function openTextPage(titleId as ResourceId, bodyId as ResourceId) as Void {
	var view = new TextPageView(WatchUi.loadResource(titleId) as String, WatchUi.loadResource(bodyId) as String);
	WatchUi.pushView(view, new TextPageDelegate(view), WatchUi.SLIDE_LEFT);
}

// The instruction topics. Each item opens one paged text screen.
class InstructionsMenu extends WatchUi.Menu2 {
	function initialize() {
		Menu2.initialize({:title=>WatchUi.loadResource(Rez.Strings.Instructions) as String});
		var topics = InstructionsMenu.topics();
		for (var i = 0; i < topics.size(); i++) {
			var topic = topics[i] as Array<ResourceId>;
			addItem(new WatchUi.MenuItem(WatchUi.loadResource(topic[0]) as String, null, i, null));
		}
	}

	// [title, body] string resources, in menu order.
	static function topics() as Array<Array<ResourceId> > {
		return [
			[Rez.Strings.HelpProgramTitle, Rez.Strings.HelpProgram],
			[Rez.Strings.HelpListTitle, Rez.Strings.HelpList],
			[Rez.Strings.HelpRatingsTitle, Rez.Strings.HelpRatings],
			[Rez.Strings.HelpDaysOffTitle, Rez.Strings.HelpDaysOff],
			[Rez.Strings.HelpWarningsTitle, Rez.Strings.HelpWarnings],
			[Rez.Strings.HelpButtonsTitle, Rez.Strings.HelpButtons]
		] as Array<Array<ResourceId> >;
	}
}

class InstructionsDelegate extends WatchUi.Menu2InputDelegate {
	function initialize() {
		Menu2InputDelegate.initialize();
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var topic = InstructionsMenu.topics()[item.getId() as Number] as Array<ResourceId>;
		openTextPage(topic[0], topic[1]);
	}
}

function openInstructions() as Void {
	WatchUi.pushView(new InstructionsMenu(), new InstructionsDelegate(), WatchUi.SLIDE_LEFT);
}

// About: app name, version, and the repository link as text. Start asks the
// phone (through Garmin Connect Mobile) to open the link.
function openAbout() as Void {
	var version = AppVersion.label(WatchUi.loadResource(Rez.Strings.VersionLabel) as String, WatchUi.loadResource(Rez.Strings.AppVersion) as String);
	var link = TextPages.breakAfterSlashes(WatchUi.loadResource(Rez.Strings.RepoLink) as String);
	var body = version + "||" + link;
	if (Communications has :openWebPage) {
		body += "||" + (WatchUi.loadResource(Rez.Strings.OpenOnPhoneHint) as String);
	}
	var view = new TextPageView(WatchUi.loadResource(Rez.Strings.AppName) as String, body);
	WatchUi.pushView(view, new AboutDelegate(view), WatchUi.SLIDE_LEFT);
}

class AboutDelegate extends TextPageDelegate {
	function initialize(view as TextPageView) {
		TextPageDelegate.initialize(view);
	}

	function onSelect() as Boolean {
		if (Communications has :openWebPage) {
			Communications.openWebPage("https://" + (WatchUi.loadResource(Rez.Strings.RepoLink) as String), null, null);
		}
		return true;
	}
}
