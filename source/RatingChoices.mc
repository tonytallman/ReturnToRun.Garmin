import Toybox.Lang;

// The rating picker's choices, without any UI: their order (Bad, OK, Good,
// Great; Up moves toward Great), which one starts selected, and the rating a picked
// value stands for. The picker only draws what this module says.
module RatingChoices {
	function count() as Number {
		return 4;
	}

	// The rating at a picker position. Positions match the Rating values.
	function ratingAt(index as Number) as Number? {
		if (Rating.isValid(index)) {
			return index;
		}
		return null;
	}

	// Where the picker starts: the given rating, or Good when it is not a rating.
	// After a run and when adding a workout that is Good; History starts on the
	// entry's own rating.
	function defaultIndex(rating as Number?) as Number {
		if ((rating instanceof Number) && Rating.isValid(rating as Number)) {
			return rating as Number;
		}
		return Rating.GOOD;
	}

	// The rating from the picker's accepted values, or null if it is not one.
	function fromPicked(values as Array?) as Number? {
		if ((values == null) || ((values as Array).size() != 1)) {
			return null;
		}
		var value = (values as Array)[0];
		if (!(value instanceof Number)) {
			return null;
		}
		return ratingAt(value as Number);
	}

	// The resource for each choice's word, in picker order.
	function labelId(rating as Number) as ResourceId? {
		if (rating == Rating.BAD) {
			return Rez.Strings.RatingBad;
		}
		if (rating == Rating.OK) {
			return Rez.Strings.RatingOk;
		}
		if (rating == Rating.GOOD) {
			return Rez.Strings.RatingGood;
		}
		if (rating == Rating.GREAT) {
			return Rez.Strings.RatingGreat;
		}
		return null;
	}
}
