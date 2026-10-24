import Toybox.Lang;

// One short beep at each of the last five seconds of a segment (5, 4, 3, 2, 1).
// Second 0 is when the next segment starts, so it is not a countdown beep.
module CountdownTones {
	const LAST_SECONDS = 5;

	function shouldPlay(secondsRemaining as Number) as Boolean {
		return (secondsRemaining >= 1) && (secondsRemaining <= LAST_SECONDS);
	}
}
