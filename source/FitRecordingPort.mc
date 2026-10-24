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

	function initialize(name as String) {
		RecordingPort.initialize();
		activityName = name;
	}

	function open() as Void {
		Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
		Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE] as Array<Sensor.SensorType>);
		session = ActivityRecording.createSession({
			:name=>activityName,
			:sport=>ActivityRecording.SPORT_RUNNING,
			:subSport=>ActivityRecording.SUB_SPORT_GENERIC
		});
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
			(session as ActivityRecording.Session).stop();
		}
	}

	function addLap() as Void {
		if (session != null) {
			(session as ActivityRecording.Session).addLap();
		}
	}

	function save() as Void {
		if (session != null) {
			(session as ActivityRecording.Session).save();
		}
		release();
	}

	function discard() as Void {
		if (session != null) {
			(session as ActivityRecording.Session).discard();
		}
		release();
	}

	function release() as Void {
		session = null;
		Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
		Sensor.setEnabledSensors([] as Array<Sensor.SensorType>);
	}
}
