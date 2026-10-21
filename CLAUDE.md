# CLAUDE.md

A macOS menu-bar habit tracker: SwiftPM only (no Xcode project), Swift 6, SwiftUI `MenuBarExtra`
(window style), GRDB/SQLite, macOS 14+. User-facing docs are in README.md.

## Commands

```sh
make build    # debug build
make test     # Swift Testing suites in Tests/HabitCoreTests
make run      # build + launch "HabitTracker Dev" (bundle id ….dev, data in …/HabitTracker-Dev/)
make bundle   # release .app in .build/app/
make install  # release app → ~/Applications, re-registered and relaunched
swift test --filter ReminderPlannerTests   # one suite (export DEVELOPER_DIR first, see below)
```

The Makefile and `Scripts/package_app.sh` export `DEVELOPER_DIR=/Applications/Xcode.app/...`.
The Command Line Tools for macOS 27 can't build this app: they lack the SwiftUI macro plugin that
`@State` needs, and their `swift test` is flaky (swift-build #1870). When calling `swift` directly,
export the same `DEVELOPER_DIR`.

## Layout

- `Sources/HabitCore/`: pure logic and persistence; no SwiftUI. Default (nonisolated) isolation and
  `Sendable` value types. Everything here is unit tested.
  - `Calendar/`: `Day`, `DayBoundary` (04:00), `TimeOfDay`
  - `Config/`: `habits.json` parsing and validation, `SeedConfig`
  - `Storage/`: `AppDatabase` (migrations), `EntryRepository`
  - `Logging/`: `DayStatus`, `DoneScope`, `DoneMarks`, `SleepLog`, `NumberInput`
  - `Stats/`: `CompletionRate`, `DayDot`, `TrendSeries`, `StatsSnapshot`
  - `Reminders/`: `ReminderPlanner`, its inputs and outputs, `ReminderLog`
  - `Export/`: CSV
- `Sources/HabitTracker/`: the app. `.defaultIsolation(MainActor.self)` with `InferIsolatedConformances`.
  - `App/`: `AppDelegate` (composition root), `HabitStore` (`@Observable` state + edits), `DayClock`, `ConfigWatcher`
  - `Popover/` (Log tab), `Stats/`, `Settings/` (a tab, not a window), `Notifications/`, `Design/` (shared sizes)

## Conventions

- One type per file; folders by feature. Match the existing doc-comment density.
- Tests: Swift Testing (`@Test`, `#expect`), never XCTest. Inject time zones and dates; never rely
  on the machine's zone. Use `AppDatabase.inMemory()` per test.
- Write HabitCore changes tests-first, then `make test`. Run `make build` after app changes.
- No `#Preview` blocks (the user edits in VS Code).
- Prefer immutable value types with copy-on-write helpers (`DoneMarks.marking`, `ReminderLog.setting`).
- Errors: `HabitStore.report(_:doing:)` shows a banner and logs via `os.Logger` (`Log.*`). Never swallow them.
- UI follows the swiftui-pro skill:
  - `foregroundStyle`, `Button(_:systemImage:action:)`.
  - Bindings via `@Bindable`, plus writable computed properties or labeled subscripts on the store.
  - Business logic stays out of `body`.

## Data invariants (don't break these)

- **NULL vs 0.**
  - Missing row or NULL `value` = not logged; `0` = logged, didn't do it.
  - Clearing deletes the row, and the app never writes NULL.
  - "Logged" queries filter `value IS NOT NULL`.
- **Day boundary.** A logical day ends at 04:00 local time. Always go through `DayBoundary`, which
  compares absolute dates, so 01:00 counts as after 21:30.
- **Done.**
  - It writes 0 only for unlogged `binary`/`count` habits in the `DoneScope` groups.
  - `number` and `sleep` are measurements and are never auto-filled.
  - Done marks live in UserDefaults; they are UI state, not analysis data.
- **Viewing never writes.** The number and count fields keep their own text and skip saving while the
  text still equals the stored value's display text (`FieldDraft`, tested). Keep that guard.
- **Never guess numbers.** More fraction digits than a habit's `decimals` is invalid input, not
  rounded: "8,500" could be 8.5 or 8500.
- **Schema.** Add a new `DatabaseMigrator` migration for any change; never edit `v1`. Keep the
  columns plain (TEXT dates, REAL values) for pandas.
- **Config.**
  - Habit `id`s are database keys: never rename them.
  - Unknown keys in habits.json are errors on purpose, so typos surface.
  - The app only seeds `habits.json` at launch when it is missing.
  - The last config that parsed is kept in UserDefaults (`lastGoodConfig`), so a broken file at
    launch doesn't silently cancel every reminder.

## Platform quirks

- **Popover open/close.** On macOS 27, SwiftUI has no public API to open or close a window-style
  `MenuBarExtra`. `MenuBarExtraAccess` (pinned at 1.3.1) does it through `isPopoverPresented`.
  - Open: `NSApp.activate()`, then set the flag to true. Close: set it to false. Never `window.close()`.
  - `.menuBarExtraAccess` must come before `.menuBarExtraStyle`.
- **Popover size.** The popover has one fixed frame (`Design.popoverWidth/Height`), because
  MenuBarExtra windows grow but never shrink.
- **Grid rows.** Don't put modifiers on a `GridRow` itself; attach them to a cell.
- **Keyboard.** `KeyToggle`/`TagChip` use `.focusable(interactions: .edit)` + Space, so Tab reaches
  them even with macOS Keyboard navigation off. Global shortcuts live in `GlobalShortcuts`
  (hidden buttons).
- **Notifications.**
  - They need an `.app` bundle; a bare `swift run` disables them.
  - Delegate methods are `nonisolated` and hop to the main actor.
  - UN callbacks use `@Sendable` closures and return only Sendable data.
  - Pending reminders are removed before sleep, and `ReminderPlanner` decides catch-ups on wake.
  - On wake, the 5 s replan must stay the last request.
  - A clicked notification is recorded as shown (`ReminderLog.markingShown`); the click removes it
    from Notification Center, and a relaunch would otherwise send a catch-up.
  - The Dev build removes its notifications on quit.
- **Quitting.** SIGTERM (from `pkill` in the Makefile) is turned into a normal quit, so
  `applicationWillTerminate` runs.
- **Seeing the UI from a terminal.** `screencapture` lacks permission here. Temporarily render the
  popover in-process with `NSView.cacheDisplay(in:to:)` on the `MenuBarExtraWindow`'s content view
  (find it in `NSApp.windows`), and remove that code afterwards.
- **Logs.** Use `/usr/bin/log` (zsh's `log` is a builtin):
  `/usr/bin/log show --last 5m --info --predicate 'process == "HabitTrackerDev"'`.
