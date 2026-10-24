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
	TestSupport.expectEqual(WorkoutSession.NONE, session.onConfirmEnd(), "confirm does nothing until it was asked");
	TestSupport.expectEqual(WorkoutSession.PAUSED, session.state, "still paused");
	TestSupport.expectEqual(WorkoutSession.ASK_TO_END, session.onBack(), "back while paused asks to end");
	TestSupport.expectEqual(WorkoutSession.CONFIRMING_END, session.state, "waiting for the answer");
	TestSupport.expectFalse(session.isTiming(), "still not timing");
	TestSupport.expectTrue(session.showsPaused(), "stays paused under the confirm");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onSelect(), "select does not answer the confirm");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onBack(), "back does not answer the confirm");
	TestSupport.expectEqual(WorkoutSession.CONFIRMING_END, session.state, "still waiting");

	TestSupport.expectEqual(WorkoutSession.NONE, session.onDeclineEnd(), "decline keeps the workout");
	TestSupport.expectEqual(WorkoutSession.PAUSED, session.state, "back to paused");
	TestSupport.expectTrue(session.showsPaused(), "still shows paused");
	TestSupport.expectEqual(WorkoutSession.RESUME, session.onSelect(), "select after decline resumes");

	TestSupport.expectEqual(WorkoutSession.PAUSE, session.onBack(), "pause again");
	TestSupport.expectEqual(WorkoutSession.ASK_TO_END, session.onBack(), "ask again");
	TestSupport.expectEqual(WorkoutSession.DISCARD, session.onConfirmEnd(), "confirm ends without logging");
	TestSupport.expectEqual(WorkoutSession.FINISHED, session.state, "finished");
	TestSupport.expectFalse(session.isTiming(), "finished does not time");
	TestSupport.expectFalse(session.showsPaused(), "finished is not the paused label");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onSelect(), "select after the end");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onBack(), "back after the end");
	TestSupport.expectEqual(WorkoutSession.NONE, session.onDeclineEnd(), "decline after the end");

	var done = new WorkoutSession.Machine();
	done.onCompleted();
	TestSupport.expectEqual(WorkoutSession.FINISHED, done.state, "the last segment finishes the session");
	TestSupport.expectFalse(done.isTiming(), "a finished workout does not keep ticking");
	TestSupport.expectEqual(WorkoutSession.NONE, done.onSelect(), "select after completion");
	return true;
}
