import Toybox.Application;
import Toybox.Lang;

const FIRST_WORKOUT_ID = 1;

// The return-to-run catalog loaded from the bundled JSON resource.
// Workout ids are 1-based and match the array order.
class WorkoutProgram {
	var warmUpSeconds as Number;
	var coolDownSeconds as Number;
	private var workouts as Array<WorkoutDefinition>;

	function initialize(warmUpSeconds as Number, coolDownSeconds as Number, workouts as Array<WorkoutDefinition>) {
		self.warmUpSeconds = warmUpSeconds;
		self.coolDownSeconds = coolDownSeconds;
		self.workouts = workouts;
	}

	static function load() as WorkoutProgram {
		var resource = Application.loadResource(Rez.JsonData.WorkoutProgram);
		if (!(resource instanceof Dictionary)) {
			return new WorkoutProgram(0, 0, [] as Array<WorkoutDefinition>);
		}
		return WorkoutProgram.fromDictionary(resource as Dictionary);
	}

	static function fromDictionary(data as Dictionary) as WorkoutProgram {
		var warmUp = asNumber(data["warmUpSeconds"]);
		var coolDown = asNumber(data["coolDownSeconds"]);
		var warmUpSeconds = (warmUp == null) ? 0 : (warmUp as Number);
		var coolDownSeconds = (coolDown == null) ? 0 : (coolDown as Number);
		var definitions = [] as Array<WorkoutDefinition>;
		var rawWorkouts = data["workouts"];
		if (rawWorkouts instanceof Array) {
			var list = rawWorkouts as Array;
			for (var i = 0; i < list.size(); i++) {
				var item = list[i];
				if (item instanceof Dictionary) {
					var row = item as Dictionary;
					var definition = WorkoutProgram.definitionFromRow(row);
					if (definition != null) {
						definitions.add(definition as WorkoutDefinition);
					}
				}
			}
		}
		return new WorkoutProgram(warmUpSeconds, coolDownSeconds, definitions);
	}

	static function definitionFromRow(row as Dictionary) as WorkoutDefinition? {
		var id = asNumber(row["id"]);
		var runSeconds = asNumber(row["runSeconds"]);
		var walkSeconds = asNumber(row["walkSeconds"]);
		var repeatCount = asNumber(row["repeatCount"]);
		if ((id == null) || (runSeconds == null) || (walkSeconds == null) || (repeatCount == null)) {
			return null;
		}
		return new WorkoutDefinition(id as Number, runSeconds as Number, walkSeconds as Number, repeatCount as Number);
	}

	function maxId() as Number {
		return workouts.size();
	}

	function workoutById(id as Number) as WorkoutDefinition? {
		var index = id - 1;
		if ((index < 0) || (index >= workouts.size())) {
			return null;
		}
		var definition = workouts[index] as WorkoutDefinition;
		if (definition.id != id) {
			return null;
		}
		return definition;
	}
}
