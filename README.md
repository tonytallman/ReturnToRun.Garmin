# Return to Run

A Garmin Connect IQ watch app for a return-to-run program after injury. The first screen is Run, then the workout list, pre-run warnings, the in-progress workout, and the post-run rating, plus a History screen to review, edit, add, and delete entries, Help, and About. Each workout is recorded as a running activity and saved to Garmin Connect.

## Architecture

Workout definitions live in `resources-program/data/program.json` and load through `WorkoutProgram`. Ids are 1 through 40 and match the old hard-coded table: run 60 s / walk 60 s x3 up to a single 1800 s run. Workouts 38 to 40 (20, 25, and 30 minute continuous runs) have `walkSeconds` 0; every other workout walks 60 s. Every workout has a 300 s warm-up and a 300 s cool-down. `Workout` builds the activity sequence from a definition: warm-up, then each run followed by its walk, then cool-down. The last run is followed by its walk too, so every workout with walks has a one-minute walk before cool-down. A workout with no walk goes from its run straight to cool-down. Nothing in the new model assumes a screen size. A simulator build can swap in `resources-quick` (15 s warm-up and cool-down, 10 s run and walk, same ids and repeat counts, and no walk in workouts 38 to 40); see Build and test. The normal build does not include that folder.

`HistoryStore` is the only record of progress. An entry is a local calendar day, a workout id, and a rating (`Bad`, `OK`, `Good`, `Great`). Entries stay newest first. Several entries on the same day are allowed, and a newly added one sorts ahead of the entries already stored for that day. The store is one flat array of `[yyyymmdd, workoutId, rating]` triples under the storage key `history`, plus a boolean `programCompleteShown`. In memory, the store keeps that same flat array rather than an object per entry, and builds an entry only when one is read; with 100 entries, this uses about 24 KB less memory than one object per entry did. The stored format has not changed, so history saved by earlier versions loads as it is, and values the object store returns as Long, Float, or Double load as whole numbers. The cap is `HISTORY_ENTRY_CAP` (100). A newer entry past the cap drops the oldest; an entry that would itself fall at or past the cap is rejected and the store is unchanged. 100 triples is a few hundred integers, under the 32 KB per-value limit in `Application.Storage`, and it covers the 40-workout program more than twice including back-offs and manual edits.

`Progress` is the API the screens call:

- add an entry on any date, change a rating, delete one entry, delete an entry and every entry older than it, or clear every entry
- `recommend(today)` and `warning(today)`, both pure functions of history plus the date the caller passes in
- `logWorkout(date, id, rating)`, which adds the entry and returns whether the program-complete screen should show now
- `shouldShowProgramComplete(today)` and `markProgramCompleteShown()`
- `changeRating(index, rating, today)` and `addWorkout(date, id, rating, today)` for History; each returns whether the program-complete screen should show now (see below). `lastAddedIndex()` is where the last add landed, or -1 if the cap rejected it
- `isTooOldToAdd(date)`, true when the history is full and an entry on that date would be older than every entry, so the cap would reject it (`HistoryStore.isTooOldToAdd`, the same rule `add` uses)

The recommended workout is never stored. It is derived from the newest entry.

### Recommendation

Ratings move the last workout by -1, 0, +1, or +2 (`Bad`, `OK`, `Good`, `Great`). Days off are the full calendar days strictly between the newest entry and today, so a Monday run and a Thursday today are 2 days off. The same day or the next day is 0. The penalty is 0 for 0–2 days, then 1, 2, and 3 for 3, 4, and 5 days. Six or more days restarts at workout 1 and does not mark the program complete, whatever the last rating was.

Otherwise the recommendation is `last workout + rating step - penalty`, clamped to 1..40. `Bad` on workout 1 stays on 1. `Good` or `Great` past 40 stays on 40. Empty history recommends workout 1.

