import Toybox.Lang;
import Toybox.Test;

(:test)
class FixedBreadcrumbClock extends BreadcrumbClock {
	function initialize() {
		BreadcrumbClock.initialize();
	}

	function stamp() as String {
		return "10-27 11:05:00";
	}
}

(:test)
module BreadcrumbTestSupport {
	function open(gateway as MemoryStorageGateway, cap as Number) as RingBreadcrumbs {
		return new RingBreadcrumbs(gateway, new FixedBreadcrumbClock(), null, cap);
	}
}

(:test)
function testBreadcrumbOrderAndStamp(logger as Test.Logger) as Boolean {
	logger.debug("entries are stamped and kept oldest first");
	var log = BreadcrumbTestSupport.open(new MemoryStorageGateway(), 5);
	TestSupport.expectEqual(0, log.entries().size(), "empty at first");
	log.note("start");
	log.note("list");
	var entries = log.entries();
	TestSupport.expectEqual(2, entries.size(), "two entries");
	TestSupport.expectEqual("10-27 11:05:00 start", entries[0], "first entry");
	TestSupport.expectEqual("10-27 11:05:00 list", entries[1], "second entry");
	return true;
}

(:test)
function testBreadcrumbCap(logger as Test.Logger) as Boolean {
	logger.debug("the oldest entries are dropped at the cap");
	var log = BreadcrumbTestSupport.open(new MemoryStorageGateway(), 3);
	for (var i = 1; i <= 7; i++) {
		log.note("e" + i);
	}
	var entries = log.entries();
	TestSupport.expectEqual(3, entries.size(), "capped at 3");
	TestSupport.expectEqual("10-27 11:05:00 e5", entries[0], "oldest kept");
	TestSupport.expectEqual("10-27 11:05:00 e7", entries[2], "newest last");
	return true;
}

(:test)
function testBreadcrumbPersistence(logger as Test.Logger) as Boolean {
	logger.debug("a new log on the same storage continues the old one");
	var gateway = new MemoryStorageGateway();
	BreadcrumbTestSupport.open(gateway, 3).note("first run");
	var reopened = BreadcrumbTestSupport.open(gateway, 3);
	reopened.note("second run");
	var entries = reopened.entries();
	TestSupport.expectEqual(2, entries.size(), "both runs kept");
	TestSupport.expectEqual("10-27 11:05:00 first run", entries[0], "earlier run first");
	return true;
}

(:test)
function testBreadcrumbBadStorage(logger as Test.Logger) as Boolean {
	logger.debug("unexpected stored data is replaced, not a crash");
	var gateway = new MemoryStorageGateway();
	gateway.set(RingBreadcrumbs.STORAGE_KEY, 5);
	var log = BreadcrumbTestSupport.open(gateway, 3);
	TestSupport.expectEqual(0, log.entries().size(), "a number reads as empty");
	gateway.set(RingBreadcrumbs.STORAGE_KEY, [1, 2] as Array<Number>);
	TestSupport.expectEqual(0, log.entries().size(), "numbers read as empty");
	log.note("ok");
	TestSupport.expectEqual(1, log.entries().size(), "logging starts over");
	return true;
}

(:test)
function testBreadcrumbClockFormat(logger as Test.Logger) as Boolean {
	logger.debug("the real clock gives MM-DD HH:MM:SS");
	var stamp = new BreadcrumbClock().stamp();
	TestSupport.expectEqual(14, stamp.length(), "length");
	TestSupport.expectEqual("-", stamp.substring(2, 3), "date separator");
	TestSupport.expectEqual(":", stamp.substring(8, 9), "time separator");
	return true;
}
