> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_notebook_screen.dart (Notebook list and _NoteTile)

Group g2. Source: lib/features/cashbook/cashbook_notebook_screen.dart (212 lines, includes `_NoteTile`).

## 1. Purpose and primary user task

Dated to-do notes: browse by period, mark done with a checkbox, filter Completed or Pending, sort by date, add a note with the floating button, open a note to edit. Stats strip: Completed, Pending, Total. Parity: PARITY-065, 067, 068.

## 2. Current structure

`CashbookNotebookScreen` (ConsumerStatefulWidget). Local state `_sel` (default Monthly), `_filter` (`_NoteFilter` all, completed, pending), `_ascending`. Provider: `cashNotesProvider` (watch), `cashSettingsProvider` (watch). `build` filters by `range.contains(n.date)`, counts completed and pending, filters by `_filter`, sorts by date (default descending). Tree: `Scaffold(cashAppBar('Notebook', [PopupMenuButton Completed, Pending, Date Ascending, Date Descending (checked)]), FAB Icons.add -> CashbookNoteFormScreen, body: CashPageBody(800) > Column[CashPeriodSelector, Expanded(empty text 'No notes' or ListView.builder of _NoteTile), stats Container (Completed / Pending / Total, `IntrinsicHeight`)])`. `_NoteTile` (159-212): `Card` > `InkWell` (edit) > Row[Column(note text 15 sp with line-through when completed, date line `formatDayHeader + formatTime` 12 sp), `Checkbox` -> `cashNotesProvider.notifier.toggleCompleted(note.id)`].

## 3. Problems found

1. Overflow `PopupMenuButton` has no tooltip (notebook:70); active filter (Completed or Pending) is not visible outside the menu (checkmarks only).
2. The FAB uses the default Material FAB with `Icons.add` over the list; the list bottom padding is 80 to clear it (notebook:127) but the stats strip sits below the list, so the FAB overlaps the strip's right edge area on short screens (FAB floats above the body, strip is in the body) (notebook:107-151).
3. Stats strip: bordered Container with `IntrinsicHeight` and `VerticalDivider`s; text colors `CashColors.income` for Completed and `CashColors.expense` for Pending (red means negative; Pending is not an error) (notebook:143-148).
4. Note text has no `maxLines`; very long notes make tall cards (notebook:180-191).
5. Completed notes use `textSecondary` + line-through; contrast fine; the checkbox is the only completion control; tapping the row opens edit, so mis-taps near the checkbox edit instead of toggling (checkbox 48 dp but card padding right 8) (notebook:173,200).
6. Date text uses `formatDayHeader` (fixed pattern) + time, ignoring the user's date format (notebook:194).
7. Empty state bare text `textHint` (notebook:123-125).
8. No feedback on toggle (no animation); the stats update instantly (acceptable) but the item may jump out of the filtered list instantly under Pending/Completed filters.
9. `_NoteTile` is a `Card` with default elevation and `margin: bottom 8`.
10. "Report" overflow item from the reference app is absent (documented skip, T-CB13).

## 4. Redesign

