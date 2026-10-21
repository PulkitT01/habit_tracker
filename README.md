# HabitTracker

A personal habit tracker that lives in the macOS menu bar. Logging a day takes a few seconds,
mostly from the keyboard. It reminds you morning and evening, makes backfilling yesterday one
click, and stores everything in a plain SQLite file that pandas can read directly.

- Swift 6, SwiftUI `MenuBarExtra`, SwiftPM only (no Xcode project), macOS 14+.
- Data and config: `~/Library/Application Support/HabitTracker/` (`habits.json`, `habits.sqlite`).
- New habits are added in `habits.json`; no code changes needed.

## Setup

Requirements: macOS 14 or later, and **Xcode installed** (27 on macOS 27). Only Xcode's toolchain is
used, selected automatically by the Makefile and the packaging script. You still edit in any editor
and build from the terminal. The Command Line Tools alone can't build the app on macOS 27: they lack
the SwiftUI macro plugin that `@State` needs.

```sh
make test      # unit tests (Swift Testing)
make install   # build, copy to ~/Applications/HabitTracker.app, and launch
```

| Target | What it does |
|---|---|
| `make build` | Debug build of every target. |
| `make test` | Runs the HabitCore unit tests. |
| `make bundle` | Release build, assembled into `.build/app/HabitTracker.app` (LSUIElement, ad-hoc signed). |
| `make run` | Builds and launches **HabitTracker Dev**: bundle id `….HabitTracker.dev`, data in `~/Library/Application Support/HabitTracker-Dev/`. Development never touches your real data. Its notifications are removed when it quits. |
| `make install` | Quits the installed copy, installs the release app to `~/Applications`, registers it with Launch Services and launches it. |
| `make clean` | Removes build products. |

**First launch.**
1. Allow notifications when macOS asks.
2. Open the popover, go to **Settings** and turn on **Launch at login**. That way the app is
   always running and reminds you; you never have to remember to open it.
3. The first launch writes a starter `habits.json` with the 12 seed habits, active from the date you
   installed.

To launch it yourself later, use Spotlight (“HabitTracker”) or `open ~/Applications/HabitTracker.app`.

## Logging

Click the menu-bar icon, or a reminder notification. The icon shows today's state:
- ○ nothing logged yet
- ◐ partly logged
- ✓ done

| Key | Action |
|---|---|
| Tab / Shift-Tab | Move between habits (focus starts on the first unlogged one) |
| Space | Toggle a checkbox or tag chip |
| ↩ | In a number field: next field |
| ↑ / ↓ | In a count field: ±1 |
| ⌫ | On a checkbox: clear the entry (back to "not logged") |
| ⌘↩ | **Done** |
| ⌘[ / ⌘] | Previous / next day |
| ⌘1 / ⌘2 / ⌘3 | Log / Stats / Settings |
| ⌘R | Reload `habits.json` |

These work without macOS's "Keyboard navigation" setting.

- **Done** writes 0 for every checkbox and count you didn't touch ("didn't do it"), marks the group
  finished, and closes the popover. Weight, sleep and other `number`/`sleep` habits are
  measurements and are never filled in: a skipped weigh-in stays "not logged".
  - For today, Done covers the morning group always, and the evening group once you've logged an
    evening habit or the evening reminder time has passed.
  - For past days it covers everything.
- **Backfilling:** when yesterday isn't finished, a banner offers **Log Yesterday** (one click, or ⌘[).
  The date field reaches any earlier day.
- Each row's trailing mark keeps "not logged" (dotted ring) apart from "not done" (✕).
- A field gets a red outline when its text can't be saved as typed, and nothing is saved until you fix
  it. That covers letters, and more decimal places than the habit's `decimals` (for example "8,500"
  for a whole-number habit, which could mean 8.5 or 8500).
- Right-click a habit's name to clear its entry. Hover the name to see its description.
- The day note ("sick", "travelling") is saved as you type.

## Habits: `habits.json`

