# Return to Run

A Garmin Connect IQ watch app for a return-to-run program after injury. The first screen is Run, then the workout list, pre-run warnings, the in-progress workout, and the post-run rating. Each workout is recorded as a running activity and saved to Garmin Connect. History, Instructions, and About come later.

## Architecture

Workout definitions live in `resources-program/data/program.json` and load through `WorkoutProgram`. Ids are 1 through 40 and match the old hard-coded table: run 60 s / walk 60 s x3 up to a single 1800 s run. Workouts 38 to 40 (20, 25, and 30 minute continuous runs) have `walkSeconds` 0; every other workout walks 60 s. Every workout has a 300 s warm-up and a 300 s cool-down. `Workout` builds the activity sequence from a definition: warm-up, then each run followed by its walk, then cool-down. The last run is followed by its walk too, so every workout with walks has a one-minute walk before cool-down. A workout with no walk goes from its run straight to cool-down. Nothing in the new model assumes a screen size. A simulator build can swap in `resources-quick` (15 s warm-up and cool-down, 10 s run and walk, same ids and repeat counts, and no walk in workouts 38 to 40); see Build and test. The normal build does not include that folder.

`HistoryStore` is the only record of progress. An entry is a local calendar day, a workout id, and a rating (`Bad`, `OK`, `Good`, `Great`). Entries stay newest first. Several entries on the same day are allowed, and a newly added one sorts ahead of the entries already stored for that day. The store is one flat array of `[yyyymmdd, workoutId, rating]` triples under the storage key `history`, plus a boolean `programCompleteShown`. The cap is `HISTORY_ENTRY_CAP` (100). A newer entry past the cap drops the oldest; an entry that would itself fall at or past the cap is rejected and the store is unchanged. 100 triples is a few hundred integers, under the 32 KB per-value limit in `Application.Storage`, and it covers the 40-workout program more than twice including back-offs and manual edits.

`Progress` is the API the screens call:

- add an entry on any date, change a rating, delete one entry, delete an entry and every entry older than it, or clear every entry
- `recommend(today)` and `warning(today)`, both pure functions of history plus the date the caller passes in
- `logWorkout(date, id, rating)`, which adds the entry and returns whether the program-complete screen should show now
- `shouldShowProgramComplete(today)` and `markProgramCompleteShown()`

The recommended workout is never stored. It is derived from the newest entry.

### Recommendation

Ratings move the last workout by -1, 0, +1, or +2 (`Bad`, `OK`, `Good`, `Great`). Days off are the full calendar days strictly between the newest entry and today, so a Monday run and a Thursday today are 2 days off. The same day or the next day is 0. The penalty is 0 for 0–2 days, then 1, 2, and 3 for 3, 4, and 5 days. Six or more days restarts at workout 1 and does not mark the program complete, whatever the last rating was.

Otherwise the recommendation is `last workout + rating step - penalty`, clamped to 1..40. `Bad` on workout 1 stays on 1. `Good` or `Great` past 40 stays on 40. Empty history recommends workout 1.

Program completion is that same result before clamping. If it would be 41 or higher, `Recommendation.programComplete` is true. That is true for a workout just logged and for a rating change on the newest entry. The UI asks `shouldShowProgramComplete` and, after showing the screen, calls `markProgramCompleteShown`. The flag is not set merely because completion was detected, and `clear()` does not reset it. Logging workout 1 does reset it, including a backdated workout 1 that is not the newest entry, so a later completion can show the screen again. An add that the cap rejects does not reset it. The signal is derived from the newest entry and today, so enough days off can clear it again. `logWorkout` returns `shouldShowProgramComplete` after a successful add, so the rating screen and a later History rating change (phase 4) use the same rule. With a full history, logging today's run drops the oldest entry as usual and can still show the screen. An entry the cap rejects (only possible when future-dated entries fill the store) logs nothing and shows nothing, although the FIT activity is already saved.

### Pre-run warnings

`PreRunWarnings.evaluate` returns every warning that applies, in this priority order:

1. `ALREADY_LOGGED_TODAY` — any entry dated today. Message: "It is recommended that you run no more than once per day."
2. `SEVEN_CONSECUTIVE_DAYS` — each of the previous 6 calendar days has at least one entry, so a run today would be the 7th day in a row. Message: "It is recommended that you run no more than six times per week."

There is no check for too few recent runs.

### Screens

There is no migration from the old `WorkoutIndex` storage key; no installed copies need it.

The first screen is a Menu2 titled with the app name. Its only item is Run. Back from that menu exits. History, Instructions, and About are later phases.

