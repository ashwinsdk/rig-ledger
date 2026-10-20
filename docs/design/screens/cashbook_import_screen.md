> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_import_screen.dart (Import from cashbook app)

Group g2. Source: lib/features/cashbook/cashbook_import_screen.dart (255 lines).

## 1. Purpose and primary user task

One-time import of a backup `.db` file from the reference cashbook app: choose a file, read the dry run (counts, period, totals, warnings), choose whether to import the notebook, confirm, watch progress, read the result. Nothing is written before confirmation; the source file is never changed; importing twice does not duplicate. Hub entry only.

## 2. Current structure

`CashbookImportScreen` (ConsumerStatefulWidget). State: `_path`, `_fileName`, `_preview` (`CashImportPreview`), `_result` (`CashImportResult`), `_error`, `_includeNotes`, `_busy`, `_progress`. Flow: `_pick` (`FilePicker.platform.pickFiles(type: any)`, then `CashbookImportService.preview(path)` synchronously) -> `_import` (`confirmCashDialog` 'Import' with counts; `CashbookImportService.run(path, includeNotes, onProgress)`; `refreshCashbookAfterImport()` refreshes books, entries and notes notifiers) -> result card with Done.
Tree: `Scaffold(cashAppBar('Import from cashbook app'))` > `CashPageBody(700)` > `ListView(16)[intro Text, ElevatedButton.icon 'Choose file' / 'Choose another file', file name, error Container (error 8 percent tint), dry-run Card (lines: Books, Transactions, Deleted transactions (kept 30 days), Notes, Period, Total Income, Total Expense, Balance, already imported warning, warnings, books list with counts, SwitchListTile 'Import notebook', LinearProgressIndicator or 'Import' button), result Card (check icon, counts, Done)]`.
Providers: `cashSettingsProvider` (watch, formatMoney), refresh via `cashBooksProvider`, `cashEntriesProvider`, `cashNotesProvider` notifiers. Date format local: `DateFormat('dd MMM yyyy')` created in `build` (import:96).

## 3. Problems found

