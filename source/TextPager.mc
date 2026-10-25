import Toybox.Lang;

// Which lines of a long text are on screen. Up and Down move a whole page.
// UI-free so the paging is unit tested.
class TextPager {
	var lineCount as Number;
	var linesPerPage as Number;
	var page as Number;

	function initialize(lineCount as Number, linesPerPage as Number) {
		self.lineCount = (lineCount < 0) ? 0 : lineCount;
		self.linesPerPage = (linesPerPage < 1) ? 1 : linesPerPage;
		page = 0;
	}

	function pageCount() as Number {
		if (lineCount == 0) {
			return 1;
		}
		return (lineCount + linesPerPage - 1) / linesPerPage;
	}

	// The first line on the current page, and one past its last.
	function firstLine() as Number {
		return page * linesPerPage;
	}

	function endLine() as Number {
		var end = firstLine() + linesPerPage;
		return (end > lineCount) ? lineCount : end;
	}

	function hasPrevious() as Boolean {
		return page > 0;
	}

	function hasNext() as Boolean {
		return page < pageCount() - 1;
	}

	function next() as Boolean {
		if (!hasNext()) {
			return false;
		}
		page++;
		return true;
	}

	function previous() as Boolean {
		if (!hasPrevious()) {
			return false;
		}
		page--;
		return true;
	}
}
