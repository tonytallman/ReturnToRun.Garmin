import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Add workout, step 1: the date. Starts at today; Down steps back a day and
// Up steps forward again, never past today. Select moves on to the workout.
// Positions are fractions of the display so the text stays inside the circle.
class AddDateView extends WatchUi.View {
	var stepper as DateStepper;
	var words as HistoryWords;
	var leaveTimer as LeaveTimer;
	var title as String;
	var todayWord as String;
	var yesterdayWord as String;

	function initialize(stepper as DateStepper) {
		View.initialize();
		self.stepper = stepper;
		words = new HistoryWords();
		leaveTimer = new LeaveTimer();
		title = WatchUi.loadResource(Rez.Strings.DateTitle) as String;
		todayWord = WatchUi.loadResource(Rez.Strings.Today) as String;
		yesterdayWord = WatchUi.loadResource(Rez.Strings.Yesterday) as String;
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

		dc.drawText(centerX, height * 18 / 100, Graphics.FONT_SMALL, title, center);
		dc.drawText(centerX, height * 50 / 100, Graphics.FONT_LARGE, words.shortDate(stepper.date()), center);

		var dayWord = stepper.isToday() ? todayWord : (stepper.isYesterday() ? yesterdayWord : HistoryWords.weekdayDaysAgo(stepper.daysBack));
		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		dc.drawText(centerX, height * 66 / 100, Graphics.FONT_TINY, dayWord, center);

		// Up arrow only when a later day is available; there is always an earlier one.
		var arrow = width * 4 / 100;
		if (!stepper.isToday()) {
			var upY = height * 31 / 100;
			dc.fillPolygon([[centerX - arrow, upY + arrow], [centerX + arrow, upY + arrow], [centerX, upY]]);
		}
		var downY = height * 79 / 100;
		dc.fillPolygon([[centerX - arrow, downY - arrow], [centerX + arrow, downY - arrow], [centerX, downY]]);
	}
}

class AddDateDelegate extends WatchUi.BehaviorDelegate {
	var view as AddDateView;

	function initialize(view as AddDateView) {
		BehaviorDelegate.initialize();
		self.view = view;
	}

	function onNextPage() as Boolean {
		view.stepper.earlier();
		WatchUi.requestUpdate();
		return true;
	}

	function onPreviousPage() as Boolean {
		if (view.stepper.later()) {
			WatchUi.requestUpdate();
		}
		return true;
	}

	function onSelect() as Boolean {
		var title = WatchUi.loadResource(Rez.Strings.WorkoutTitle) as String;
		WatchUi.pushView(new WorkoutListView(title), new AddWorkoutDelegate(view.stepper.date()), WatchUi.SLIDE_LEFT);
		return true;
	}
}

// Add workout, step 2: the workout, from the same list as Run.
class AddWorkoutDelegate extends WatchUi.Menu2InputDelegate {
	var date as CalendarDay;

	function initialize(date as CalendarDay) {
		Menu2InputDelegate.initialize();
		self.date = date;
	}

	function onSelect(item as WatchUi.MenuItem) as Void {
		var id = item.getId();
		if (id instanceof Number) {
			WatchUi.pushView(new RatingPicker(Rating.GOOD), new AddRatingDelegate(date, id as Number), WatchUi.SLIDE_LEFT);
		}
	}
}

// Add workout, step 3: the rating. Adds the entry and returns to History, or
// shows the too-old notice when a full history would not keep it.
// Back closes the picker and returns to the workout choice; nothing is added.
class AddRatingDelegate extends WatchUi.PickerDelegate {
	var date as CalendarDay;
	var workoutIndex as Number;

	function initialize(date as CalendarDay, workoutIndex as Number) {
		PickerDelegate.initialize();
		self.date = date;
		self.workoutIndex = workoutIndex;
	}

	function onAccept(values as Array) as Boolean {
		var rating = RatingChoices.fromPicked(values);
		if (rating == null) {
			return true;
		}
		var services = appServices();
		if (services.isTooOldForHistory(date)) {
			showAddTooOld();
			return true;
		}
		var show = services.addHistoryWorkout(date, workoutIndex, rating as Number);
		finishHistoryEdit(show);
		return true;
	}

	function onCancel() as Boolean {
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
		return true;
	}
}
