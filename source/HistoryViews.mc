import Toybox.Lang;
import Toybox.WatchUi;

function openHistory() as Void {
	var list = new HistoryListView();
	WatchUi.pushView(list, new HistoryListDelegate(list), WatchUi.SLIDE_LEFT);
}

// Every saved workout, newest first, then Clear history and Add workout.
// Items are built from the stored numbers with cached words, so a full history
// stays cheap. After an edit the list rebuilds itself when it shows again.
// While a screen opened from the list is showing (an entry's details and its
// rating picker, Clear history, or Add workout), the list's items are released
// to free memory, and the list is rebuilt with the same item in focus on return.
class HistoryListView extends WatchUi.Menu2 {
	var leaveTimer as LeaveTimer;
	var builtVersion as Number;
	var builtItems as Number;
	var releaseWhenHidden as Boolean;

	function initialize() {
		Menu2.initialize({:title=>WatchUi.loadResource(Rez.Strings.History) as String});
		leaveTimer = new LeaveTimer();
		builtVersion = -1;
		builtItems = 0;
		releaseWhenHidden = false;
		appServices().historyFocus = 0;
		build();
	}

	function build() as Void {
		var services = appServices();
		var words = new HistoryWords();
		var count = services.historySize();
		for (var index = 0; index < count; index++) {
			var entry = services.historyEntryAt(index);
			if (entry != null) {
				addItem(new WatchUi.MenuItem(words.entryLabel(entry as HistoryEntry), null, index, null));
			}
		}
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ClearHistory) as String, null, :clear, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.AddWorkout) as String, null, :add, null));
		builtItems = HistoryFormat.itemCount(count);
		builtVersion = services.historyVersion;
		setFocus(HistoryFormat.clampFocus(services.historyFocus, count));
	}

	function release() as Void {
		for (var index = builtItems - 1; index >= 0; index--) {
			deleteItem(index);
		}
		builtItems = 0;
	}

	// Called with the selected item's position just before a screen opens over
	// the list. Menu2 cannot report its focus later, so it is kept here.
	function releaseOnHide(focus as Number) as Void {
		appServices().historyFocus = focus;
		releaseWhenHidden = true;
	}

	function onHide() as Void {
		if (releaseWhenHidden) {
			releaseWhenHidden = false;
			release();
		}
	}

	function onShow() as Void {
		ScreenStack.atHistory();
		if (leaveTimer.schedule()) {
			return;
		}
		if ((builtItems == 0) || (appServices().historyVersion != builtVersion)) {
			release();
			build();
		}
	}
}

class HistoryListDelegate extends WatchUi.Menu2InputDelegate {
	var list as HistoryListView;

	function initialize(list as HistoryListView) {
		Menu2InputDelegate.initialize();
		self.list = list;
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var id = item.getId();
		var count = appServices().historySize();
		if (id instanceof Number) {
			list.releaseOnHide(id as Number);
			var view = new HistoryDetailsView(id as Number);
			WatchUi.pushView(view, new HistoryDetailsDelegate(id as Number), WatchUi.SLIDE_LEFT);
		} else if (id == :clear) {
			list.releaseOnHide(HistoryFormat.clearPosition(count));
			confirmHistoryChange(Rez.Strings.ConfirmClear, HistoryConfirmDelegate.CLEAR, 0);
		} else if (id == :add) {
			list.releaseOnHide(HistoryFormat.addPosition(count));
			var stepper = new DateStepper(appServices().currentDay());
			var dateView = new AddDateView(stepper);
			WatchUi.pushView(dateView, new AddDateDelegate(dateView), WatchUi.SLIDE_LEFT);
		}
	}
}

// Workout details: the entry's date and workout as the title, then its rating,
// Delete, and Delete this & older. Any change returns to the History list.
class HistoryDetailsView extends WatchUi.Menu2 {
	var leaveTimer as LeaveTimer;