Program completion is that same result before clamping. If it would be 41 or higher, `Recommendation.programComplete` is true. That is true for a workout just logged and for a rating change on the newest entry. The UI asks `shouldShowProgramComplete` and, after showing the screen, calls `markProgramCompleteShown`. The flag is not set merely because completion was detected, and `clear()` does not reset it. Logging workout 1 does reset it, including a backdated workout 1 that is not the newest entry, so a later completion can show the screen again. An add that the cap rejects does not reset it. The signal is derived from the newest entry and today, so enough days off can clear it again. `logWorkout` returns `shouldShowProgramComplete` after a successful add, so the rating screen and History use the same rule: `changeRating` returns it only when the changed entry is the newest (index 0), and `addWorkout` only when the added entry became the newest. Changing a rating can also take completion away (for example Good to OK on 40); the flag is unchanged either way. With a full history, logging today's run drops the oldest entry as usual and can still show the screen. An entry the cap rejects (only possible when future-dated entries fill the store) logs nothing and shows nothing, although the FIT activity is already saved.

### Pre-run warnings

`PreRunWarnings.evaluate` returns every warning that applies, in this priority order:

1. `ALREADY_LOGGED_TODAY` — any entry dated today. Message: "Running more than once a day is not recommended."
2. `SEVEN_CONSECUTIVE_DAYS` — each of the previous 6 calendar days has at least one entry, so a run today would be the 7th day in a row. Message: "Running more than six days a week is not recommended."

There is no check for too few recent runs.

### Screens

There is no migration from the old `WorkoutIndex` storage key; no installed copies need it.

The first screen is a Menu2 titled with the app name. Its items are Run, History, Help, and About. Back from that menu exits.

Run opens a Menu2 with one item per workout. The label is `#1  R1 W1 ×3`: the id, run, walk, and repeat count. A whole number of minutes is `R1` or `R30`; anything else is `m:ss`, such as `R1:30`. A workout with no walk omits `W` and a single repeat omits the count, so workout 33 is `#33  R9 W1` and workout 40 is `#40  R30`. The subtitle is the total of that activity sequence, rounded to the nearest minute (30 seconds and above rounds up). Workout 1 is `16 min with walks`: warm-up, three runs, three walks (the last one before cool-down), and cool-down. A workout with no walk interval omits `with walks`. The recommended workout is focused, and its subtitle is prefixed with a star.

Choosing a workout runs `PreRunWarnings`. No warning starts the workout. Otherwise the warnings are shown one at a time, highest priority first, each with Continue and Cancel. Continue moves to the next warning, and after the last one it starts the workout. Cancel or Back on any warning returns to the list. Up and Down move between the two actions. On a touch screen, a tap on Continue or Cancel chooses it, and a tap on the message does nothing; `WarningLayout` holds where the two actions are drawn and which one a tap hits, and is unit tested. The message is wrapped to fit the middle of the round face, with no title. `TextWrap` does the greedy word wrap through a `TextMeasure` port, so it is unit tested with a fake measure; it avoids `Graphics.fitTextToArea`. The view draws text directly so the blue focus bar is centered on the focused action. The workout list marks the recommended workout with "*", because the fēnix 5X fonts have no ★ glyph.

The in-progress screen shows the step (Warm up, Run, Walk, or Cool down) above a large centered countdown, the time left in the run/walk main set, and the repeat such as `1/8`. The step is at `10%`, the countdown is centered, the time left is at `73%`, and the repeat stays centered at the bottom (`85%`). The time left counts the rest of the current run or walk and every run and walk after it, so it starts at the main-set total on the first run and reaches zero when cool-down starts. During warm-up and cool-down the screen shows only the step and the countdown, with no time left and no repeat (`WorkoutDuration.remainingInMainSet` and `showsRemaining`). Start/Stop pauses and resumes. On a touch screen, taps are ignored during a workout, so a stray touch never pauses it: a tap also arrives as the Select behavior, so there the Start key (`KEY_ENTER`) runs the action instead. The Venu, Venu D, Venu Sq, Venu Sq 2, D2 Air, and D2 Air X10 are the exception: their Start button never reaches Select, so a tap pauses and resumes there (`resources-tap-pause` sets `StartButton`). `TouchPolicy` makes that choice and is unit tested, and `StartActionDelegate` applies it to the workout and warning screens. While paused, the countdown turns yellow and a Paused label is shown. The timer and the five-second tones stop while paused. Back while running pauses, so Back alone never quits. Back while paused opens "End workout?", a Menu2 with Resume (focused, so a stray press keeps the run), Save, and Discard. Back on that menu stays paused. Discard throws the recording away and returns to the main menu with no history entry. Save saves the recording and goes to the rating. When the last segment reaches zero, the recording stops and the rating replaces the workout. The Buttons help notes that Up and Down change the rating, Start picks it, and Back stays on the rating screen until you pick one.

