> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_report_dialog.dart (Report dialogs and export runner)

Group g2. Source: lib/features/cashbook/cashbook_report_dialog.dart (151 lines).

## 1. Purpose and primary user task

Create a PDF or CSV report: for the book on screen with the active period, search and filters (`showCashReportDialog`), or for all books for a period (All or a custom range) (`showCashReportAllDialog`, the hub's "Report-All Accounts" item). The file is saved or shared through `FileSaveService`. Parity: PARITY-069..072, 074 (PDF and CSV only).

## 2. Current structure

- `showCashReportDialog(context, ref, data)`: `SimpleDialog` 'Report' with options 'PDF' and 'CSV' (`_Format`), then `runCashExport`.
- `runCashExport(context, ref, data, pdf)`: empty rows -> error snackbar 'Nothing to export'; builds bytes (`CashbookExportService.loadFonts` + `buildPdf`, or `buildCsvBytes`), `FileSaveService.saveFile(fileName: CashbookExportService.fileName(data, ext), shareSubject: 'RigLedger Account Ledger report', dialogTitle: 'Save report')`; success snackbar 'Report exported'; failure snackbar 'Failed to export: $e'.
- `showCashReportAllDialog`: `StatefulBuilder` `AlertDialog` 'Report - All Accounts': `Wrap` of two `ChoiceChip`s ('All', 'Select Date Range' or the chosen range label via `pickCashDateRange`), `SegmentedButton<bool>` PDF/CSV, Cancel/OK; then `buildAllBooksExport(ref, range)` (all non-deleted entries, ascending rows, `bookNames` map) and `runCashExport`.
- Local variables `range`, `pdf` inside the builder closure (no controllers).
Providers read: `cashSettingsProvider`, `cashBooksProvider`, `cashEntriesProvider`.

## 3. Problems found

1. No progress indication while the PDF is generated (report:44-51) (G2-B19); double taps can open two share sheets.
2. The format chooser is a `SimpleDialog` with two plain text options (report:18-28); no icons, no description of what each produces; tapping a row closes and immediately starts a long operation.
3. All-accounts dialog: ChoiceChip 'Select Date Range' doubles as a button and a selected state; after a range is chosen the chip's label becomes the long range string with the ASCII arrow (`rangeLabel`) and may wrap or overflow in a 280 dp dialog width (report:91-100). Tapping the chip again reopens the picker (no way to see it is editable).
4. `pickCashDateRange(ctx, ...)` is awaited inside `onSelected` using the dialog's `ctx` and then `setLocal` (report:96-99): if the dialog is dismissed while the picker is open, `setLocal` could run on a disposed state (the picker is modal above it, so the barrier cannot be tapped; low risk, UNVERIFIED).
5. 'Nothing to export' and the export errors are default snackbars; error text includes the raw exception (`Failed to export: $e`).
6. Dialog buttons: 'OK' label (not specific, e.g. "Export"); both text buttons.
7. Subject and file names are fixed strings (export content, unchanged in the redesign).
8. `runCashExport` depends on a live `BuildContext` after awaits; guarded with `context.mounted` (report:51, 59, 61): correct.

## 4. Redesign

- Single-book report: `RigChoiceDialog` titled "Report" (sheet on compact, dialog on expanded, max width 400) with two `RigListRow`s: "PDF" (leading `Icons.picture_as_pdf_rounded`, subtitle "Printable report with the current period and filters") and "CSV" (leading `Icons.table_chart_rounded`, subtitle "Spreadsheet file"). The subtitles are new helper text; labels PDF and CSV unchanged. Row tap closes the chooser and starts the export.
- Running state: `RigDialogShell` (non-dismissible) with a 24 dp indicator and "Preparing report" (`bodyMedium`) while the bytes are built; the Report toolbar icon on the ledger is disabled (UI flag) until finished; the dialog closes before `FileSaveService.saveFile` is shown. Same async order as today.
- Empty: `showRigSnack(error, 'Nothing to export')` (text unchanged); the order stays as today: the chooser opens first, then 'Nothing to export' appears if there are no rows.
- Report - All Accounts: `RigDialogShell` titled "Report - All Accounts" (title unchanged), content: `RigSection` "Period" with two `RigSegmented` options "All" and "Date range"; when "Date range" is selected a `RigDateField`-style row shows the chosen range with the user's date format (" - " separator) and a tap re-opens `pickCashDateRange`; `RigSection` "Format" with `RigSegmented` PDF, CSV; actions: Cancel (text), "Export" (filled; replaces "OK"; same `Navigator.pop(ctx, true)`).
  Behavior parity: initially range = null (All), pdf = true (PDF selected), selecting "Date range" opens the picker immediately; cancelling the picker leaves the previous selection.
- Feedback: success `showRigSnack(success, 'Report exported')` (unchanged), failure `showRigSnack(error, 'Failed to export')` with the raw exception in a "Details" action (opens a `ConfirmDialog`-style info dialog). Text 'Failed to export: $e' is kept in Details.
- Desktop: dialogs max width 400 and 440; Esc closes; Enter activates the focused row or Export.

Tokens: dialog padding `s6`, gap `s3`; radius `xl` dialog, `md` rows; type `titleMedium`, `bodyMedium`, `bodySmall`; colors `primary`, `onSurfaceVariant`, `negative` for errors.

State table:

| State | Rule |
|---|---|
| Choose | list of 2 formats |
| Building | non-dismissible dialog with indicator |
| Saved | success snackbar |
| Nothing to export | error snackbar |
| Error | error snackbar with Details |
| Disabled | Export disabled while building; Report icon on the ledger disabled while building |

Motion: dialog entrance `slow`; segmented change `fast`.

## 5. Logic touchpoints that must stay untouched

- `CashExportData` construction (title, rangeLabel, allBooks, rows, previousBalance, hasPreviousBalance, reporter, generatedAt, bookNames) in `_report` (home) and `buildAllBooksExport` (ascending, non-deleted, optional range).
- `CashbookExportService.loadFonts`, `buildPdf(data, settings, baseFont:, fallbackFonts:)`, `buildCsvBytes(data)`, `fileName(data, ext)`.
- `FileSaveService.saveFile(context:, bytes:, fileName:, shareSubject: 'RigLedger Account Ledger report', dialogTitle: 'Save report')`.
- Texts: 'Nothing to export', 'Report exported', 'Report - All Accounts', 'PDF', 'CSV'.
- Defaults of the all-accounts dialog: All, PDF.
- `context.mounted` guards after awaits.
- `pickCashDateRange` return contract (half-open range).

## 6. Acceptance criteria

1. From the ledger home: Report > PDF produces a PDF with the same rows (period, search, filters honored), same title, range and totals as before; CSV likewise (parity P-RPT in parity_g2.md).
2. Report-All with All and PDF exports every non-deleted entry of every book, oldest first; with a date range only that range.
3. A progress state is visible while the file is built; a second tap cannot start a second export.
4. Empty data shows 'Nothing to export' and creates no file.
5. File names follow the existing rule ('<Book> <date>.<ext>' / 'cashbook <date>.<ext>').
6. The dialogs fit 360 dp and 200 percent text.
7. Cancelling the range picker keeps the previous choice.
8. Errors show a friendly line with Details.

## 7. Performance notes

- PDF building (`buildPdf`) runs on the UI isolate through the service; the redesign adds a visible state only (moving to an isolate is a service change, L-12).
- The all-books dialog uses `StatefulBuilder` (rebuilds the whole content per chip tap): extract `_ReportAllDialog` as a `StatefulWidget` with two fields; no controllers exist.
- `buildAllBooksExport` runs on tap, not per frame; the `where` over all entries is O(n).


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Report dialog (all) | `cbReportDlg(0)` | lib/features/cashbook/cashbook_report_dialog.dart (`showCashReportAllDialog`) | RigSheet "Report - All Accounts": RigChipRow (All, Select Date Range), RigSegmented (PDF, CSV), pinned RigButton "OK" | Opened from the hub row Report-All Accounts. |
| Home (All) Report button | `cbReportDlg(1)` | cashbook_report_dialog.dart (`showCashReportDialog`) | RigSheet "Report": RigGroup of RigRows PDF and CSV with coloured icon tiles | Opened from the PDF button of the home bar. |

### R2. What changes in the redesign (supersedes section 4)

Report (single book): RigSheet (28 radius, grabber, title "Report", close button) with one RigGroup of two RigRows: PDF (29 dp tile `moneyOutButton`, glyph `picture_as_pdf`) and CSV (tile `moneyInButton`, glyph `table_chart`). Choosing a row closes the sheet and starts the export; RigSnack "Report exported" on success, "Nothing to export" when there are no rows (unchanged order: chooser first).

Report - All Accounts: RigSheet titled "Report - All Accounts": RigChipRow with "All" (default) and "Select Date Range" (opens the range sheet or the shared date range sheet immediately; cancelling keeps the previous choice), then a RigSegmented PDF and CSV (default PDF), pinned RigButton "OK" that starts the export. While the bytes are built the button shows a 20 dp spinner and the report button on the ledger is disabled (UI flag); a second tap cannot start a second export. Failure: RigSnack "Failed to export" with a "Details" action opening a RigAlertDialog holding the raw message.


Old section 4 items:

- Old 4 single-book RigChoiceDialog (sheet on compact, dialog on expanded): CHANGED to the RigSheet with coloured tiles; subtitle "Printable report with the current period" is DROPPED (the mockup shows no subtitle).
- Old running state dialog (non-dismissible, "Preparing report"): CHANGED to a spinner in the pinned button for the all-accounts sheet; for the single-book sheet the sheet closes and a RigSnack "Preparing report" shows (new copy).
- Old all-accounts dialog with RigSection and two RigSegmented: CHANGED to chips plus one segmented control.
- Old feedback texts: KEPT.
- Old desktop paragraph (Esc, Enter, widths): DROPPED.


States:

| State | Rule in the new look |
|---|---|
| Choose | two rows or chips and segmented |
| Building | spinner in the pinned button; ledger report button disabled |
| Saved | RigSnack "Report exported" |
| Nothing to export | RigSnack "Nothing to export" |
| Error | RigSnack "Failed to export" with Details |
| Disabled | OK disabled while building |


Motion: sheet rise 250 ms; chip change 150 ms; ink press; reduced motion removes durations.


### R3. Logic touchpoints and LR items

Untouched: `CashExportData` construction (title, rangeLabel, allBooks, rows, previousBalance, hasPreviousBalance, reporter, generatedAt, bookNames), `buildAllBooksExport`, `CashbookExportService.loadFonts`, `buildPdf`, `buildCsvBytes`, `fileName`, `FileSaveService.saveFile(...)` arguments, texts "Nothing to export", "Report exported", "Report - All Accounts", "PDF", "CSV", defaults All and PDF, `context.mounted` guards, `pickCashDateRange` return contract.


- LR-24 (approved): applies to on-screen text only; PDF and CSV content is frozen (export content must not change; Noto fonts stay for PDFs).
- LR-32 (approved, Phase 1): the second-export guard is a UI flag of the same kind.
- No new logic item.


### R4. Acceptance criteria delta

1. Report from the ledger home produces a PDF or CSV with the same rows, title, range and totals as before (parity P-RPT); the files keep "Rs." and their own date formats.
2. Report - All Accounts with All and PDF exports every non-deleted entry of every book oldest first; with a range only that range.
3. The spinner shows while the file is built and a second tap cannot start a second export.
4. Empty data shows "Nothing to export" and creates no file; cancelling the range keeps the previous choice.
5. Sheets fit 360 dp and 412 dp, light and dark, text scale 200 percent; pinned button above the inset.
6. Android back closes the sheet; it is not blocked while building (the export continues and reports through a snackbar).


### R5. Parity delta

Change on purpose:

- PARITY-069 to 072: chooser is a sheet; on-screen text only.


Must stay identical:

- PARITY-069 to 072 report contents, PARITY-073 CSV instead of xls (deviation stays), PARITY-074 file names, PARITY-079 name and address printed under the PDF title.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- The export bytes are built with the existing service; if building blocks the UI thread move it to an isolate only with a separate proposal (not part of this redesign).
- Controllers: none. The range uses plain DateTime variables in the sheet State.

