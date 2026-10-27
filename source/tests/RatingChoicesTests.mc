import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// The rating picker's choices, start position, and picked value.
(:test)
function testRatingChoices(logger as Test.Logger) as Boolean {
	logger.debug("rating choices");
	TestSupport.expectEqual(4, RatingChoices.count(), "four ratings");
	TestSupport.expectEqual(Rating.BAD, RatingChoices.ratingAt(0), "top is Bad");
	TestSupport.expectEqual(Rating.OK, RatingChoices.ratingAt(1), "then OK");
	TestSupport.expectEqual(Rating.GOOD, RatingChoices.ratingAt(2), "then Good");
	TestSupport.expectEqual(Rating.GREAT, RatingChoices.ratingAt(3), "bottom is Great");
	TestSupport.expectNull(RatingChoices.ratingAt(4), "past the end");
	TestSupport.expectNull(RatingChoices.ratingAt(-1), "before the start");

	// Steps are unchanged: Bad back one, OK repeat, Good next, Great skip one.
	TestSupport.expectEqual(-1, Rating.step(RatingChoices.ratingAt(0) as Number), "Bad steps back one");
	TestSupport.expectEqual(0, Rating.step(RatingChoices.ratingAt(1) as Number), "OK repeats");
	TestSupport.expectEqual(1, Rating.step(RatingChoices.ratingAt(2) as Number), "Good moves on");
	TestSupport.expectEqual(2, Rating.step(RatingChoices.ratingAt(3) as Number), "Great skips one");

	TestSupport.expectEqual(Rating.GOOD, RatingChoices.ratingAt(RatingChoices.defaultIndex(Rating.GOOD)), "after a run: Good");
	TestSupport.expectEqual(0, RatingChoices.defaultIndex(Rating.BAD), "History entry rated Bad starts on Bad");
	TestSupport.expectEqual(3, RatingChoices.defaultIndex(Rating.GREAT), "History entry rated Great starts on Great");
	TestSupport.expectEqual(Rating.GOOD, RatingChoices.defaultIndex(7), "not a rating: Good");
	TestSupport.expectEqual(Rating.GOOD, RatingChoices.defaultIndex(-1), "negative: Good");
	TestSupport.expectEqual(Rating.GOOD, RatingChoices.defaultIndex(null), "none: Good");

	TestSupport.expectEqual(Rating.BAD, RatingChoices.fromPicked([0]), "picked Bad");
	TestSupport.expectEqual(Rating.GREAT, RatingChoices.fromPicked([3]), "picked Great");
	TestSupport.expectNull(RatingChoices.fromPicked([4]), "picked a value out of range");
	TestSupport.expectNull(RatingChoices.fromPicked(["Good"]), "picked a non-number");
	TestSupport.expectNull(RatingChoices.fromPicked([]), "picked nothing");
	TestSupport.expectNull(RatingChoices.fromPicked([1, 2]), "picked two values");
	TestSupport.expectNull(RatingChoices.fromPicked(null), "no values");

	for (var index = 0; index < RatingChoices.count(); index++) {
		var word = WatchUi.loadResource(RatingChoices.labelId(RatingChoices.ratingAt(index) as Number) as ResourceId) as String;
		TestSupport.expectTrue(word.length() > 0, "word for choice " + index.toString());
	}
	TestSupport.expectEqual("Bad", WatchUi.loadResource(RatingChoices.labelId(Rating.BAD) as ResourceId), "Bad word");
	TestSupport.expectEqual("Great", WatchUi.loadResource(RatingChoices.labelId(Rating.GREAT) as ResourceId), "Great word");
	TestSupport.expectNull(RatingChoices.labelId(9), "no word for a non-rating");
	return true;
}