The rating is the built-in `WatchUi.Picker` (`RatingPicker`) titled "How did it feel?", which fits on one line and is always shown. It starts on Good. Up moves toward Great and Down toward Bad, wrapping around, and Start picks the rating. The choices, their order, the starting one, and the mapping from a picked value back to a rating live in `RatingChoices`, which is UI-free and unit tested; the picker only draws them. Back does nothing (`onCancel` returns true without popping, and the Picker stays up); a finished run must be rated. The words and title paint their own black boxes because the simulator (SDK 8.3 and later) paints every Picker white, while the watch keeps the black background set in `onUpdate`. Choosing a rating saves the recording if it is not saved yet, logs today, the workout id, and the rating, and returns to the main menu. If that rating takes the recommendation past workout 40 and the program-complete screen has not been shown for this program, "Program complete" is shown instead, once, with a message to keep running #40 or pick #1 to start over; Select or Back on it returns to the main menu. The recommendation stays at 40.

### History

History is a Menu2 titled History with one item per entry, newest first, such as `Oct 24  #5  Good`: the localized short month and day (no year), the workout id, and the rating. Clear history is the second-to-last item and Add workout is the last; both are always there, even when history is empty. Positions and the focus after an edit come from `HistoryFormat`, which is UI-free.

Building the list does no date math per entry. `HistoryWords` loads the four rating words once and caches the 12 month abbreviations, each formatted once from `Gregorian` on first use. With 100 entries, opening the list, opening an entry, deleting, adding, and rebuilding all ran in the simulator with the watchdog budget lowered to half of the default.

Selecting an entry opens its details, a Menu2 titled `Oct 24  #5` with Rating (the current rating as the subtitle), Delete, and "Delete this & older". Rating opens the same rating picker, starting on the current rating; Start saves it and returns to the History list, and Back returns to the details without a change. Delete asks "Delete workout?", Delete this & older asks "Delete this & older?", and Clear history asks "Clear all history?". Each uses the standard Confirmation, so the prompts are kept short enough not to be cut off. Yes makes the change and returns to the list; No or Back changes nothing.

