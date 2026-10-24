import Toybox.Lang;

// JSON resources and the object store may surface integers as Number, Long, Float, or Double.
function asNumber(value as Object?) as Number? {
	if (value instanceof Number) {
		return value as Number;
	}
	if (value instanceof Long) {
		return (value as Long).toNumber();
	}
	if (value instanceof Float) {
		return (value as Float).toNumber();
	}
	if (value instanceof Double) {
		return (value as Double).toNumber();
	}
	return null;
}
