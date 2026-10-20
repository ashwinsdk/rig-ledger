> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# csv_import_screen (lib/features/export/csv_import_screen.dart, 741 lines)

Contains `CsvImportScreen` (3-step `Stepper`) and `_SummaryChip`. One doc.

## 1. Purpose and primary user task

Bring ledger bills (main ledger entries only) from a CSV file into the active rig: pick the file, map CSV columns to RigLedger fields, validate and review errors, then import. Used when migrating from a spreadsheet or restoring data from a CSV exported earlier.

## 2. Current structure

- State: `_csvData`, `_headers`, `_columnMapping` (Map expected name to column index), `_errors`, `_validEntries`, `_createMissingAgents`, `_isImporting`, `_currentStep`.
- `Scaffold` + flat primary `AppBar('Import from CSV')` + material `Stepper` with 3 steps (Select File, Map Columns, Preview & Import) and custom `controlsBuilder` (Back text button + primary button whose label changes: "Select File"/"Continue"/"Validate"/"Import"/"Importing...").
- Step 1 (`_buildFileSelectionStep`, 161): dashed-like box with icon, "File loaded successfully", row count, "Browse Files"/"Choose Different File"; expected format notes.
- Step 2 (`_buildColumnMappingStep`, 225): 16 rows (`expectedHeaders`: Date, Bill number, Agent name, Address, Depth, Depth in feet, Depth per feet rate, PVC, PVC rate, MS pipe, MS pipe rate, Extra-chargers, TOTAL, Received, Balance, Less), each a label (required ones starred: Date, Bill number, Agent name) + arrow + `DropdownButtonFormField<int>`; `SwitchListTile` "Auto-create missing agents".
- Step 3 (`_buildPreviewStep`, 323): two `_SummaryChip`s (valid, errors), error box listing the first 5 errors, preview of the first 5 valid entries.
- Reads: `agentsProvider`. Writes: `agentsProvider.notifier.addAgent(name)`, `.refresh()`, `ledgerEntriesProvider.notifier.importEntries(entries)`.
- `_autoMapColumns` (498) maps by lowercase `header == expected || header.contains(expected)`; `_validateAndParse` (520) builds `LedgerEntry` objects; `_importEntries` (629).

## 3. Problems found

Correctness (verified from the code)
1. Auto-mapping is wrong for RigLedger's own export. The exported headers are `Date, Bill Number, Agent Name, Address, Depth Type, Depth (feet), Depth Rate/ft, Step Rate, PVC Type, PVC (feet), PVC Rate/ft, MS Pipe Type, MS Pipe (feet), MS Pipe Rate/ft, Extra Charges, Total, Received, Balance, Less, Notes, Commission` (ledger_entry.dart:500-522) but the importer expects `Bill number`, `Depth`, `Depth in feet`, `Depth per feet rate`, `PVC rate`, `MS pipe rate`, `Extra-chargers` (32-49). The matcher uses `contains` and `break`s on the first expected name in list order (506-512): header "Depth Type" maps to "Depth" correctly, but "Depth (feet)" and "Depth Rate/ft" also contain "depth" and overwrite `mapping['Depth']` with the LATER column index; "Depth in feet" and "Depth per feet rate" are never mapped (they come after "Depth" in the list and the loop breaks at the first hit). Same for PVC and MS pipe; "Extra Charges" does not match "extra-chargers". Result: a file exported by this app maps Depth to the "Depth Rate/ft" column and leaves feet, rates and extra charges unmapped, so imports silently produce zero depth, rate and extra values (wrong number). The user can fix the dropdowns by hand but nothing warns that required numeric fields are unmapped.
2. The "Validate" step can be passed with required fields unmapped (141-146): every row then errors one by one; no guard or summary at step 2 ("Date, Bill number and Agent name must be mapped").
3. `_autoMapColumns()` runs every time "Continue" is pressed on step 0 (135), so going Back to step 0 and Continue again discards the user's manual mapping. State loss.
4. Missing date silently becomes now (`date = DateTime.now()`, 559-563) and an unparseable date errors; `DateTime.parse` only accepts ISO formats, so `12/10/2026` (the PDF/CSV-like format used elsewhere) fails for all rows with the single message "Invalid date format" repeated.
5. Duplicate imports: `importEntries` saves every entry with a new uuid (593; provider 139-144). Importing the same file twice doubles every bill (no duplicate detection by bill number + agent + date). Pressing Import twice quickly is also possible because the primary button stays enabled during `_isImporting` (75-78, 148, 630): `_importEntries` has no re-entrancy guard. Data duplication.
6. Fields the export contains are not imported: Step Rate, Notes, Commission, payments; `isTotalManuallyEdited: false` and `total` taken from the CSV (593-615). Round-trip is lossy. (Logic request, not a redesign item.)
7. `updatedAgents.firstWhere(...)` without `orElse` (665-667): if an agent could not be created (name casing difference handled) a `StateError` aborts mid-import after some agents were created; entries are not imported but agents were added.
8. When `_createMissingAgents` is false and the agent is missing, the row errors. When true, agent ids are assigned later; but agents are created with name only (no phone, notes, rates).
9. Import target rig is not shown. Entries are saved into whatever the active rig is; imported into a side-bore rig, PVC fields still import (the side-bore form hides PVC). UNVERIFIED how `saveLedgerEntry` assigns the vehicle id (constructor call in 593 passes none).
10. Preview shows only 5 entries and 5 errors (`take(5)`, 370, 408); no way to see all errors or download an error list. Amount shown with `toStringAsFixed(2)` (436), no currency format, no right alignment.
11. After `Navigator.pop` (678) the success snackbar is shown on the previous screen: good, but the screen closes immediately, so the user cannot review counts or undo.

