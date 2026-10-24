# Return to Run

A Garmin Connect IQ watch app for a return-to-run program after injury. This phase is the non-UI foundation: the workout catalog, history, recommendation, and pre-run warnings. The existing workout screen still runs a session. Later phases add the Menu2 screens (Run, History, Instructions, About), activity recording, and the post-run rating UI.

## Architecture

Workout definitions live in `resources/data/program.json` and load through `WorkoutProgram`. Ids are 1 through 40 and match the old hard-coded table: run 60 s / walk 60 s x3 up to run 1800 s / walk 60 s x1. Every workout has a 300 s warm-up and a 300 s cool-down. `Workout` still builds the same activity sequence from a definition (warm-up, then run/walk repeats, then cool-down). Nothing in the new model assumes a screen size.

`HistoryStore` is the only record of progress. An entry is a local calendar day, a workout id, and a rating (`Bad`, `OK`, `Good`, `Great`). Entries stay newest first. Several entries on the same day are allowed, and a newly added one sorts ahead of the entries already stored for that day. The store is one flat array of `[yyyymmdd, workoutId, rating]` triples under the storage key `history`, plus a boolean `programCompleteShown`. The cap is `HISTORY_ENTRY_CAP` (100). A newer entry past the cap drops the oldest; an entry that would itself fall at or past the cap is rejected and the store is unchanged. 100 triples is a few hundred integers, under the 32 KB per-value limit in `Application.Storage`, and it covers the 40-workout program more than twice including back-offs and manual edits.

`Progress` is the API the screens will call:

- add an entry on any date, change a rating, delete one entry, delete an entry and every entry older than it, or clear every entry
- `recommend(today)` and `warnings(today)`, both pure functions of history plus the date the caller passes in
- `shouldShowProgramComplete(today)` and `markProgramCompleteShown()`

The recommended workout is never stored. It is derived from the newest entry.

### Recommendation

Ratings move the last workout by -1, 0, +1, or +2 (`Bad`, `OK`, `Good`, `Great`). Days off are the full calendar days strictly between the newest entry and today, so a Monday run and a Thursday today are 2 days off. The same day or the next day is 0. The penalty is 0 for 0–2 days, then 1, 2, and 3 for 3, 4, and 5 days. Six or more days restarts at workout 1 and does not mark the program complete, whatever the last rating was.

Otherwise the recommendation is `last workout + rating step - penalty`, clamped to 1..40. `Bad` on workout 1 stays on 1. `Good` or `Great` past 40 stays on 40. Empty history recommends workout 1.

Program completion is that same result before clamping. If it would be 41 or higher, `Recommendation.programComplete` is true. That is true for a workout just logged and for a rating change on the newest entry. The UI asks `shouldShowProgramComplete` and, after showing the screen, calls `markProgramCompleteShown`. The flag is not set merely because completion was detected, and `clear()` does not reset it. Logging workout 1 does reset it, including a backdated workout 1 that is not the newest entry, so a later completion can show the screen again. An add that the cap rejects does not reset it. The signal is derived from the newest entry and today, so enough days off can clear it again.

### Pre-run warnings

`PreRunWarnings.evaluate` returns every warning that applies, in this order:

1. `ALREADY_LOGGED_TODAY` — any entry dated today
2. `SEVEN_CONSECUTIVE_DAYS` — each of the previous 6 calendar days has at least one entry, so a run today would be the 7th day in a row
3. `TOO_FEW_RECENT_RUNS` — fewer than 3 entries on the previous 6 days, excluding today. Entries are counted, not distinct days, because more than one log on a day counts. Three entries on one recent day is enough; two is not. A day seven days ago does not count.

The weekly rule is 4 to 6 runs, at most one a day. Even with today's run, fewer than 3 earlier entries in the window cannot make 4. An empty history therefore returns the frequency warning. All three warnings cannot be true together, because six previous days is already at least three runs.

### The current screen

There is no migration from the old `WorkoutIndex` storage key; no installed copies need it.

The current screen reads the recommendation when it opens. Choosing another workout in the picker changes only that session. Reaching cool-down logs that workout as `Good` for today, which is the old "advance by one" step. There is no rating screen yet. Starting a workout and leaving it no longer writes storage.

The in-progress screen shows the segment name and the remaining time. Run and walk segments also show the repeat, such as `1/8`: the current repeat out of the workout's repeat count. A run and the walk after it share that number. Warm-up (index 0) and cool-down (the last index, which is the final walk) do not. The count is between the name and the countdown, at screen-relative `15%` and `33%`, so it stays on the round 240x240 fenix 5X face. The countdown stays centered.

Every segment vibrates when it starts, including the first warm-up. Runs use the run pattern. Warm-up, walk, and cool-down use the walk pattern. Workout complete keeps its own pattern. Each of the last five seconds of a segment (5, 4, 3, 2, 1) plays one short tone when the device has `Attention.playTone` and `System.getDeviceSettings().tonesOn` is true. Those beeps do not vibrate. The next segment's vibration follows the last beep. Which seconds beep, which repeat a segment index is, and which alert a segment gets are pure functions in `CountdownTones`, `IntervalCount`, and `SegmentAlerts`. They do not import the UI.

`AppSettings.mc` is unused. It is not part of this saved state.

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

# The simulator must already be running and have the fenix5x device files.
connectiq
monkeydo bin/ReturnToRun-test.prg fenix5x -t
```

`monkeydo` can take a test name after `-t` to run one test. Tests live in `source/tests` and use `(:test)` functions, so a normal build leaves them out. Do not commit the developer key or anything under `bin/`.
