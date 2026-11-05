import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// A short trail of what the app did, kept so a problem on the watch can be
// traced afterwards (for example, an app that closed on its own). Screens and
// the recorder only see Breadcrumbs; the base class records nothing, so tests
// and code without a log can pass it.
class Breadcrumbs {
	function initialize() {
	}

	function note(event as String) as Void {
	}
}

// Watch-clock time for each entry, as "MM-DD HH:MM:SS". Tests pass a fixed one.
class BreadcrumbClock {
	function initialize() {
	}

	function stamp() as String {
		var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		return Lang.format("$1$-$2$ $3$:$4$:$5$", [
			(info.month as Number).format("%02d"), info.day.format("%02d"),
			info.hour.format("%02d"), info.min.format("%02d"), info.sec.format("%02d")
		]);
	}
}

// Writes each line to the app's log file too. The watch keeps that file only
// if GARMIN/APPS/LOGS/<PRG name>.TXT already exists; see the README.
class BreadcrumbEcho {
	function initialize() {
	}

	function write(line as String) as Void {
		System.println(line);
	}
}

// Keeps the newest entries in storage, oldest first, and drops the oldest
// once there are cap of them. Each entry is "time event".
class RingBreadcrumbs extends Breadcrumbs {
	static const STORAGE_KEY = "log";
	static const CAP = 40;

	private var gateway as StorageGateway;
	private var clock as BreadcrumbClock;
	private var echo as BreadcrumbEcho?;
	private var cap as Number;

	function initialize(gateway as StorageGateway, clock as BreadcrumbClock, echo as BreadcrumbEcho?, cap as Number) {
		Breadcrumbs.initialize();
		self.gateway = gateway;
		self.clock = clock;
		self.echo = echo;
		self.cap = cap;
	}

	static function production() as RingBreadcrumbs {
		return new RingBreadcrumbs(new ApplicationStorageGateway(), new BreadcrumbClock(), new BreadcrumbEcho(), CAP);
	}

	function note(event as String) as Void {
		var line = clock.stamp() + " " + event;
		if (echo != null) {
			(echo as BreadcrumbEcho).write(line);
		}
		var kept = entries();
		var start = kept.size() + 1 - cap;
		if (start > 0) {
			kept = kept.slice(start, null);
		}
		kept.add(line);
		gateway.set(STORAGE_KEY, kept as Array<Storage.ValueType>);
	}

	// Oldest first. Anything stored that is not a list of strings reads as empty.
	function entries() as Array<String> {
		var stored = gateway.get(STORAGE_KEY);
		if (!(stored instanceof Array)) {
			return [] as Array<String>;
		}
		var list = stored as Array;
		for (var i = 0; i < list.size(); i++) {
			if (!(list[i] instanceof String)) {
				return [] as Array<String>;
			}
		}
		return list as Array<String>;
	}
}