Layout, accessibility, density
12. Material `Stepper` on macOS: vertical stepper stretches to the full window width (no max width), the step content for 16 mapping rows is long, and the step header "subtitle" texts are small. `Stepper` controls have 48 dp buttons but "Back" and primary share a Row without wrapping.
13. Mapping rows: label `Expanded(flex: 2)` + icon + dropdown `Expanded(flex: 3)` (247-303): at 360 dp wide and text scale 200 percent the label (e.g. "Depth per feet rate") wraps to 4 lines and the dropdown is about 120 dp wide, truncating column names. Required fields marked only by " *" text and a weight change; weak contrast cue (`textPrimary` vs `textSecondary`).
14. `-- Skip --` item uses `textHint` #94A3B8 (2.56:1) (280).
15. Error box and `_SummaryChip` use `AppColors.error` text on 10 percent tint (350-364): about 3.4:1 at 12 to 14 sp; the success chip `AppColors.success` text on its tint about 2.4:1 (fails). Chip meaning is color plus icon plus text, so not color-only, but contrast fails.
16. The Step 0 helper text shows "Expected format" but not the column names expected, which is the thing the user needs; and says "Comma-separated" while `CsvToListConverter` auto-detects delimiters.
17. No loading state while reading and parsing a big file in `_pickFile` (455-465) and in `_validateAndParse` (all rows on the UI isolate, then `setState`): the app freezes on large files with no spinner.
18. Controls: the Stepper's "Continue" label on step 0 is "Select File" when no file is loaded and then "Continue": the label changes meaning mid-flow; two buttons do the same thing (the "Browse Files" button and the primary "Select File").

## 4. Redesign

Keep the 3-step flow and the same data flow, but replace the Material `Stepper` by a `RigScaffold` page with a step header and one step visible at a time.

Page: `RigScaffold(appBar: RigAppBar(title: 'Import from CSV'), maxContentWidth: 720)`. Under the app bar a `ImportStepHeader` (new, components_g3.md): 3 numbered circles (24 dp, `labelMedium`) connected by 2 px lines, labels "Select File", "Map Columns", "Review"; completed steps show `Icons.check_rounded` in a `primary` circle, current step `primary` outline, future `outlineVariant`; each has `Semantics(label: 'Step 2 of 3, Map Columns, current')`. On compact the labels are shown only for the current step.

Rig context row (same as export screens): "Importing into: <rig name>" and, because duplicates are not detected, a standing hint "Importing the same file twice creates duplicate bills." (copy only, `info` tone).

