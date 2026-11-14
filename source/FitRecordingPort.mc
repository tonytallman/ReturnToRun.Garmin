import Toybox.ActivityRecording;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Sensor;

// Records a running activity to a FIT file, which Garmin Connect picks up on
// the next sync. GPS feeds distance and the track; the heart-rate sensor feeds
// heart rate. Activity.SPORT_RUNNING needs API 3.2 and the fenix 5X is 3.1, so
// this uses the older ActivityRecording constants, which have the same values.
class FitRecordingPort extends RecordingPort {
	private var activityName as String;
	private var session as ActivityRecording.Session?;
	private var log as Breadcrumbs;
	private var sensorsOn as Boolean = false;

	function initialize(name as String, log as Breadcrumbs) {
		RecordingPort.initialize();
		activityName = name;
		self.log = log;
	}

	function open() as Void {
		Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
		Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE] as Array<Sensor.SensorType>);
		sensorsOn = true;
		try {
			session = ActivityRecording.createSession({
				:name=>activityName,
				:sport=>ActivityRecording.SPORT_RUNNING,
				:subSport=>ActivityRecording.SUB_SPORT_GENERIC
			});
		} catch (e) {
			log.note("recording open error " + e.getErrorMessage());
			throw e;
		}
		log.note("recording opened");
	}

	// The session reads GPS itself. Location events only need to be on.
	function onPosition(info as Position.Info) as Void {
	}

	function start() as Void {
		if (session != null) {
			(session as ActivityRecording.Session).start();
		}
	}

	function stop() as Void {
		if ((session != null) && (session as ActivityRecording.Session).isRecording()) {
			log.note("session stop");
			(session as ActivityRecording.Session).stop();
			log.note("session stopped");
		}
	}

	function addLap() as Void {
		if (session != null) {
			(session as ActivityRecording.Session).addLap();
		}
	}

	function save() as Void {
		if (session != null) {
			log.note("save started");
			var saved = false;
			try {
				saved = (session as ActivityRecording.Session).save();
			} catch (e) {
				log.note("save error " + e.getErrorMessage());
				throw e;
			}
			log.note(saved ? "save finished" : "save failed");
		}
		release();
	}

	function discard() as Void {
		if (session != null) {
			(session as ActivityRecording.Session).discard();
			log.note("recording discarded");
		}
		release();
	}

	// Drops the session. GPS and heart rate stay on until shutdown, so they are
	// not turned off in the same moment the watch writes the FIT file.
	function release() as Void {
		session = null;
	}

	function shutdown() as Void {
		if (!sensorsOn) {
			return;
		}
		sensorsOn = false;
		Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
		log.note("gps off");
		Sensor.setEnabledSensors([] as Array<Sensor.SensorType>);
		log.note("sensors off");
	}
}