Run opens a Menu2 with one item per workout. The label is `#1  R1 W1 ×3`: the id, run, walk, and repeat count. A whole number of minutes is `R1` or `R30`; anything else is `m:ss`, such as `R1:30`. A workout with no walk omits `W` and a single repeat omits the count, so workout 33 is `#33  R9 W1` and workout 40 is `#40  R30`. The subtitle is the total of that activity sequence, rounded to the nearest minute (30 seconds and above rounds up). Workout 1 is `16 min with walks`: warm-up, three runs, three walks (the last one before cool-down), and cool-down. A workout with no walk interval omits `with walks`. The recommended workout is focused, and its subtitle is prefixed with a star.

Choosing a workout runs `PreRunWarnings`. No warning starts the workout. Otherwise the warnings are shown one at a time, highest priority first, each with Continue and Cancel. Continue moves to the next warning, and after the last one it starts the workout. Cancel or Back on any warning returns to the list. Up and Down move between the two actions. The message is wrapped to fit the middle of the round face, with no title. `TextWrap` does the greedy word wrap through a `TextMeasure` port, so it is unit tested with a fake measure; it avoids `Graphics.fitTextToArea`. The view draws text directly so the blue focus bar is centered on the focused action. The workout list marks the recommended workout with "*", because the fēnix 5X fonts have no ★ glyph.

The in-progress screen shows the step (Warm up, Run, Walk, or Cool down) above a large centered countdown, the time left in the whole workout, and the repeat such as `1/8`. The step is at `10%`, the countdown is centered, the workout time remaining is at `73%`, and the repeat stays centered at the bottom (`85%`). Start/Stop pauses and resumes. While paused, the countdown turns yellow and a Paused label is shown. The timer and the five-second tones stop while paused. Back while running pauses, so Back alone never quits. Back while paused opens "End workout?", a Menu2 with Resume (focused, so a stray press keeps the run), Save, and Discard. Back on that menu stays paused. Discard throws the recording away and returns to the main menu with no history entry. Save saves the recording and goes to the rating. When the last segment reaches zero, the recording stops and the rating replaces the workout.

The rating is a Menu2 titled "How did it go?" with Bad, OK, Good, and Great. Good is focused, so its title shows only after scrolling up to Bad. Back does nothing; a finished run must be rated. Choosing a rating saves the recording if it is not saved yet, logs today, the workout id, and the rating, and returns to the main menu. If that rating takes the recommendation past workout 40 and the program-complete screen has not been shown for this program, "Program complete" is shown instead, once; Select or Back on it returns to the main menu. The recommendation stays at 40.

### Recording

`WorkoutRecording.Recorder` owns the recording lifecycle and talks to a `RecordingPort`. `FitRecordingPort` is the real port: it turns on continuous GPS and the heart-rate sensor and creates an `ActivityRecording` session (sport running, sub-sport generic, named after the app). The workout starts recording when it opens, stops the session timer on pause, starts it again on resume, and adds a lap at every segment change after the warm-up. Save and discard turn GPS and the sensor back off. Save is idempotent, so the end prompt and the rating can both call it. If the app is stopped with a recording still open, `ReturnToRunApp.onStop` saves it. The FIT file reaches Garmin Connect on the watch's next sync. `Activity.SPORT_RUNNING` needs API 3.2 and the fēnix 5X is 3.1.6, so the code uses the deprecated `ActivityRecording.SPORT_RUNNING` and `SUB_SPORT_GENERIC`, which have the same values; the compiler warns about them. The manifest asks for the Fit, Positioning, and Sensor permissions.

Every segment, including warm-up and cool-down, starts with one vibration: duty cycle 100 for 1000 ms. Connect IQ has no built-in vibration preset, so that single pulse is the segment cue. Workout complete is three 500 ms pulses at the same duty cycle, separated by 250 ms gaps. Each of the last five seconds of a segment (5, 4, 3, 2, 1) plays one short tone when the device has `Attention.playTone` and `System.getDeviceSettings().tonesOn` is true. Those beeps do not vibrate, and they do not play while paused. The next segment's vibration follows the last beep. Which seconds beep, which repeat a segment index is, which alert a segment gets, the list text, the duration totals, the warning message, text wrapping, the workout session transitions (pause, end prompt, save, discard, rating), and the recording lifecycle are UI-free (`CountdownTones`, `IntervalCount`, `SegmentAlerts`, `WorkoutListFormat`, `WorkoutDuration`, `WarningMessages`, `TextWrap`, `WorkoutSession`, `WorkoutRecording`). They do not import the UI, and the recorder is tested with a fake port.

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

`monkeydo` can take a test name after `-t` to run one test. Tests live in `source/tests` and use `(:test)` functions, so a normal build leaves them out. Do not commit the developer key or anything under `bin/`.
