import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// The watch's own words for History: localized month and weekday names and
// the four rating words. Each month name is looked up at most once per list,
// so building a long list does no date work per entry.
class HistoryWords {
	var ratings as Array<String>;
	private var months as Array<String?>;

	function initialize() {
		ratings = [
			WatchUi.loadResource(Rez.Strings.RatingBad) as String,
			WatchUi.loadResource(Rez.Strings.RatingOk) as String,
			WatchUi.loadResource(Rez.Strings.RatingGood) as String,
			WatchUi.loadResource(Rez.Strings.RatingGreat) as String
		] as Array<String>;
		months = new Array<String?>[13];
	}

	function rating(value as Number) as String {
		if (!Rating.isValid(value)) {
			return "?";
		}
		return ratings[value];
	}

	// Mid-month at noon UTC is the same month in every time zone.
	function month(value as Number) as String {
		if ((value < 1) || (value > 12)) {
			return "?";
		}
		var cached = months[value];
		if (cached != null) {
			return cached as String;
		}
		var moment = Gregorian.moment({:year=>2001, :month=>value, :day=>15, :hour=>12, :minute=>0, :second=>0});
		var name = Gregorian.info(moment, Time.FORMAT_MEDIUM).month as String;
		months[value] = name;
		return name;
	}

	function shortDate(day as CalendarDay) as String {
		return HistoryFormat.shortDate(month(day.month), day.day);
	}

	function entryLabel(entry as HistoryEntry) as String {
		return HistoryFormat.entryLabel(month(entry.date.month), entry.date.day, entry.workoutId, rating(entry.rating));
	}

	// Local noon on a day some days before today, so a daylight-saving hour
	// cannot move it to another day.
	static function weekdayDaysAgo(daysBack as Number) as String {
		var noon = Time.today().add(new Time.Duration(43200 - (daysBack * 86400)));
		return Gregorian.info(noon, Time.FORMAT_MEDIUM).day_of_week as String;
	}
}