- `RigScaffold(appBar: RigAppBar(title: 'Notebook', actions: [RigMenuButton]), fab: standard FAB with `Icons.add_rounded` and tooltip "Add note"; the stats card moves into `bottomBar` and the FAB floats above it (`FloatingActionButtonLocation.endFloat`, bar height reserved) so it never overlaps the stats card; maxContentWidth 640 on medium, 1100 on expanded)`.
- `RigMenuButton` groups: [Completed (checked), Pending (checked)] divider [Date Ascending (checked), Date Descending (checked)] (same labels and toggles).
- Period: `RigChipRow` + `PeriodNavigator` (shared).
- `FilterSummaryBar` (home doc) appears when `_filter != all` or `_ascending`: chips "Completed"/"Pending" and "Oldest first", remove icons change only that facet; "Clear" resets both.
- Note row `RigCard` (radius `lg`, padding `s4`, min height 72): left `Checkbox` (48 dp hit, moved to the left so it is away from the row's tap-to-edit area; same callback `toggleCompleted(note.id)`), body: text `bodyLarge` maxLines 4 ellipsis (line-through and `onSurfaceVariant` when completed), date line `bodySmall` `onSurfaceVariant` using `settings.formatDayHeader` + `formatTime` (strings unchanged). Tap on the body opens edit (same as today); the checkbox and the body are separate hit regions (checkbox does not trigger edit).
- Stats: `RigStatStrip` in a `RigCard` tone `container`: Completed (`moneyIn`), Pending (`outstanding`, replaces red), Total (`onSurface`); label `labelMedium`, value `amountMedium` (integers). Values unchanged.
- Empty: `EmptyState(icon: Icons.sticky_note_2_rounded, title: 'No notes', hint: 'Tap + to add a note', action: tonal 'Add note')` (title text unchanged; hint and action are added copy). With an active filter: hint "No notes match the filter" and a "Clear filters" action.
- Desktop: list max width 720 centered; hover on row; Enter opens edit, Space toggles the focused checkbox; Cmd+N is NOT bound here (reserved for the ledger entry).

Tokens: `s4` page, `s2` between cards; radius `lg`; type `bodyLarge`, `bodySmall`, `amountMedium`; colors `moneyIn`, `outstanding`, `onSurface`, `onSurfaceVariant`, `outlineVariant`.

State table:

| State | Rule |
|---|---|
| Default | note cards |
| Loading | none |
| Empty | two variants above |
| Error | none |
| Completed row | line-through, `onSurfaceVariant` |
| Filtered | `FilterSummaryBar` |

Motion: toggling completion animates the line-through and color in `fast` (150 ms); a row leaving a filtered list fades out in `fast` via `AnimatedSwitcher`; no other list animation.

## 5. Logic touchpoints that must stay untouched

- `cashNotesProvider` data, `cashNotesProvider.notifier.toggleCompleted(note.id)`.
- Period filter `range == null || range.contains(n.date)`; completed and pending counts are over the period (not over the `_filter`); `_filter` toggle semantics (selecting the active filter again returns to all); `_ascending` default false; sort by `date`.
- Stats: Completed, Pending, Total of the period.
- Tap on a note pushes `CashbookNoteFormScreen(note: note)`; FAB pushes `CashbookNoteFormScreen()`.
- `_NoteFilter` enum values.

## 6. Acceptance criteria

1. Notes of the selected period appear sorted by date descending by default; ascending via the menu.
2. Checking a note marks it completed immediately and updates Completed, Pending counts; unchecking reverses.
3. Completed filter shows only completed notes; Pending only pending; stats still count the whole period.
4. Tapping a note opens its edit form; tapping the checkbox does not.
5. FAB opens an empty note form; it never covers the stats card or the last list row.
6. Active filter or sort shows a chip row with working remove icons.
7. At 200 percent text: no overflow; note text wraps up to 4 lines.
8. Pending count uses the amber role, not red.

## 7. Performance notes

- `build` recomputes `inPeriod`, counts, `shown` and sorting on every rebuild (notebook:34-50); memoize in a small provider-free helper keyed by (notes identity, `_sel`, `_filter`, `_ascending`) or compute inside a `Consumer` with `select`.
- `_NoteTile` is a ConsumerWidget but only reads the notifier on tap; make it a plain `StatelessWidget` with a callback and `ValueKey(note.id)`.
- `ListView.builder` already lazy; remove `IntrinsicHeight` in the stats strip.
- Settings watch: only `formatDayHeader`/`formatTime` needed; pass formatted strings, or `select` the format fields.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Notebook | `SC.cbNotebook`, `nbMenu`, `setNp` | lib/features/cashbook/cashbook_notebook_screen.dart | LargeTitleScaffold (pushed, trailing Add and More glass buttons), RigChipRow, period navigator, three RigCards (Completed, Pending, Total), RigGroup sections "Pending" and "Completed" of note rows with RigCheck and RowActions, EmptyState, RigSheet (menu) | The mockup replaces the FAB with a trailing "+" button. |
| Notebook empty | `SC.cbNotebook` with `UI.state=empty` | cashbook_notebook_screen.dart | EmptyState (icon `sticky_note_2`, "No notes", "Tap + to write a note.") |  |

### R2. What changes in the redesign (supersedes section 4)

Notebook (pushed from the drawer):
1. LargeTitleScaffold, title "Notebook", back chevron, trailing glass buttons Add (plus, opens the note form) and More (opens the menu sheet).
2. RigChipRow (All, Daily, Weekly, Monthly, Yearly) and the period navigator.
3. Stats: three RigCards in a row (gap 12): Completed (`moneyInText`), Pending (`moneyOutText` in the mockup; see conflicts_r3.md C-12 for the amber `outstandingText` option), Total (`label`), label 12 sp weight 600, value 22 sp integer.
4. Lists: caption "Pending" then a RigGroup of pending notes; caption "Completed" then a RigGroup of completed notes. Each row: a circular RigCheck at left (48 dp target, `accent` fill, white check), the note text 17 sp weight 400 (struck through and `label2` when completed), the date and time (`dGroup`, `fT`) in 13 sp `label2` below. Tap on the text opens the note form; tap on the check toggles completion (unchanged). RowActions: swipe left shows Edit and Delete; Delete shows the existing confirm "Delete this note?" (the mockup shows a snackbar only, conflicts_r3.md C-13).
5. Menu sheet (More): RigGroup of Completed, Pending, Date Ascending, Date Descending with a check mark on the active filter and sort (the mockup draws the check only on Date Descending; all four use check marks in the code).
6. Empty: EmptyState "No notes", "Tap + to write a note."; with an active filter the hint becomes "No notes match this filter" (existing copy from the old doc).
7. Bottom padding inset + 24 dp (no tab bar on the pushed screen, no FAB).


Old section 4 items:

- Old 4 FAB with the stats card in a bottom bar: CHANGED to the trailing Add button and the stats strip at the top; FAB DROPPED.
- Old RigMenuButton groups: CHANGED to a RigSheet; labels and toggle semantics KEPT.
- Old RigChipRow plus PeriodNavigator: CHANGED to the mockup chips and navigator (navigator shows static month in the mockup; the real navigator shifts the period).
- Old FilterSummaryBar with per-facet remove icons: DROPPED (mockup shows none); filters are changed in the menu sheet.
- Old note row `RigCard` with a left Checkbox: CHANGED to rows in RigGroups split into Pending and Completed sections (the mockup sections); circular RigCheck KEPT.
- Old stats strip card `RigStatStrip`: CHANGED to three RigCards.
- Old empty state with a tonal action button: CHANGED to the icon, title and hint; the action button is DROPPED (the trailing Add button exists).
- Old desktop paragraph and row hover: DROPPED.
- Old motion (line-through fade, AnimatedSwitcher): CHANGED to ink press and an instant strike-through (reduced motion safe).


States:

| State | Rule in the new look |
|---|---|
| Default | stats, Pending and Completed groups |
| Loading | not applicable |
| Empty | EmptyState (two variants) |
| Error | not applicable |
| Completed row | strike-through, `label2` |
| Filtered | only the matching section is shown; stats still count the whole period |


Motion: ink press; menu sheet rise 250 ms; reduced motion removes durations.


### R3. Logic touchpoints and LR items

Untouched: `cashNotesProvider` data and `toggleCompleted(note.id)`, period filter `range == null || range.contains(n.date)`, counts over the period (not the filter), filter toggle semantics (selecting the active filter again returns to all), `_ascending` default, row tap opening `CashbookNoteFormScreen(note:)`, Add opening an empty form.


- LR-25 (approved): the note form opened from here carries the discard prompt.
- LR-24 (approved): `dGroup` and `fT` formats.
- No new logic item. Swipe Delete reuses the existing `deleteNote` with its confirm.


### R4. Acceptance criteria delta

1. Notes of the selected period appear in the Pending and Completed sections sorted by date descending by default and ascending via the menu.
2. Checking a note moves it to Completed immediately and updates the counts; unchecking reverses.
3. Tapping the note text opens its form; tapping the check does not.
4. Swipe Delete asks "Delete this note?" before deleting.
5. Completed and Pending filters show one section; the stats keep counting the whole period.
6. At text scale 200 percent note text wraps up to 4 lines; the stats cards stack; nothing is clipped.
7. Light and dark; targets 48 dp; Android back pops.


### R5. Parity delta

Change on purpose:

- PARITY-065: the list is split into Pending and Completed sections (mockup).
- PARITY-066: Add is a trailing button, not a FAB.
- Pending stat colour follows the mockup (`moneyOutText`) unless C-11 resolves to amber.


Must stay identical:

- PARITY-065 period tabs and stats, PARITY-066 add and edit, PARITY-067 check toggles completion, PARITY-068 Report stays a deviation (no PDF for notes).


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- List strategy: `SliverList` per section; rows have `ValueKey(note.id)`; one transparent Material for ink.
- No controllers on this screen.

