import Toybox.Application.Storage;
import Toybox.Lang;

// Persistence port so history rules can be tested without Application.Storage.
class StorageGateway {
	function initialize() {
	}

	function get(key as String) as Storage.ValueType {
		return null;
	}

	function set(key as String, value as Storage.ValueType) as Void {
	}

	function remove(key as String) as Void {
	}
}

class ApplicationStorageGateway extends StorageGateway {
	function initialize() {
		StorageGateway.initialize();
	}

	function get(key as String) as Storage.ValueType {
		return Storage.getValue(key);
	}

	function set(key as String, value as Storage.ValueType) as Void {
		Storage.setValue(key, value);
	}

	function remove(key as String) as Void {
		Storage.deleteValue(key);
	}
}

class MemoryStorageGateway extends StorageGateway {
	private var values as Dictionary<String, Storage.ValueType>;

	function initialize() {
		StorageGateway.initialize();
		values = {} as Dictionary<String, Storage.ValueType>;
	}

	function get(key as String) as Storage.ValueType {
		if (!values.hasKey(key)) {
			return null;
		}
		return values[key] as Storage.ValueType;
	}

	function set(key as String, value as Storage.ValueType) as Void {
		values.put(key, value);
	}

	function remove(key as String) as Void {
		if (values.hasKey(key)) {
			values.remove(key);
		}
	}
}
