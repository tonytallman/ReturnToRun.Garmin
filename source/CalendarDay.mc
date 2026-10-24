import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// A local calendar day. Day arithmetic uses civil dates, so daylight saving
// cannot change the number of days between two logged runs.
class CalendarDay {
	var year as Number;
	var month as Number;
	var day as Number;

	function initialize(year as Number, month as Number, day as Number) {
		self.year = year;
		self.month = month;
		self.day = day;
	}

	static function today() as CalendarDay {
		var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		return new CalendarDay(info.year as Number, info.month as Number, info.day as Number);
	}

	function toNumber() as Number {
		return (year * 10000) + (month * 100) + day;
	}

	static function fromNumber(value as Number) as CalendarDay? {
		if ((value < 10000101) || (value > 99991231)) {
			return null;
		}
		var year = value / 10000;
		var month = (value / 100) % 100;
		var day = value % 100;
		if ((month < 1) || (month > 12) || (day < 1) || (day > CalendarDay.daysInMonth(year, month))) {
			return null;
		}
		return new CalendarDay(year, month, day);
	}

	// Negative when this day is before other, zero when they are the same day.
	function compare(other as CalendarDay) as Number {
		return toNumber() - other.toNumber();
	}

	// Civil days from this day until other. Negative when other is earlier.
	function daysUntil(other as CalendarDay) as Number {
		return CalendarDay.julianDay(other.year, other.month, other.day) - CalendarDay.julianDay(year, month, day);
	}

	function plusDays(offset as Number) as CalendarDay {
		var y = year;
		var m = month;
		var d = day + offset;
		while (d > CalendarDay.daysInMonth(y, m)) {
			d = d - CalendarDay.daysInMonth(y, m);
			m = m + 1;
			if (m > 12) {
				m = 1;
				y = y + 1;
			}
		}
		while (d < 1) {
			m = m - 1;
			if (m < 1) {
				m = 12;
				y = y - 1;
			}
			d = d + CalendarDay.daysInMonth(y, m);
		}
		return new CalendarDay(y, m, d);
	}

	static function daysInMonth(year as Number, month as Number) as Number {
		if (month == 2) {
			if (CalendarDay.isLeapYear(year)) {
				return 29;
			}
			return 28;
		}
		if ((month == 4) || (month == 6) || (month == 9) || (month == 11)) {
			return 30;
		}
		return 31;
	}

	static function isLeapYear(year as Number) as Boolean {
		if ((year % 400) == 0) {
			return true;
		}
		if ((year % 100) == 0) {
			return false;
		}
		return (year % 4) == 0;
	}

	// Fliegel and Van Flandern's civil-to-Julian day count. Verified against 1970-01-01 = 2440588.
	static function julianDay(year as Number, month as Number, day as Number) as Number {
		var a = (14 - month) / 12;
		var y = year + 4800 - a;
		var m = month + (12 * a) - 3;
		return day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045;
	}
}
