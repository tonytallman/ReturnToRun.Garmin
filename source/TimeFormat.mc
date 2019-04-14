function getTimeAsString(time) {
    var minutes = time / 60;
    var seconds = time % 60;
    return minutes + ":" + zeroPadded(seconds);
}
    
function zeroPadded(value) {
	return ((value < 10) ? "0" : "") + value;
}