The app re-reads the file within 2 seconds of a save (or via ⌘R / gear menu → Reload Config;
gear → Edit habits.json opens it). If the file is invalid, the app keeps the last valid
habits and shows the error, such as `habit 'pushups': unknown key 'min_targt'`. It keeps them across
restarts too, so reminders keep working. Only if no valid version has ever loaded does the menu-bar
icon turn into a warning triangle.

```json
{
  "habits": [
    {
      "id": "pushups",
      "name": "Push-ups",
      "type": "count",
      "unit": "reps",
      "min_target": 5,
      "prompt": "evening",
      "order": 10,
      "active_from": "2026-10-20"
    }
  ]
}
```

| Key | Required | Meaning |
|---|---|---|
| `id` | yes | Stable key stored in the database: `a–z`, `0–9`, `_`. **Never change it**; rename via `name`. |
| `name` | yes | Shown in the popover. |
| `description` | | Tooltip; put definitions here ("girlfriend doesn't count"). |
| `type` | yes | `binary` (checkbox), `count` (whole number + stepper), `number` (measurement), `sleep` (bed/wake times). |
| `unit` | | Shown after the field: `kg`, `s`, `reps`. |
| `decimals` | | `number` only: digits after the decimal point (0–3, default 0). |
| `min_target` | | Count/number/sleep: the value that counts as done (otherwise anything above 0). |
| `trend` | | `number` only: `true` shows an EWMA trend, weekly rate and sparkline in Stats. |
| `prompt` | yes | `morning` or `evening`: section and reminder. |
| `order` | yes | Sort order within the section (the seed uses 10, 20, …). |
| `active_from` | yes | First tracked day (`YYYY-MM-DD`). Earlier days are "not tracked", never "missing". |
| `active_to` | | Last tracked day, to retire a habit without losing its history. |
| `tags` | | `binary` only: optional chips, multi-select (socializing: india / here / new people). |

**Adding a habit:** add an object with a new `id`, set `active_from` to today, and save. To stop
tracking one, set `active_to` rather than deleting it. Either way, its rows stay in the database
and in exports.

## Data

### The day boundary
A day ends at **04:00** local time, so logging at 01:00 counts toward the previous day. Dates are
the local wall-clock date shifted this way, which keeps daylight-saving changes harmless.

### NULL vs 0
- **No row (or NULL `value`):** not logged.
- **`0`:** logged, didn't do it.

These are never conflated. Clearing an entry deletes its row, and the app never writes NULL.

### Schema
`habits.sqlite` uses SQLite's default rollback journal, so it is always a single self-contained file.
GRDB adds a `grdb_migrations` bookkeeping table.

```sql
CREATE TABLE entries (
    date      TEXT NOT NULL,  -- logical day YYYY-MM-DD; a day ends at 04:00 local time
    habit_id  TEXT NOT NULL,  -- id from habits.json
    value     REAL,           -- NULL or no row = not logged; 0 = logged, didn't do it
    detail    TEXT,           -- binary tags "india,here" or sleep "23:30-07:15"
    logged_at TEXT NOT NULL,  -- ISO 8601 time of the last edit, with UTC offset
    source    TEXT NOT NULL,  -- 'manual', or 'auto_zero' when filled by Done
    PRIMARY KEY (date, habit_id)
);
CREATE TABLE day_notes (
    date TEXT NOT NULL PRIMARY KEY,  -- logical day YYYY-MM-DD
    note TEXT NOT NULL               -- free text such as "sick" or "travelling"
);
```

- **binary:** 1 or 0. Choosing a tag also sets 1; tags are comma-joined in `detail` in config order.
- **count / number:** the value; numbers are rounded to the habit's `decimals`.
- **sleep:** stored on the day you **wake up**. `value` is the real hours slept (2 dp; daylight-saving
  nights are an hour shorter or longer) and `detail` is `"HH:MM-HH:MM"`.
