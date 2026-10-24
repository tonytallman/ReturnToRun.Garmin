import Toybox.Lang;

// How the latest logged workout moves the recommendation.
// Bad steps back one, OK repeats it, Good advances one, and Great skips one (ahead two).
module Rating {
	const BAD = 0;
	const OK = 1;
	const GOOD = 2;
	const GREAT = 3;

	function step(rating as Number) as Number {
		if (rating == BAD) {
			return -1;
		}
		if (rating == OK) {
			return 0;
		}
		if (rating == GOOD) {
			return 1;
		}
		if (rating == GREAT) {
			return 2;
		}
		return 0;
	}

	function isValid(rating as Number) as Boolean {
		return (rating == BAD) || (rating == OK) || (rating == GOOD) || (rating == GREAT);
	}
}