	function initialize(index as Number) {
		var services = appServices();
		var words = new HistoryWords();
		var entry = services.historyEntryAt(index);
		var title = "";
		var ratingWord = "";
		if (entry != null) {
			var found = entry as HistoryEntry;
			title = words.shortDate(found.date) + "  #" + found.workoutId.toString();
			ratingWord = words.rating(found.rating);
		}
		Menu2.initialize({:title=>title});
		leaveTimer = new LeaveTimer();
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.RatingLabel) as String, ratingWord, :rating, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.Delete) as String, null, :delete, null));
		addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.DeleteOlder) as String, null, :deleteOlder, null));
	}

	function onShow() as Void {
		leaveTimer.schedule();
	}
}

class HistoryDetailsDelegate extends WatchUi.Menu2InputDelegate {
	var index as Number;

	function initialize(index as Number) {
		Menu2InputDelegate.initialize();
		self.index = index;
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var id = item.getId();
		if (id == :rating) {
			var entry = appServices().historyEntryAt(index);
			var current = (entry == null) ? Rating.GOOD : (entry as HistoryEntry).rating;
			WatchUi.pushView(new RatingPicker(current), new HistoryRatingDelegate(index), WatchUi.SLIDE_LEFT);
		} else if (id == :delete) {
			confirmHistoryChange(Rez.Strings.ConfirmDelete, HistoryConfirmDelegate.DELETE, index);
		} else if (id == :deleteOlder) {
			confirmHistoryChange(Rez.Strings.ConfirmDeleteOlder, HistoryConfirmDelegate.DELETE_OLDER, index);
		}
	}
}

// Prompts stay short because the standard confirmation truncates long text.
function confirmHistoryChange(prompt as ResourceId, action as Number, index as Number) as Void {
	var text = WatchUi.loadResource(prompt) as String;
	WatchUi.pushView(new WatchUi.Confirmation(text), new HistoryConfirmDelegate(action, index), WatchUi.SLIDE_IMMEDIATE);
}

// The confirmation closes itself. A delete asks the details screen under it
// to return to the list; Clear history was opened from the list itself.
class HistoryConfirmDelegate extends WatchUi.ConfirmationDelegate {
	static const CLEAR = 0;
	static const DELETE = 1;
	static const DELETE_OLDER = 2;

	var action as Number;
	var index as Number;

	function initialize(action as Number, index as Number) {
		ConfirmationDelegate.initialize();
		self.action = action;
		self.index = index;
	}

	function onResponse(response as WatchUi.Confirm) as Boolean {
		if (response != WatchUi.CONFIRM_YES) {
			return true;
		}
		var services = appServices();
		if (action == CLEAR) {
			services.clearHistory();
			return true;
		}
		if (action == DELETE) {
			services.deleteHistoryAt(index);
		} else {
			services.deleteHistoryAtAndOlder(index);
		}
		ScreenStack.requestReturnToHistory();
		return true;
	}
}

// Changing a rating. On the newest entry it uses the same program-complete
// rule as rating a finished run, and the screen shows at most once per program.
// Back closes the picker and changes nothing.
class HistoryRatingDelegate extends WatchUi.PickerDelegate {
	var index as Number;

	function initialize(index as Number) {
		PickerDelegate.initialize();
		self.index = index;
	}

	function onAccept(values as Array) as Boolean {
		var rating = RatingChoices.fromPicked(values);
		if (rating == null) {
			return true;
		}
		var show = appServices().changeHistoryRating(index, rating as Number);
		finishHistoryEdit(show);
		return true;
	}

	function onCancel() as Boolean {
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
		return true;
	}
}

// After a History edit made from a pushed screen: show program complete once
// if the edit finished the program, then return to the History list.
function finishHistoryEdit(showProgramComplete as Boolean) as Void {
	ScreenStack.requestReturnToHistory();
	if (showProgramComplete) {
		appServices().markProgramCompleteShown();
		WatchUi.switchToView(new ProgramCompleteView(), new ProgramCompleteDelegate(true), WatchUi.SLIDE_LEFT);
		return;
	}
	WatchUi.popView(WatchUi.SLIDE_RIGHT);
}