- **`logged_at`:** updated on every edit. Offsets vary with DST and travel, so parse with `utc=True`.
- **`source`:** `manual` for direct input, `auto_zero` for zeros written by Done. Future clients
  (a phone app, an importer) can add their own values.

### Reading it from pandas

```python
import json
import sqlite3
from contextlib import closing
from pathlib import Path

import pandas as pd

folder = Path.home() / "Library/Application Support/HabitTracker"
db = folder / "habits.sqlite"
# Read-only is safe while the app runs; as_uri() escapes the space in "Application Support".
with closing(sqlite3.connect(db.as_uri() + "?mode=ro", uri=True)) as con:
    entries = pd.read_sql("SELECT * FROM entries", con, parse_dates=["date"])
    notes = pd.read_sql("SELECT * FROM day_notes", con, parse_dates=["date"])

entries["logged_at"] = pd.to_datetime(entries["logged_at"], utc=True)

# One row per day, one column per habit: NaN = not logged, 0 = logged but not done.
# reindex/asfreq add habits and days with no rows at all (also NaN; mask days before a habit's
# active_from if that matters).
habit_ids = [h["id"] for h in json.loads((folder / "habits.json").read_text())["habits"]]
wide = (
    entries.pivot(index="date", columns="habit_id", values="value")
    .reindex(columns=habit_ids)
    .asfreq("D")
)

# The app's weight trend: EWMA over logged values, alpha 0.1.
weight = wide["weight"].dropna()
trend = weight.ewm(alpha=0.1, adjust=False).mean()

# Socializing tags, one row per (day, tag).
social = entries.query("habit_id == 'socializing' and value == 1")
tags = social.assign(tag=social["detail"].str.split(",")).explode("tag")
```

### Export
**Settings → Export CSV…** writes `entries.csv` (the table above, long format, every row) and
`day_notes.csv` into a folder you choose. Existing files with those names are replaced. Empty fields
are NULL.

## Stats

- **7-day dots:** done (filled), not done (✕), not logged (dotted ring), not tracked yet (dash).
- **7d / 28d rates:** done ÷ eligible days.
  - Days before `active_from` (or after `active_to`) aren't eligible.
  - Unlogged past days count as not done.
  - The window ends today once today is logged, and yesterday until then, so rates don't dip every morning.
  - Hover a rate for the done / not done / not logged split.
  - Done means 1 for binary habits, otherwise at least `min_target` (or above 0).
- **Trend habits** (weight):
  - The latest value, its EWMA trend (alpha 0.1, one step per logged value, the same as pandas
    `ewm(alpha=0.1, adjust=False)`), and the weekly rate.
  - The weekly rate is the change in trend from the most recent value at least 7 days earlier,
    scaled to 7 days.
  - The sparkline shows 28 days of values (dots) against the trend (line).

## Reminders

- **Times:** the morning reminder (default 08:30) and evening reminder (21:30) list the habits still
  unlogged. Change them in Settings.
- **Follow-up:** sent once, 45 minutes (configurable) after the reminder, and only if that group is
  still unlogged. A group counts as logged when every habit has a value or you pressed Done.
- **Already logged:** no reminder at all, and logging clears the banner.
- **Clicking a notification** opens the popover on that day.
- **Mac asleep at reminder time:** you get one catch-up when it wakes, with the follow-up 45 minutes
  after that, never a pile of stale banners.

## Troubleshooting

- **No notifications:** Settings shows the permission state, with a button to System Settings.
- **Launch at login:**
  - Only the installed copy (in `~/Applications` or `/Applications`) can enable it.
  - If macOS asks for approval, use the button shown in Settings.
- **Logs:** `/usr/bin/log stream --predicate 'subsystem == "io.github.pulkitt01.HabitTracker"'`.
  Use the full path: zsh has its own `log` builtin.
- **"plugin for module 'SwiftUIMacros' not found":** you're building with the Command Line Tools.
  Install Xcode, or point `DEVELOPER_DIR` at it.
