# Return to Run

A Garmin Connect IQ watch app for a return-to-run program after injury. The first screen is Run, then the workout list, pre-run warnings, and the in-progress workout. History, Instructions, About, activity recording, and the post-run rating screen come later.

## Architecture

Workout definitions live in `resources-program/data/program.json` and load through `WorkoutProgram`. Ids are 1 through 40 and match the old hard-coded table: run 60 s / walk 60 s x3 up to run 1800 s / walk 60 s x1. Every workout has a 300 s warm-up and a 300 s cool-down. `Workout` still builds the same activity sequence from a definition (warm-up, then run/walk repeats, then cool-down). Nothing in the new model assumes a screen size. A simulator build can swap in `resources-quick` (15 s warm-up and cool-down, 10 s run and walk, same ids and repeat counts); see Build and test. The normal build does not include that folder.

`HistoryStore` is the only record of progress. An entry is a local calendar day, a workout id, and a rating (`Bad`, `OK`, `Good`, `Great`). Entries stay newest first. Several entries on the same day are allowed, and a newly added one sorts ahead of the entries already stored for that day. The store is one flat array of `[yyyymmdd, workoutId, rating]` triples under the storage key `history`, plus a boolean `programCompleteShown`. The cap is `HISTORY_ENTRY_CAP` (100). A newer entry past the cap drops the oldest; an entry that would itself fall at or past the cap is rejected and the store is unchanged. 100 triples is a few hundred integers, under the 32 KB per-value limit in `Application.Storage`, and it covers the 40-workout program more than twice including back-offs and manual edits.

`Progress` is the API the screens call:

- add an entry on any date, change a rating, delete one entry, delete an entry and every entry older than it, or clear every entry
- `recommend(today)` and `warning(today)`, both pure functions of history plus the date the caller passes in
- `shouldShowProgramComplete(today)` and `markProgramCompleteShown()`

The recommended workout is never stored. It is derived from the newest entry.

### Recommendation

Ratings move the last workout by -1, 0, +1, or +2 (`Bad`, `OK`, `Good`, `Great`). Days off are the full calendar days strictly between the newest entry and today, so a Monday run and a Thursday today are 2 days off. The same day or the next day is 0. The penalty is 0 for 0–2 days, then 1, 2, and 3 for 3, 4, and 5 days. Six or more days restarts at workout 1 and does not mark the program complete, whatever the last rating was.

Otherwise the recommendation is `last workout + rating step - penalty`, clamped to 1..40. `Bad` on workout 1 stays on 1. `Good` or `Great` past 40 stays on 40. Empty history recommends workout 1.

Program completion is that same result before clamping. If it would be 41 or higher, `Recommendation.programComplete` is true. That is true for a workout just logged and for a rating change on the newest entry. The UI asks `shouldShowProgramComplete` and, after showing the screen, calls `markProgramCompleteShown`. The flag is not set merely because completion was detected, and `clear()` does not reset it. Logging workout 1 does reset it, including a backdated workout 1 that is not the newest entry, so a later completion can show the screen again. An add that the cap rejects does not reset it. The signal is derived from the newest entry and today, so enough days off can clear it again.

### Pre-run warnings

`PreRunWarnings.evaluate` returns at most one warning, the first that applies in this priority order, or null:

1. `ALREADY_LOGGED_TODAY` — any entry dated today. Message: "It is recommended that you run no more than once per day."
2. `SEVEN_CONSECUTIVE_DAYS` — each of the previous 6 calendar days has at least one entry, so a run today would be the 7th day in a row. Message: "It is recommended that you run no more than six times per week."

There is no check for too few recent runs.

### Screens

There is no migration from the old `WorkoutIndex` storage key; no installed copies need it.

The first screen is a Menu2 titled with the app name. Its only item is Run. Back from that menu exits. History, Instructions, and About are later phases.

Run opens a Menu2 with one item per workout. The label is `#1  R1 W1 ×3`: the id, run, walk, and repeat count. A whole number of minutes is `R1` or `R30`; anything else is `m:ss`, such as `R1:30`. One repeat has no walk interval, because `Workout.getActivityAtIndex` replaces that walk with the cool-down, so workout 40 is `#40  R30`. The subtitle is the total of that activity sequence, rounded to the nearest minute (30 seconds and above rounds up). Workout 1 is `15 min with walks`: 15 minutes, not 16, because the last walk is the cool-down rather than an extra interval on top of it. A workout with no walk interval omits `with walks`. The recommended workout is focused, and its subtitle is prefixed with a star.

Choosing a workout runs `PreRunWarnings`. No warning starts the workout. Otherwise one screen shows that warning, plus Continue and Cancel. Cancel and Back return to the list. Continue starts the workout anyway. Up and Down move between the two actions. The message is wrapped to fit the middle of the round face, with no title. The view draws text directly so the blue focus bar is centered on the focused action. The workout list marks the recommended workout with "*", because the fēnix 5X fonts have no ★ glyph.

The in-progress screen shows the step (Warm up, Run, Walk, or Cool down) above a large centered countdown, the time left in the whole workout, and the repeat such as `1/8`. The step is at `10%`, the countdown is centered, the workout time remaining is at `73%`, and the repeat stays centered at the bottom (`85%`). Start/Stop pauses and resumes. While paused, the countdown turns yellow and a Paused label is shown. The timer and the five-second tones stop while paused. Back while running pauses. Back while paused asks "End workout?". Yes returns to the main menu and does not log. No stays paused. Reaching cool-down still logs the workout as Good for today; ending later, during cool-down, does not remove that entry. When the last segment reaches zero, the app returns to the main menu. Save, discard, and the rating screen are phase 3.

Every segment, including warm-up and cool-down, starts with one vibration: duty cycle 100 for 1000 ms. Connect IQ has no built-in vibration preset, so that single pulse is the segment cue. Workout complete is three 500 ms pulses at the same duty cycle, separated by 250 ms gaps. Each of the last five seconds of a segment (5, 4, 3, 2, 1) plays one short tone when the device has `Attention.playTone` and `System.getDeviceSettings().tonesOn` is true. Those beeps do not vibrate, and they do not play while paused. The next segment's vibration follows the last beep. Which seconds beep, which repeat a segment index is, which alert a segment gets, the list text, the duration totals, the warning message, and the pause transitions are pure functions (`CountdownTones`, `IntervalCount`, `SegmentAlerts`, `WorkoutListFormat`, `WorkoutDuration`, `WarningMessages`, `WorkoutSession`). They do not import the UI.

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
