import Toybox.Lang;

function getTimeAsString(time as Number) as String {
	var duration = time;
	if (duration < 0) {
		duration = 0;
	}
	var minutes = duration / 60;
	var seconds = duration % 60;
	return minutes.toString() + ":" + zeroPadded(seconds);
}

function zeroPadded(value as Number) as String {
	var text = value.toString();
	if (value < 10) {
		text = "0" + text;
	}
	return text;
}
