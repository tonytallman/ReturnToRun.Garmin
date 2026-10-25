import Toybox.Lang;
import Toybox.Test;

(:test)
function testWorkoutSession(logger as Test.Logger) as Boolean {
	logger.debug("workout session");
	var session = new WorkoutSession.Machine();
	TestSupport.expectTrue(session.isTiming(), "starts running");
	TestSupport.expectFalse(session.showsPaused(), "not paused yet");

	TestSupport.expectEqual(WorkoutSession.PAUSE, session.onSelect(), "select pauses");
	TestSupport.expectEqual(WorkoutSession.PAUSED, session.state, "paused state");
	TestSupport.expectFalse(session.isTiming(), "timer stops");
	TestSupport.expectTrue(session.showsPaused(), "paused is visible");

	TestSupport.expectEqual(WorkoutSession.RESUME, session.onSelect(), "select resumes");
	TestSupport.expectTrue(session.isTiming(), "timer runs again");
	TestSupport.expectFalse(session.showsPaused(), "pause label hides");

	TestSupport.expectEqual(WorkoutSession.PAUSE, session.onBack(), "back while running pauses");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onDiscard(), "discard does nothing until it was asked");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onSaveEarly(), "save does nothing until it was asked");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onResumeFromEnd(), "resume answer does nothing until it was asked");
	TestSupport.expectEqual(WorkoutSession.PAUSED, session.state, "still paused");
	TestSupport.expectEqual(WorkoutSession.ASK_TO_END, session.onBack(), "back while paused asks to end");
	TestSupport.expectEqual(WorkoutSession.CONFIRMING_END, session.state, "waiting for the answer");
	TestSupport.expectFalse(session.isTiming(), "still not timing");
	TestSupport.expectTrue(session.showsPaused(), "stays paused under the prompt");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onSelect(), "select does not answer the prompt");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onBack(), "back on the workout does not answer the prompt");

	TestSupport.expectEqual(WorkoutSession.KEEP_PAUSED, session.onDeclineEnd(), "back on the prompt keeps the workout");
	TestSupport.expectEqual(WorkoutSession.PAUSED, session.state, "back to paused");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onDeclineEnd(), "a second back is ignored");
	TestSupport.expectEqual(WorkoutSession.RESUME, session.onSelect(), "select after decline resumes");

	session.onBack();
	session.onBack();
	TestSupport.expectEqual(WorkoutSession.RESUME, session.onResumeFromEnd(), "resume on the prompt");
	TestSupport.expectTrue(session.isTiming(), "timing again");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onResumeFromEnd(), "a second resume is ignored");
	return true;
}

(:test)
function testWorkoutSessionEndings(logger as Test.Logger) as Boolean {
	logger.debug("workout session endings");
	var discarded = new WorkoutSession.Machine();
	discarded.onBack();
	discarded.onBack();
	TestSupport.expectEqual(WorkoutSession.DISCARD, discarded.onDiscard(), "discard");
	TestSupport.expectEqual(WorkoutSession.FINISHED, discarded.state, "finished");
	TestSupport.expectFalse(discarded.isTiming(), "finished does not time");
	TestSupport.expectFalse(discarded.showsPaused(), "finished is not the paused label");
	TestSupport.expectEqual(WorkoutSession.NONE, discarded.onDiscard(), "a second discard is ignored");
	TestSupport.expectEqual(WorkoutSession.NONE, discarded.onRated(), "a discarded run is never rated");
	TestSupport.expectEqual(WorkoutSession.NONE, discarded.onCompleted(), "no completion after discard");
	TestSupport.expectEqual(WorkoutSession.NONE, discarded.onSelect(), "select after the end");
	TestSupport.expectEqual(WorkoutSession.NONE, discarded.onBack(), "back after the end");

	var saved = new WorkoutSession.Machine();
	saved.onBack();
	saved.onBack();
	TestSupport.expectEqual(WorkoutSession.SAVE, saved.onSaveEarly(), "save early");
	TestSupport.expectEqual(WorkoutSession.RATING, saved.state, "rating next");
	TestSupport.expectFalse(saved.isTiming(), "rating does not time");
	TestSupport.expectEqual(WorkoutSession.NONE, saved.onSaveEarly(), "a second save is ignored");
	TestSupport.expectEqual(WorkoutSession.NONE, saved.onDiscard(), "discard after save is ignored");
	TestSupport.expectEqual(WorkoutSession.NONE, saved.onBack(), "back does not leave the rating");
	TestSupport.expectEqual(WorkoutSession.LOG, saved.onRated(), "rating logs");
	TestSupport.expectEqual(WorkoutSession.FINISHED, saved.state, "finished after the rating");
	TestSupport.expectEqual(WorkoutSession.NONE, saved.onRated(), "a double select logs once");

	var done = new WorkoutSession.Machine();
	TestSupport.expectEqual(WorkoutSession.COMPLETE, done.onCompleted(), "the last segment completes");
	TestSupport.expectEqual(WorkoutSession.RATING, done.state, "rating next");
	TestSupport.expectFalse(done.isTiming(), "a completed workout does not keep ticking");
	TestSupport.expectEqual(WorkoutSession.NONE, done.onCompleted(), "completion applies once");
	TestSupport.expectEqual(WorkoutSession.NONE, done.onSelect(), "select on the rating does not resume");
	TestSupport.expectEqual(WorkoutSession.LOG, done.onRated(), "rating logs");

	var asking = new WorkoutSession.Machine();
	asking.onBack();
	asking.onBack();
	TestSupport.expectEqual(WorkoutSession.NONE, asking.onCompleted(), "the timer is stopped while the prompt is up");
	return true;
}
