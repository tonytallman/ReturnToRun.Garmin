import Toybox.Lang;

class WorkoutDefinition {
	var id as Number;
	var runSeconds as Number;
	var walkSeconds as Number;
	var repeatCount as Number;

	function initialize(id as Number, runSeconds as Number, walkSeconds as Number, repeatCount as Number) {
		self.id = id;
		self.runSeconds = runSeconds;
		self.walkSeconds = walkSeconds;
		self.repeatCount = repeatCount;
	}
}