Add workout asks for the date, then the workout, then the rating. The date screen shows the short date large, with Today, Yesterday, or the weekday under it. It starts at today; Down goes back a day, Up goes forward a day but never past today, and there is no lower limit. `DateStepper` holds that logic and is UI-free. The workout step reuses the workout list (titled Workout, with today's recommendation starred and focused), and the rating step uses the rating picker starting on Good, where Back returns to the workout step. The new entry is added at its date and the list focuses it. An add that the cap would reject (the history is full and the date is older than all 100 entries) adds nothing. The rating picker is replaced by a `NoticeView` that says "This workout is older than all 100 saved workouts, so it wasn't added. History keeps only the 100 most recent." (`AddTooOldMessage`); Start or Back returns to the History list. The decision is `Progress.isTooOldToAdd`, which is UI-free and unit tested.

A rating change on the newest entry, or an added entry that becomes the newest, uses the same program-complete rule as a logged run: if it applies and the screen has not been shown for this program, "Program complete" is shown once, and closing it returns to the History list. The recommendation and the pre-run warnings are derived from history, so they follow every edit, delete, and add with no extra bookkeeping.

The History list is rebuilt in place (items deleted and re-added) when it is shown again after `AppServices.historyVersion` changed, instead of replacing the view. Screens above it get back to it through `ScreenStack`: an edit asks for a return to History, each screen above the list pops itself when shown (`LeaveTimer`), and the list stops the unwinding. A return to the main menu, as after a run, takes priority and passes through History.

While a screen opened from the list is showing (an entry's details and its rating picker, the Clear history confirmation, or Add workout's steps), the list deletes its items to free memory and rebuilds them when it is shown again. Menu2 cannot report which item is focused, so the list keeps the position of the item that was selected (`AppServices.historyFocus`) and focuses it again on return, or the item `HistoryFormat` picks after an edit. With 100 entries on the Forerunner 245, this brings the peak with the rating picker open over the details from about 88 KB to about 70 KB, so the History list itself (about 86 KB) is now the largest use.

On the 96 KB watches (Instinct 2, 2S, 2X, Instinct Crossover, and Descent G1), each Menu2 item costs about 195 bytes, and a list of all 100 entries ran out of memory in the simulator. There the list shows 30 entries at a time: "Newer workouts" (first, from the second page on) and "Older workouts" (after the entries, when there are more) turn the page, and Clear history and Add workout stay at the end. Turning to an older page focuses its first entry and turning to a newer one focuses its last. `resources-low-memory` sets the page size (`HistoryPageSize`, 0 for no paging elsewhere), `AppServices.historyFocus` stays a position in the whole history, and `HistoryFormat` maps it to a page and back (UI-free and unit tested). With 100 entries on the Instinct 2, the tour's peak is about 88 KB of its 94 KB (Add workout's workout step).

The Workout title on the reused workout list is hidden on this watch while the focused item is in the middle, a known Menu2 issue. The rating picker's title is always shown.

On the Venu Sq 2 and Sq 2 Music, the simulator draws the rating picker's OK over the rating word; the picker is left as it is until this is confirmed on a real watch.

On the fēnix 7S and 7S Pro, the system Menu2 lets longer item labels run slightly past the round edge of the screen; this is accepted, with no padding workaround. On the vívoactive 3, "Delete this & older" in an entry's details is cut off a little at the edge; that wording is kept on purpose. On watches with the newer menu style (Forerunner 255 and 955, fēnix 7 and 7X, Enduro 3, fēnix 8 51 mm and similar), the system Menu2 cuts off the left edge of the items that are not focused; this is how the system menu looks there and is accepted, with no workaround (Menu2 has no padding option, and drawing our own items would lose the system look). On watches with the white menu style (Venu, Venu 2/2S/3, D2 Air, vívoactive 5 and similar), the system Menu2 cuts off the edges of the top row, for example the recommended workout, which the Workout list still jumps to; this is accepted. On watches with the Approach menu style (Approach S50 and S70), the system Menu2 left-aligns items close to the round edge, so the first letters of lower rows (and, on the S50, the top row) are cut off; this is accepted too.