1. Raw exception text is shown to users (`e.toString()` and 'Import failed: $e') (import:47, 80) (G2-B18). The error box uses `AppColors.error` text on an 8 percent tint (3.76:1 on near-white, fails 4.5).
2. "Already imported" warning uses `AppColors.warning` text (#F59E0B on white 2.15:1) (import:166).
3. The confirm dialog's "Import" label is red (shared `confirmCashDialog`) (G2-B07).
4. Reading the file (`CashbookImportService.preview`) runs synchronously on the UI isolate inside `_pick` (import:44-45); a large database freezes the screen with no indicator. UNVERIFIED size impact.
5. `_pick` has no busy guard and the "Choose another file" button stays enabled during `_pick`; `_busy` only disables it during import.
6. While importing, the Import button is replaced by a `LinearProgressIndicator` with no percentage text and no explanation that leaving the screen is unsafe (back is not blocked).
7. After a successful import there is no navigation hint to see the data (only Done pops); the current book is not changed.
8. Layout: one long ListView with two stacked cards and plain `_line` rows (label left, bold value right); 3 sections have inconsistent hierarchy (bold 700 and 600 titles at default size) (import:142, 174).
9. Intro text `textSecondary` (4.76:1 ok) is long and not chunked.
10. `FileType.any` allows any file; the intro says .db; no extension filter or hint when a wrong file is picked other than the service error.
11. Date format 'dd MMM yyyy' fixed here but the user's Account Ledger date format elsewhere (incons_g2 23).
12. `SwitchListTile` inside the card is the only control that is disabled while busy; the Choose button is disabled; fine.

## 4. Redesign

- `RigScaffold(appBar: RigAppBar('Import from cashbook app'), maxContentWidth 640)`. A 3-step progress indicator is NOT added (not a wizard in code); instead sections are shown top to bottom as they become relevant:
  1. `RigCard` "Choose a backup file": `bodyMedium` text (same sentence, split in two lines: first "Choose a backup file (.db) made with the Backup Data option of the cashbook app." second "You see what will be imported before anything is written."), tonal `Icons.folder_open_rounded` button "Choose file" / "Choose another file" (min 48, disabled while picking or importing); file name below as `RigListRow` with `Icons.insert_drive_file_rounded`.
  2. While the preview is read: inline 24 dp `CircularProgressIndicator` with "Reading file" (`bodySmall`); the preview runs in the same call as today (no logic change); the indicator is shown by setting a local `_reading` flag before the call and yielding one frame (`await Future.delayed(Duration.zero)`), UI only.
  3. Error: `ErrorBanner(message: friendly summary, details: raw text in an expandable "Details" row)` (`negativeContainer`, `negative` text 5.53:1); the raw string stays available through Details.
  4. Dry run `RigCard`: title "Dry run (nothing written yet)" `titleMedium`; lines as `MoneyLabelValueRow` (label `bodyMedium`, value `amountSmall`): Books, Transactions, Deleted transactions (kept 30 days), Notes, Period (range `dd MMM yyyy - dd MMM yyyy` with the ASCII hyphen, from `RigFormat.dateShort`), Total Income (`moneyIn`), Total Expense (`negative`), Balance (`primary`/`negative`). Already imported note: `RigCard` tone `outstandingContainer` with `Icons.info_rounded` and text in `outstanding` (6.26:1). Warnings listed as `bodySmall` `onSurfaceVariant` bullets. "Books" subsection: `RigSection` caption "Books" and per-book count rows. `RigSwitchRow` "Import notebook".
  5. Action: filled "Import" button full width (min 48). While busy: the button area becomes a `LinearProgressIndicator` (value `_progress`) with percent text `bodySmall` "Importing 42%" and the line "Keep this screen open"; back is not blocked (no logic change) but the line warns.
  6. Result `RigCard`: `Icons.check_circle_rounded` 24 `moneyIn` + "Import complete" `titleMedium`; counts as `MoneyLabelValueRow`s; filled "Done" (pops as today) and a tonal "Open Accounts" button is NOT added (would be new navigation).
- Confirm dialog: `ConfirmDialog(destructive: false)` with the same title 'Import', message and confirm label 'Import' in `primary`.
- Desktop: max width 640 centered; drag-and-drop is not added; Tab order top to bottom.

Tokens: `s4` page, `s3` gap between cards, `s2` row gap; radius `lg`; type `titleMedium`, `bodyMedium`, `bodySmall`, `amountSmall`; colors `moneyIn`, `negative`, `outstanding`, `outstandingContainer`, `negativeContainer`, `primary`.

State table:

| State | Rule |
|---|---|
| Default | choose card only |
| Reading | inline spinner, Choose disabled |
| Preview | dry run card |
| Importing | progress bar with percent, controls disabled |
| Error | `ErrorBanner` with Details |
| Result | success card |
| Disabled | Choose and notebook switch while importing |

Motion: cards appear with `base` 200 ms fade + 8 dp slide up; progress bar value animates linearly (framework); reduced motion removes the slide.

## 5. Logic touchpoints that must stay untouched

- `CashbookImportService.preview(path)` and `CashbookImportService.run(path, includeNotes:, onProgress:)` and the shapes `CashImportPreview` (`activeEntries`, `trashedEntries`, `notes`, `bookNames`, `entriesPerBook`, `firstDate`, `lastDate`, `totalIn`, `totalOut`, `alreadyImported`, `warnings`), `CashImportResult` (`booksCreated`, `booksMerged`, `entriesImported`, `trashedImported`, `entriesSkipped`, `notesImported`, `attachmentsDropped`).
- Dry run before any write; confirm dialog with the counts text.
- `refreshCashbookAfterImport()` order: books, entries, notes refresh.
- Balance shown = `roundMoney(totalIn - totalOut)`.
- The source file is only read; import is idempotent via the importer's legacy id (service side).
- `_includeNotes` default true.

## 6. Acceptance criteria

1. Choosing a valid backup shows the dry run with the same counts as before and writes nothing.
2. Confirming imports and shows the result counts; re-importing the same file reports all entries as skipped (no duplicates).
3. Choosing an invalid file shows a friendly error with a Details row holding the raw message.
4. "Already imported" and warnings use accessible colors (>= 4.5:1).
5. The Import confirm button is not red.
6. Controls (Choose, notebook switch) are disabled while importing; progress shows a percentage.
7. At 200 percent text, 360 dp: no overflow.
8. Large file: a spinner shows while reading.
9. After import the ledger lists show the imported books and entries without restart.

## 7. Performance notes

- `CashbookImportService.preview` runs on the UI isolate; the redesign only adds an indicator (moving it to `compute` is a logic/service change, see logic_g2.md L-11).
- `onProgress` calls `setState` per callback (import:73-75); throttle in the widget: update only when the value changes by >= 1 percent (UI-side guard), and rebuild only the progress widget (extract `_ImportProgress` with `ValueNotifier<double>`).
- `DateFormat('dd MMM yyyy')` is created in `build` (import:96): move to a `static final` (or `RigFormat.dateShort`).
- Controllers: none in this screen.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Import (dry run) | `SC.cbImport` with `F.imp=1`, `confirmUI` | lib/features/cashbook/cashbook_import_screen.dart | LargeTitleScaffold (pushed, title "Import from cashbook app"), footer text, RigButton (secondary), RigGroup rows, RigRow with RigSwitch, pinned or inline RigButton "Import", RigAlertDialog | Counts and amounts come from `CashImportPreview` unchanged. |
| Import (result) | `SC.cbImport` with `F.imp=2` | cashbook_import_screen.dart | RigCard with a check glyph and "Import complete", RigGroup rows, RigButton "Done" |  |

### R2. What changes in the redesign (supersedes section 4)

Import from cashbook app (pushed from the drawer):
1. LargeTitleScaffold, title "Import from cashbook app", back chevron.
2. Intro footer (15 sp `label2`): "Choose a backup file (.db) made with the Backup Data option of the cashbook app. You see what will be imported before anything is written." then a tonal RigButton "Choose file" ("Choose another file" after a preview).
3. Dry run (after a file is read): section caption with the file name, RigGroup of label and value rows (Books, Transactions, Deleted transactions (kept 30 days), Notes, Period using `dFull` "1 Jan 2026 to 12 Oct 2026", Total income `moneyInText`, Total expense `moneyOutText`, Balance), a footer line "N transactions were imported before and will be skipped." when applicable, a caption "Books" with a RigGroup of "<name>  <n> entries" rows, a RigRow "Import notebook" with a RigSwitch (default on), and a filled RigButton "Import".
4. Confirm: RigAlertDialog "Import": "Import N transactions, N deleted transactions and N notes into Account Ledger? Your existing data is kept and the file is not changed." Actions Cancel (default) and "Import" in `accentText` (not red).
5. Importing: the Import button area becomes a linear progress bar with "Importing 42%" and "Keep this screen open"; Android back is not blocked (no `PopScope` exists in lib/features/cashbook today; blocking back while importing would be new behaviour and is not part of this redesign).
6. Result: RigCard centred with a 48 dp check glyph (`moneyIn`) and "Import complete" (20 sp), RigGroup rows (Books created, Books merged by name, Transactions imported, Deleted transactions imported, Skipped (already imported), Notes imported), tonal RigButton "Done" (pops).
7. Error: ErrorBanner with a friendly line and an expandable "Details" row holding the raw message (not in the mockup; kept from the old design).
8. Reading a large file: an inline 20 dp spinner with "Reading file" (kept from the old design).


Old section 4 items:

- Old 4 appbar and max width: CHANGED to LargeTitleScaffold; width DROPPED.
- Old section "Choose a backup file" RigCard: CHANGED to the footer text plus the tonal button.
- Old Reading spinner and Error banner with Details: KEPT (states not drawn in the mockup).
- Old dry run RigCard with `MoneyLabelValueRow`: CHANGED to RigGroup rows; values are full amounts, never compact.
- Old Import button full width and progress bar with percent: KEPT.
- Old result card and "Done": KEPT; "Open Accounts" stays NOT added.
- Old confirm dialog: CHANGED to RigAlertDialog with the same texts.
- Old desktop paragraph: DROPPED.


States:

| State | Rule in the new look |
|---|---|
| Default | intro and Choose file only |
| Reading | inline spinner, Choose disabled |
| Preview | dry run groups and Import |
| Importing | progress bar and percent, controls disabled |
| Error | ErrorBanner with Details |
| Result | success card and counts |
| Disabled | Choose and the notebook switch while importing |


Motion: cards appear with a 200 ms fade and an 8 dp slide; the progress bar value is linear; ink press; reduced motion removes the slide.


### R3. Logic touchpoints and LR items

Untouched: `CashbookImportService.preview(path)` and `run(path, includeNotes:, onProgress:)`, the `CashImportPreview` shapes, dry run before any write, the confirm with the counts, `refreshCashbookAfterImport()` order, balance = `roundMoney(totalIn - totalOut)`, source file only read, idempotent import, `_includeNotes` default true.


- LR-24 (approved): rupee sign for totals and `dFull` for the period.
- LR-32 (approved, Phase 1): double-tap Import guard (the importer is idempotent, the guard avoids two runs at once).
- No new logic item.


### R4. Acceptance criteria delta

1. Choosing a valid backup shows the dry run with the same counts as before and writes nothing; the totals show the rupee sign.
2. Import confirm shows "Import" in `accentText`; confirming imports and shows the result; re-importing the same file reports every entry as skipped.
3. An invalid file shows a friendly error with a Details row.
4. Choose, the notebook switch and Import are disabled while importing; progress shows a percentage; double tap runs one import.
5. Text scale 200 percent and 360 dp: label and value rows wrap onto two lines; no clipping.
6. After import the ledger lists show the imported books without restart.


### R5. Parity delta

Change on purpose:

- Totals and ranges show the rupee sign and `dFull` (LR-24).
- Presentation of the dry run (rows, not cards); counts identical.


Must stay identical:

- Import tool behaviour (T-CB17): dry run, idempotence by legacy id, trash with deletion time, notebook import, source file untouched.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- Preview and run use the existing async calls; the progress callback updates a `ValueNotifier<double>` and only the bar rebuilds.
- No controllers on this screen. File picker is the existing plugin call.

