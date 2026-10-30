import Toybox.Lang;

// The screen tour (tour.jungle, source-tour/Tour.mc) replaces this with a
// version that swaps in sample history and opens each screen on a timer.
// The tour build excludes the :notour annotation; the normal build never
// compiles source-tour, so this empty function is all it has.
(:notour)
function startTour(app as ReturnToRunApp) as Void {
}