Step 1 (Select File): `RigCard` drop zone (compact: tap target, expanded: also accepts drag and drop? NOT designed (new behavior); only the button). Content: icon `Icons.upload_file_rounded` 48 (`primary`), title "Select a CSV file to import", after load: `Icons.check_circle_rounded` `moneyIn`, "File loaded: <file name>" and "<n> rows found (excluding header)"; button `FilledButton` "Browse Files" / "Choose Different File" (only one file button exists; the bottom bar primary becomes "Continue" and is disabled until a file is loaded). Below, an "Expected columns" disclosure (`ExpansionTile`) listing the 16 expected header names in a `Wrap` of read-only chips, with a note "Required: Date, Bill number, Agent name". Loading: while picking/reading, the button shows a 20 dp spinner and "Reading file..."; errors: `ErrorBanner` ("CSV file is empty" / "Failed to read file") above the card (messages unchanged).

Step 2 (Map Columns): list of `MappingRow`s (new). Compact: each row is a stacked block: label (`bodyMedium`, required rows add a `labelSmall` "Required" `StatusPill` in `negativeContainer`/`negative`, optional rows say nothing) above a full-width `RigDropdownField<int>` with the first item "Skip" (`onSurfaceVariant`). Medium and expanded: two columns, label left (fixed 40 percent), dropdown right (60 percent), row min height 56. A summary strip on top: "12 of 16 columns mapped" and a warning `ErrorBanner` when any of the three required fields are unmapped: "Map Date, Bill number and Agent name to continue" and the primary button is disabled (UI guard; `_validateAndParse` untouched). "Auto-create missing agents" is a `SwitchListTile` card with subtitle "Create agents if they don't exist" (strings unchanged). Mapping is preserved when navigating Back and forward: do not re-run `_autoMapColumns` once the user has changed a dropdown (state-flag in the screen; logic freeze: this flag is purely UI and the auto-mapping algorithm itself is unchanged, its bug is logged in bugs_g3.md/logic_g3.md).

Step 3 (Review): top `ImportSummaryRow`: two `StatusPill`s "N Valid" (`moneyIn`) and "N Errors" (`negative` when > 0 else `onSurfaceVariant`), each with an icon (`Icons.check_circle_rounded`, `Icons.error_rounded`) and text, never color only. Errors: `ErrorBanner` listing the first 5 errors as `Row N: message` plus "and K more errors" and a "Show all" button that opens a `RigSheet` (compact) or dialog (expanded) with the full error list in a `ListView.builder` (same data, same messages). Preview: `RigCard` with the first 5 valid entries as `RigListRow`s: title "#<bill> - <agent>", subtitle "<yyyy-MM-dd> | <address>", trailing `AmountText(total, amountSmall)` right-aligned (value formatted by `RigFormat.money`, same number). Heading "Preview (first 5 entries):" unchanged.

