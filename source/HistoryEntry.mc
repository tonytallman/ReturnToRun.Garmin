import Toybox.Lang;

class HistoryEntry {
	var date as CalendarDay;
	var workoutId as Number;
	var rating as Number;

	function initialize(date as CalendarDay, workoutId as Number, rating as Number) {
		self.date = date;
		self.workoutId = workoutId;
		self.rating = rating;
	}
}
