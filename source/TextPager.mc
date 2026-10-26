import Toybox.Lang;

// Which lines of a long text are on screen. Up and Down move a whole page.
// Pages are given by the first line of each page (see TextPages.pageStarts),
// so a page can end early to keep a sentence whole.
// UI-free so the paging is unit tested.
class TextPager {
	var lineCount as Number;
	var starts as Array<Number>;
	var page as Number;

	function initialize(lineCount as Number, starts as Array<Number>) {
		self.lineCount = (lineCount < 0) ? 0 : lineCount;
		self.starts = (starts.size() == 0) ? [0] as Array<Number> : starts;
		page = 0;
	}

	function pageCount() as Number {
		return starts.size();
	}

	// The first line on the current page, and one past its last.
	function firstLine() as Number {
		return starts[page];
	}

	function endLine() as Number {
		var end = (page + 1 < starts.size()) ? starts[page + 1] : lineCount;
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