Bottom action bar (`ExportActionBar` reused as `FlowActionBar`): Back (text, steps 2 and 3), primary on the right: "Continue" (step 1), "Validate" (step 2), "Import N entries" (step 3, `FilledButton`). When importing: label "Importing...", spinner, a modal-free `LinearProgressIndicator` on top of the bar, Back and primary disabled (this also prevents the double import). After success the page pops (unchanged) and the previous screen shows the existing success snackbar; add the count of skipped errors in the message only if the existing string is extended by the developer (do not change today's text: "Successfully imported N entries").

Width behavior: Compact: single column, sticky bottom bar, 16 dp padding. Medium: 24 dp padding. Expanded: content 720 centered, mapping rows two-column, Cmd+Enter = primary action, Esc = Back/close (on step 1 closes the screen), Tab order follows reading order.

State table
| State | Behavior |
|---|---|
| Default | current step content |
| Loading | file read spinner; "Validate" spinner; "Importing..." with bar |
| Empty | file with only a header: banner "No data rows found" (new UI copy; today `_validateAndParse` returns silently when fewer than 2 rows) |
| Error | file errors banner; required mapping banner; row errors in review; import failure banner "Import failed: ..." with Details |
| Disabled | Continue until file loaded; Validate until required fields mapped; Import when 0 valid or importing |

Motion: step content cross-fade 200 ms (`base`) with a 16 dp horizontal slide; progress bar indeterminate; reduced motion none.

Tokens: spacing s2 s3 s4 s6; radius lg, md, full; type titleMedium, bodyMedium, bodySmall, labelMedium, amountSmall; colors primary, onPrimary, primaryContainer, surface, surfaceContainer, onSurface, onSurfaceVariant, moneyIn, negative, negativeContainer, info, outlineVariant.

Components: `RigScaffold`, `RigAppBar`, `RigCard`, `RigDropdownField`, `RigListRow`, `AmountText`, `StatusPill`, `ErrorBanner`, `RigSheet`, `RigSnack`, `ImportStepHeader`, `MappingRow`, `FlowActionBar` (all new ones in components_g3.md).

## 5. Logic touchpoints that must stay untouched

- `expectedHeaders` list and order; required set `['Date', 'Bill number', 'Agent name']` (starred in the UI).
- `_autoMapColumns` algorithm (including its bug), `_validateAndParse` (error messages `Bill number is required`, `Agent name is required`, `Invalid date format`, `Agent "<name>" not found`), numeric parsing `double.tryParse(...) ?? 0`, defaults (`'7inch'` for depth and PVC when empty, `date = now` when empty), `LedgerEntry(...)` construction, `isTotalManuallyEdited: false`.
- `_importEntries`: create missing agents via `agentsProvider.notifier.addAgent(name)`, refresh, reassign `agentId`, `ledgerEntriesProvider.notifier.importEntries`.
- `FilePicker` extension filter `['csv']`; `CsvToListConverter().convert(content)`.
- Strings: "CSV file is empty", "Failed to read file: ...", "No valid entries to import", "Successfully imported N entries", "Import failed: ...".

## 6. Acceptance criteria

1. Step order and outputs are unchanged: select file, map, validate, import; the same CSV with the same mapping produces the same valid and error counts and the same saved bills as before.
2. The primary button is disabled on step 1 until a file loads, on step 2 until Date, Bill number and Agent name are mapped, and on step 3 when 0 valid entries or while importing.
3. Pressing Import cannot be triggered twice (button and Back disabled while importing; verify with rapid double-click on macOS: one set of bills created).
4. Going Back from step 2 to step 1 and forward again keeps manual mapping changes (unless a different file was chosen).
5. The review step shows N Valid and N Errors as icon plus text pills; "Show all" lists every error with its row number.
6. The rig name and the duplicate-import hint are visible on every step.
7. At text scale 200 percent mapping rows stack and nothing overflows; dropdown shows the full column name on two lines.
8. All buttons and dropdowns are 48 dp or taller on mobile; keyboard navigation reaches all controls on macOS.
9. File read and validation show a spinner and do not freeze the step header animation for files up to 5,000 rows (visual check).
10. No `Colors.*`, hex or `Stepper` remains.

## 7. Performance notes

- `_validateAndParse` and the CSV decode run on the UI isolate; wrap in `await Future<void>.delayed(Duration.zero)` after showing the spinner. Parsing off-isolate is a logic request (logic_g3.md).
- Mapping step builds 16 `DropdownButtonFormField`s; extract `MappingRow` as a `StatelessWidget` receiving the headers list reference and the selected index, so changing one dropdown rebuilds only that row via `ValueListenableBuilder` per row or by keeping `_columnMapping` in a `ValueNotifier<Map<String,int>>`.
- The review step must use `ListView.builder` (or `SliverList`) for the "Show all errors" sheet; the first-5 preview stays a `Column`.
- Hold `_csvData` once; do not copy; headers list is created once on file pick.
- All controllers: none present; dropdown values from state.

## Reconciliation 2026-10-13 (Apple look, Android only)

Two tracks. Phase 1 (approved, LR-31): the auto-mapping fix, logic only, with the existing Material screen. Later: the screen restyle in this section. Dropped: macOS and desktop items (Cmd+Enter, Esc, two-column mapping rows, expanded cap, keyboard order, rapid double click on macOS). Old text stays above.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Mockup function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Import from CSV | `SC.importCsv` + `importStep(0)` (step 1 of 3, Select File) | `lib/features/export/csv_import_screen.dart` (`CsvImportScreen`) | LargeTitleScaffold ("Import from CSV"), RigSegmented (read-only 3 step indicator "1 2 3" plus caption "Step 1 of 3: Select File"), RigCard (upload icon, "File loaded successfully", RigButton tonal "Choose Different File"), RigCard "Expected format" text, pinned RigButton filled "Continue" | the mockup shows the loaded state only |
| (steps 2 and 3, reached with the buttons) | `importStep(1)`, `importStep(2)` | same | step 2: RigGroup of mapping rows (CSV column to field), RigGroup with RigSwitch "Auto-create missing agents", pinned Back (tonal) and Validate (filled); step 3: two RigMetricCards (Valid 12 in `moneyInText`, Errors 1 in `moneyOutText`), ErrorBanner "Row 9: invalid date", pinned Back and Import | the Flutter mapping rows hold a dropdown per expected field (the mockup shows static text) |

### R2. What changes in the redesign (supersedes section 4)

Layout (360 dp and 412 dp):
1. LargeTitleScaffold "Import from CSV". Under the title a read-only RigSegmented with three numbered segments (current step filled; completed steps stay filled; it ignores taps) and a caption `Step N of 3: <name>` 13 sp `labelSecondary` (names "Select File", "Map Columns", "Preview and Import"). This replaces the Material `Stepper` and the proposed `ImportStepHeader`. Each segment carries `Semantics(label: 'Step 2 of 3, Map Columns, current')`.
2. Step 1: RigCard (centered): upload icon 44 dp `accent`, "File loaded successfully" 17 sp w600, "<n> rows found (excluding header)" 13 sp, RigButton tonal "Choose Different File" (or "Browse Files" before a file exists; a single file button exists). Second RigCard 13 sp: "Expected format:" and the 16 expected header names. Pinned RigButton "Continue", disabled until a file is loaded. While reading the file: the button shows a spinner and "Reading file...".
3. Step 2: section label "MAP CSV COLUMNS TO FIELDS", RigGroup of 16 rows (field name left; arrow; the chosen CSV column right). In Flutter each row is a RigFormRow with the existing `DropdownButtonFormField<int>` (items: "Skip" in `labelSecondary`, then the file columns). Required fields (Date, Bill number, Agent name) show a "Required" badge in `moneyOutText` on `fill`. A RigGroup with a RigRow and RigSwitch "Auto-create missing agents", subtitle "Create agents if they do not exist" (the existing string "Create agents if they don't exist" is kept verbatim). Pinned two buttons: Back (tonal) and Validate (filled), disabled while a required field is unmapped, with an ErrorBanner "Map Date, Bill number and Agent name to continue" (UI guard only). The mapping the user has edited survives Back and forward (UI flag; `_autoMapColumns` runs once per file pick).
4. Step 3: two RigMetricCards side by side: "Valid" with the count in `moneyInText` 28 sp, "Errors" with the count in `moneyOutText` (`labelSecondary` at 0); icon plus text, not colour only. ErrorBanner listing the first 5 errors as `Row N: message`, plus "and K more errors" with a "Show all" button that opens a RigSheet with every error. Preview of the first 5 valid entries as RigRows (title `#<bill> - <agent>`, subtitle `<date> | <address>`, trailing MoneyText of the total, full value, never compact). Pinned Back and "Import N entries" (filled). While importing: spinner and "Importing...", both buttons disabled.
5. Rig context: "Importing into: <rig name>" plus the hint "Importing the same file twice creates duplicate bills." as a RigCard footer text on every step (not in the mockup; UI copy only; keep because duplicates are not detected, old problem 5).
6. Success: the page pops and the previous screen shows "Successfully imported N entries" (unchanged string) in a RigSnack. Failure: ErrorBanner "Import failed: ..." with Details.

States:

| State | Behaviour |
|---|---|
| Default | current step |
| Loading | file read spinner, Validate spinner, "Importing..." |
| Empty | file with only a header: banner "No data rows found" (new UI copy; today it returns silently) |
| Error | file errors banner; required mapping banner; row errors in step 3; import failure banner |
| Disabled | Continue until a file is loaded; Validate until required fields are mapped; Import when 0 valid or importing |

Motion: step content cross fade 200 ms with a 16 dp slide; zero under reduced motion; ink press on the buttons.

Old section 4 items:

| Old item | Verdict |
|---|---|
| Material `Stepper` replaced by one visible step | KEPT (RigSegmented indicator) |
| `ImportStepHeader` with circles and lines | DROPPED (RigSegmented) |
| Rig context row and duplicate hint | KEPT (footer text) |
| Step 1 drop zone with "Expected columns" disclosure | CHANGED (two plain cards as in the mockup) |
| Step 2 MappingRow stacked at compact, Required pill, summary strip "12 of 16 columns mapped" | CHANGED (RigFormRow rows, Required badge, no summary strip) |
| Mapping preserved on Back | KEPT |
| Step 3 StatusPill count row | CHANGED (two RigMetricCards) |
| "Show all" sheet, first 5 preview | KEPT |
| FlowActionBar | CHANGED (pinned pills Back and primary) |
| Expanded two-column mapping, Cmd+Enter, Esc | DROPPED |

### R3. Logic touchpoints and LR items

Superseded: section 5 says `_autoMapColumns` stays untouched "including its bug". LR-31 (approved 2026-10-13, Phase 1, one commit) replaces that: map the app's own export headers (exact match first, aliases for "Bill Number", "Agent Name", "Depth Type", "Depth (feet)", "Depth Rate/ft", "PVC Type", "PVC (feet)", "PVC Rate/ft", "MS Pipe Type", "MS Pipe (feet)", "MS Pipe Rate/ft", "Extra Charges", "Total", then `contains`), and import depth feet, rates and extra charges (and step rate, notes, commission per LR-31) instead of zeros. This changes data written by import and has its own test (round trip of `Model.csvHeaders`).
Still untouched: `expectedHeaders` list and order, required set, error messages (`Bill number is required`, `Agent name is required`, `Invalid date format`, `Agent "<name>" not found`), numeric parsing `double.tryParse(...) ?? 0`, defaults (`'7inch'`, date now when empty), `LedgerEntry(...)` construction, `_importEntries`, `FilePicker` filter `['csv']`, `CsvToListConverter`, strings "CSV file is empty", "Failed to read file: ...", "No valid entries to import", "Successfully imported N entries", "Import failed: ...".

| Id | Dependency | Status |
|---|---|---|
| LR-31 | mapping fix, Phase 1; screen restyle is later and independent | approved |
| LR-32 | Import cannot start twice (`_isImporting` guard, buttons disabled) | approved (Phase 1) |
| L3 L-02 / L-03 / L-04 / L-05 | duplicate detection, date formats, more fields, `firstWhere` without `orElse` | not scheduled (L-04 partly covered by LR-31 scope) |
| none new | the "No data rows found" banner is UI copy over today's silent return | no logic |

### R4. Acceptance criteria delta

1. Phase 1 test: export the Ledger CSV from this app and import it: Depth, Depth in feet, rates and extra charges are mapped automatically and the imported totals equal the exported ones (LR-31).
2. The step indicator is read-only, shows the current step, and its caption reads `Step N of 3: <name>`.
3. Continue is disabled until a file loads; Validate until Date, Bill number and Agent name are mapped; Import when 0 valid or while importing.
4. Import cannot run twice (buttons disabled, one set of bills created).
5. Going Back to step 1 and forward keeps manual mapping changes unless a different file was chosen.
6. Step 3 shows Valid and Errors with icon and text; "Show all" lists every error with its row number.
7. The rig name and the duplicate hint are visible on every step.
8. At text scale 130 and 200 percent mapping rows wrap (label above value when needed) and nothing overflows; with the keyboard not involved, the pinned buttons stay visible above the inset.
9. Light and dark: error and valid text at least 4.5:1; all buttons and dropdown rows 48 dp or more.
10. Android back goes to the previous step on steps 2 and 3 and closes the screen on step 1 (a dirty guard is not used; no typed data).

### R5. Parity delta

Changes on purpose: line 47 (auto mapping of the app's own export now maps correctly, LR-31; baseline recorded the mismatch); line 50 (depth, rates and extra charges from the app's own CSV now import instead of zero); line 51 (double Import creates one set of bills). Must stay identical: line 46 messages, line 48 counts and messages for the same file and mapping, line 49, line 50 totals equal CSV TOTAL values and defaults `'7inch'`, success message "Successfully imported N entries".

### R6. Performance and Android notes

- Insets: edge to edge; pinned buttons at `viewPaddingOf(context).bottom + 12`; the mapping list scrolls under them with matching bottom padding.
- Back: PopScope maps back to the previous step; system back on step 1 pops.
- Parsing and validation stay on the UI isolate; paint the spinner first (`await Future<void>.delayed(Duration.zero)`); for up to 5,000 rows verify there is no visible freeze.
- Keep `_csvData` once; headers built once per file; `MappingRow` rows are stateless widgets over a `ValueNotifier<Map<String,int>>` so one dropdown change rebuilds one row; the full error list uses `ListView.builder` inside the RigSheet.
- No controllers exist; dropdown values live in State.
- No BackdropFilter; budgets p90 build and raster under 8 ms, p99 under 16 ms.