On the vívoactive 3 family, the Forerunner 55, and the 1.3-inch Star Wars Legacy watches (Darth Vader and First Avenger), the system Menu2 wraps a title such as "Return to Run" onto a second line and cuts it off. On those watches every menu title (main menu, History, an entry's details, Help, Workout, and the End workout? menu) is drawn by the app instead, on one line. `monkey.jungle` adds `resources-menu-title` to their resource path, which turns on the `DrawnMenuTitles` resource, and `MenuTitle.of` then returns a `FittedMenuTitle` drawable instead of the text. It is centered in the title area the menu gives it, in the largest font that fits that area's width (`TitleFit.fontWithin`); the area is narrower than the screen (114 of 208 pixels on the Forerunner 55). All other watches keep the system's titles. To add a watch, add its `resourcePath` line in `monkey.jungle`.

### Help and About

Help is a Menu2 of topics: Program, Workout list, Ratings, Days off, Warnings, and Buttons. On the two-button touch watches the last topic is Controls, which describes Start, taps, and swipes (`resources-touch-help`); on the Venu, Venu D, Venu Sq, Venu Sq 2, D2 Air, and D2 Air X10 it says that a tap pauses (`resources-tap-pause`). Each topic opens a `TextPageView`: a green title and the body in `FONT_XTINY`, a page at a time. Down shows the next page and Up the previous one; small arrows show when there is more above or below, and Back returns to the topic list. All of the text is in `resources/strings/strings.xml` (`Help*` strings). The Program topic ends with "Check with your doctor before starting a running program." In those strings `|` starts a new line and `||` leaves a blank line, because `\n` is not reliably escaped in Connect IQ string resources.

The view wraps and pages the body once in `onLayout` with `TextWrap` and keeps the lines, so `onUpdate` only draws. Lines are 72% of the screen wide and the body runs from 27% to 85% of the height, which keeps every line inside the round face of the fēnix 5X; the lines per page come from the font height. Each sentence starts a new line (a `|` piece is split into sentences at `. `). Pages break between sentences: a page takes as many whole sentences as fit, so a sentence is never split across pages, and a blank line that does not fit stays at the end of its page so no page starts blank. Only a sentence taller than a whole page is split at line boundaries. `TextPages` (splitting on `|` and into sentences, wrapping each sentence, choosing the first line of each page, and breaking a link after each `/` since it has no spaces) and `TextPager` (page count, first and end line, next and previous) are UI-free and unit tested. A test also checks that no word in the help text is longer than 16 characters, since `TextWrap` never splits a word.

About uses the same view. It shows the app name, `Version 1.0.0`, and the repository link `github.com/tonytallman/ReturnToRun.Garmin` as text. Where `Communications.openWebPage` exists (API 1.3, so on the fēnix 5X), it adds "Press Start to open the link on your phone." and Start sends the link to the phone through Garmin Connect Mobile, which needs the phone connected. On the Venu, Venu D, Venu Sq, Venu Sq 2, D2 Air, and D2 Air X10 the hint says to tap the screen instead. That is why the manifest asks for the Communications permission.

The version shown comes from one place, the `AppVersion` string resource, because Connect IQ 3.1 cannot read the manifest version at run time. `tools/check-version.sh` fails if it differs from the `version` attribute of `iq:application` in `manifest.xml`; run it whenever either changes. A unit test checks that the resource is `major.minor.patch` (`AppVersion.isWellFormed`).

### Recording

`WorkoutRecording.Recorder` owns the recording lifecycle and talks to a `RecordingPort`. `FitRecordingPort` is the real port: it turns on continuous GPS and the heart-rate sensor and creates an `ActivityRecording` session (sport running, sub-sport generic, named `Return to Run #<workout id>`). The workout starts recording when it opens, stops the session timer on pause, starts it again on resume, and adds a lap at every segment change after the warm-up. Save and discard turn GPS and the sensor back off. Save is idempotent, so the end prompt and the rating can both call it. If the app is stopped with a recording still open, `ReturnToRunApp.onStop` saves it. The FIT file reaches Garmin Connect on the watch's next sync. `Activity.SPORT_RUNNING` needs API 3.2 and the fēnix 5X is 3.1.6, so the code uses the deprecated `ActivityRecording.SPORT_RUNNING` and `SUB_SPORT_GENERIC`, which have the same values; the compiler warns about them. The manifest asks for the Fit, Positioning, and Sensor permissions, plus Communications for the About link.

Every segment, including warm-up and cool-down, starts with one vibration: duty cycle 100 for 1000 ms. Connect IQ has no built-in vibration preset, so that single pulse is the segment cue. Workout complete is three 500 ms pulses at the same duty cycle, separated by 250 ms gaps. Each of the last five seconds of a segment (5, 4, 3, 2, 1) plays one short tone when the device has `Attention.playTone` and `System.getDeviceSettings().tonesOn` is true. Those beeps do not vibrate, and they do not play while paused. The next segment's vibration follows the last beep. Which seconds beep, which repeat a segment index is, which alert a segment gets, the list text, the duration totals, the warning message, text wrapping, the workout session transitions (pause, end prompt, save, discard, rating), and the recording lifecycle are UI-free (`CountdownTones`, `IntervalCount`, `SegmentAlerts`, `WorkoutListFormat`, `WorkoutDuration`, `WarningMessages`, `TextWrap`, `WorkoutSession`, `WorkoutRecording`). They do not import the UI, and the recorder is tested with a fake port.

### Breadcrumb log

To help diagnose problems on the watch, such as the app closing on its own, the app keeps a short log of what it did. Screens and the recorder see only `Breadcrumbs`, whose `note` records nothing; `RingBreadcrumbs` is the real one, and tests use it with a memory store and a fixed clock. Each entry is the watch-clock time and a short event, such as `10-27 11:05:12 workout 2 started`. The app logs:

- start (with the app version) and stop, including whether a run was still open and was saved;
- the workout list, each pre-run warning shown (once per day, six per week), and a cancelled warning;
- the workout starting, the recording opening, the workout screen first showing, pause, resume, the end prompt, Save or Discard on it, the workout completing, and the rating;
- save started, save finished or failed, a discarded recording, and any error while opening or saving the recording.

Segment changes are not logged. The newest 40 entries are kept in `Application.Storage` under the key `log` (about 1.5 KB), and the oldest entry is dropped when a new one is added after that.

Every entry is also printed with `System.println`. On a sideloaded app, the watch writes those lines to a file only if the file already exists. To turn this on, connect the watch over USB and create an empty file in `GARMIN/APPS/LOGS` named after the PRG, in capital letters with a `.TXT` extension: for `ReturnToRun.prg`, that is `GARMIN/APPS/LOGS/RETURNTORUN.TXT`. After the next run, copy the file off the watch. The log can't be viewed on the watch.

### Instinct watches

The Instinct 2, 2S, 2X, Instinct Crossover, Instinct 3 Solar 45 mm, Instinct E 40 and 45 mm, and Descent G1 have black-and-white screens. `resources-mono` turns on the `Monochrome` resource, and `Palette` then draws every title, the paused countdown, the dimmed text, and the warning's highlight bar in white (with the focused action in black on it) instead of green, yellow, gray, or blue, which would come out black (invisible) or white there. The Instinct 3 AMOLED and Instinct Crossover AMOLED are color screens and keep the colors.

Most Instinct watches have a small round subscreen in the top-right corner. `Subscreen` keeps text out of it (6 pixels clear, for the frame drawn around it): a title on its rows is centered in the room to its left, in a smaller font or split in two if needed (`TitleFit.draw`); a help page starts below it; and a message (a warning, the too-old notice, Program complete) is wrapped line by line to the room each line has, left of the subscreen on its rows and inside the cut-off top corner and the round bottom (`Subscreen.drawMessage`), with the warning's actions moved down below it. During a workout the step and the Paused label move left of the subscreen, and the subscreen shows the time of day (12- or 24-hour, as set on the watch). Elsewhere nothing is drawn there. Where `WatchUi.getSubscreen` is missing or returns null (as on the Instinct 3 AMOLED in the simulator), nothing changes.

The Instinct watches have no touch screen, so they use the default `TouchPolicy` (Select is the Start button) and the Buttons help.

Day differences use a civil calendar, not 86400-second chunks, so a daylight-saving change does not add or remove a day off.

## Build and test

Connect IQ SDK 9.3.0, device `fenix5x` only. The manifest minimum API level is 3.1.0: Menu2 needs 3.0, `Application.loadResource` for JSON needs 3.1, and the fenix 5X in this SDK reports Connect IQ 3.1.6. Do not pass `-l 0`; type checking stays at the compiler default.

Install the fēnix 5X device files with the SDK Manager (a Garmin login is required), then:

```sh
export PATH="$HOME/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.3.0-2026-10-20-95888f262/bin:$PATH"

openssl genrsa -out /tmp/returntorun-dev.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in /tmp/returntorun-dev.pem -out /tmp/returntorun-dev.der -nocrypt

monkeyc -d fenix5x -f monkey.jungle -o bin/ReturnToRun.prg -y /tmp/returntorun-dev.der -w
monkeyc -d fenix5x -f monkey.jungle -o bin/ReturnToRun-test.prg -y /tmp/returntorun-dev.der --unit-test -w

# Shorter segments for a simulator pass: 15 s warm-up and cool-down, 10 s run and walk.
# quick.jungle replaces the resource path, so the real program is not in this build.
# Do not use it for unit tests; those assert the real 300 s warm-up and cool-down.
monkeyc -d fenix5x -f "monkey.jungle;quick.jungle" -o bin/ReturnToRun-quick.prg -y /tmp/returntorun-dev.der -w

# The simulator must already be running and have the fenix5x device files.
connectiq
monkeydo bin/ReturnToRun-test.prg fenix5x -t
monkeydo bin/ReturnToRun-quick.prg fenix5x
```

`monkey.jungle` sets `base.resourcePath` to `resources;resources-program`. `quick.jungle` sets it to `resources;resources-quick` and is only passed for the quick build, so the two `WorkoutProgram` resources are never compiled together. Repeat counts and ids in the quick file match the real catalog (40 workouts). VS Code's Run Quick launch configuration passes the same jungle list and still asks for the target device.

### Screen tour

The tour build opens every screen in turn on a timer, so a device can be checked in the simulator without pressing anything. `tour.jungle` adds `source-tour` and excludes the `:notour` stub in `source/TourHook.mc`; the normal build never compiles `source-tour`. The tour keeps 100 sample history entries in memory (one a day ending today, so the history is full and both pre-run warnings apply) and never touches `Application.Storage`. It shows the main menu, the workout list, both warnings, warm-up, run, run paused, walk, cool-down, the rating picker, the History list, its next page of older entries (the same list where it is not paged), and an entry's details, Add workout's date and workout steps, the too-old notice, Program complete, the Help menu, every page of every help topic, and every page of About. After each screen has drawn it prints `TOUR <nn> <name> used=<bytes> total=<bytes>`, then `TOUR END`.

```sh
tools/device-tour.py fenix5x fr245      # builds, runs, and captures each device in turn
tools/device-tour.py vivoactive3 --out /tmp/shots --full
```

The script needs python3-xlib and Pillow and an X display. It starts the simulator if it is not running, builds `bin/tour-<device>.prg` with `monkey.jungle;tour.jungle` (key from `--key`, `$CIQ_DEVELOPER_KEY`, or `~/Garmin/keys/developer_key.der`), runs it with `monkeydo`, and on each marker grabs the simulator window. Screens are cropped to the watch display and saved as `<out>/<device>/<nn>-<name>.png` (default `bin/tour`), with `tour.log` (the app output, including memory at each screen) and `contact.png` (every screen on one sheet); `--full` keeps the whole window instead. The window is read through X, so it does not need to be in front, and nothing is typed into it. Before it starts, the script copies the simulator's app storage (`/tmp/com.garmin.connectiq/GARMIN/APPS`), its `Settings` folder, and `~/.Garmin/ConnectIQ/simulator.ini` aside, and puts them back when it finishes or fails.

The memory figures in `tour.log` include the tour code itself (a few KB), so they are a little above the normal build's.

### Launcher icon

The launcher icon is `resources/drawables/launcher_icon.png`, 40 x 40 px (the fēnix 5X `launcherIcon` size). Its source is `resources/drawables/launcher_icon.svg`, an original running figure in palette greens (00FF00 near limbs, 00AA00 far limbs) on a transparent background. After editing the SVG, render the PNG again:

```sh
sudo apt install librsvg2-bin   # rsvg-convert; the script also needs Pillow
tools/render-icon.py            # resources/drawables/launcher_icon.svg -> launcher_icon.png
```

The script renders at 8x, scales down to 40 x 40, makes pixels under 50% coverage transparent, and snaps every other pixel to the device's 64-colour palette (each channel 00, 55, AA, or FF), so the PNG matches what the watch draws.

Most supported watches use the 40 x 40 icon. The vívoactive 3 family (vivoactive3, vivoactive3m, vivoactive3mlte) uses 40 x 33, so `resources-icon-40x33/drawables/launcher_icon.png` holds the same drawing centred on a 40 x 33 canvas, and `monkey.jungle` adds that folder to those devices' resource paths. Render it again too after editing the SVG:

```sh
tools/render-icon.py resources/drawables/launcher_icon.svg resources-icon-40x33/drawables/launcher_icon.png 40x33
```

Smaller round watches use smaller square icons in the same way: `resources-icon-35x35` (fr55, Legacy Hero First Avenger, Legacy Saga Darth Vader, vívoactive 4) and `resources-icon-30x30` (Legacy Hero Captain Marvel, Legacy Saga Rey, vívoactive 4S):

```sh
tools/render-icon.py resources/drawables/launcher_icon.svg resources-icon-35x35/drawables/launcher_icon.png 35
tools/render-icon.py resources/drawables/launcher_icon.svg resources-icon-30x30/drawables/launcher_icon.png 30
```

The round AMOLED watches (Venu, Forerunner 165/265/570/965/970, fēnix 8/9 and epix, MARQ, D2, Descent, Approach S50/S70/S72, vívoactive 5/6) use larger square icons: `resources-icon-54x54`, `-56x56`, `-60x60`, `-61x61`, `-65x65` and `-70x70`. `monkey.jungle` lists which device uses which folder. Render them all again after editing the SVG:

```sh
for n in 54 56 60 61 65 70; do tools/render-icon.py resources/drawables/launcher_icon.svg resources-icon-${n}x${n}/drawables/launcher_icon.png $n; done
```

The rectangular Venu Sq and Venu Sq Music use `resources-icon-36x36`, and the Venu X1 uses `resources-icon-65x65`; the Venu Sq 2 uses the default 40 x 40:

```sh
tools/render-icon.py resources/drawables/launcher_icon.svg resources-icon-36x36/drawables/launcher_icon.png 36
```

The black-and-white Instinct watches use `resources/drawables/launcher_icon_mono.svg`, the same runner in white over a black outline, rendered with `mono` so every pixel is black or white (no gray to dither): `resources-icon-mono-62x62` (Instinct 2 and 2X, Instinct 3 Solar 45 mm, Instinct E 45 mm, Descent G1), `-54x54` (Instinct 2S), `-52x52` (Instinct E 40 mm), and `-26x26` (Instinct Crossover). The Instinct 3 AMOLED watches use the color `resources-icon-60x60`, and the Instinct Crossover AMOLED uses `resources-icon-38x38`:

```sh
for n in 26 52 54 62; do tools/render-icon.py resources/drawables/launcher_icon_mono.svg resources-icon-mono-${n}x${n}/drawables/launcher_icon.png $n mono; done
tools/render-icon.py resources/drawables/launcher_icon.svg resources-icon-38x38/drawables/launcher_icon.png 38
```

When adding a device, check its `launcherIcon` size in `~/.Garmin/ConnectIQ/Devices/<device>/compiler.json`. If it is not 40 x 40, add a `resources-icon-<W>x<H>` folder the same way; otherwise the compiler warns and scales the 40 x 40 icon.

Check the version before a release:

```sh
tools/check-version.sh
```

`monkeydo` can take a test name after `-t` to run one test. Tests live in `source/tests` and use `(:test)` functions, so a normal build leaves them out. Do not commit the developer key or anything under `bin/`.
