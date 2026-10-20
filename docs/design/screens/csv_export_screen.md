> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# csv_export_screen (lib/features/export/csv_export_screen.dart, 531 lines)

Contains `ExportType` enum (15), `CsvExportScreen` and its State. One doc.

## 1. Purpose and primary user task

Export ledger or side-ledger records of the active rig as a CSV file (for spreadsheets or backup in a readable form): choose type (Ledger, Diesel, PVC, Bit, Hammer), choose all entries or a date range, check the columns and entry count, and export.

## 2. Current structure

- `_CsvExportScreenState` fields: `_startDate` (now minus 30 days), `_endDate`, `_exportAll = true`, `_isExporting`, `_exportType`.
- `build` (41) computes `_getEntriesCount()` (Hive query, 355) and `_getHeaders()` (390) every build; `Scaffold` with `AppBar(primary, white)`; `ListView(padding 16)` of three shadow `Container` cards: Export Type (`Wrap` of `GestureDetector` pills, PVC hidden for side bore via `ref.watch(isSideBoreProvider)` inside the `where`, line 86), Date Range (`SwitchListTile` "Export all entries" + two `InkWell` date boxes when off), "Preview" card (entry count pill + "Columns to export:" list of header chips); a 50 dp `ElevatedButton.icon` "Export <Type> CSV".
- Reads: `isSideBoreProvider`; `DatabaseService.currentVehicleId`, `getAllLedgerEntries`, `getLedgerEntriesByDateRange`, `get{Diesel,Pvc,Bit,Hammer}EntriesByVehicle` and `...ByDateRange`.
- `_exportCsv` (423): builds rows `[Model.csvHeaders, ...entries.map(toCsvRow)]`, `ListToCsvConverter().convert`, file name `rigledger_<type>_export_all_<yyyyMMdd>.csv` or `..._export_<start>_to_<end>.csv`, saves via `FileSaveService.saveStringFile`.

## 3. Problems found

1. Active rig is not shown (same as PDF screen); main ledger "all" export uses `getAllLedgerEntries()` (469 in DB: current rig scope presumably) so the user cannot confirm what "all" means. Display only: name of rig and the number of entries.
2. Card titled "Preview" (269) shows only column header chips, not rows: the title promises a data preview. Misleading; it should be "Columns". Header chips are 11 sp `textSecondary` in a bordered box (311-322), under the 11 sp readability recommendation boundary (it is exactly 11) and the Ledger CSV has 21 columns, two of which (Notes, Commission) are not in the PDF.
3. Defaults differ from PDF: CSV defaults to Export all, PDF to last 30 days (36 vs pdf 53). A user switching between the two gets surprise scopes. Display a one-line scope sentence at the top of the summary ("All 128 entries" / "12 Sep 2026 to 12 Oct 2026") so the scope is always explicit.
4. No date validation (From after To) (405-421); picker bounds 2000 to 2100.
5. `SwitchListTile` title "Export all entries" subtitle "Export entire dataset" (164-165): "entire dataset" is wrong for Diesel/PVC (it is entries of the active rig only) and for Ledger it might include other rigs. UNVERIFIED which; copy should reflect the count shown.
6. Export type pills 36 dp tall `GestureDetector`s with no semantics or focus (90-122); selection color only; same defect as PDF screen. `ref.watch(isSideBoreProvider)` is called in the `.where` of every build for every enum value (5 watches per build) - harmless but unclear.
7. Feedback: spinner in the button only (335-347); success "CSV exported successfully" with white on #10B981 2.54:1 (506-512); error shows `$e` raw (517).
8. Zero entries: the button is disabled (334) but nothing says why (no message, unlike the PDF screen's amber box). The user sees a greyed button and a "0 entries" pill only.
9. Visual duplication: the type pills, date boxes and summary pill are copied from pdf_export_screen.dart with small differences (24 vs 20 radii not; both 20). `ExportType` vs `PdfExportType` are two identical enums.
10. Currency/date: `DateFormat('dd MMM yyyy')` created in `build` (42); entry count computed on every build (43), headers (44).
11. Contrast: the pill count text `primary` on `accentLight` 30 percent over white: about 5.5:1, OK. Border colors `AppColors.border` 1.23:1 for the date boxes (input border 3:1 needed for UI components).
12. No hint about what CSV contains (encoding, delimiter) or where it is saved.

## 4. Redesign

Share the structure with pdf_export_screen.md so both feel identical. Screen = `RigScaffold(appBar: RigAppBar(title: 'Export to CSV'), maxContentWidth: 720)`.

Cards (single column):
1. Rig context row (same as PDF screen): "Rig: <name>".
2. "Export Type": `RigChipRow` ChoiceChips (Ledger, Diesel, PVC, Bit, Hammer; PVC hidden for side bore), 48 dp hit, check icon on selected.
3. "Date Range": `RigSegmented` with two segments "All entries" and "Date range" bound to `_exportAll` (replaces the Switch; same boolean; default "All entries"). When "Date range": `PeriodPresetRow` and two `RigDateField`s with the same validation as the PDF screen (inline error and disabled Export when From is after To).
4. "Columns" (title renamed from "Preview"): `StatusPill` "N entries" on the right; scope sentence below the title ("All entries" or "12 Sep 2026 to 12 Oct 2026"); header names as non-interactive `Chip`s in a `Wrap` (`bodySmall` 12 sp, `surfaceContainer` fill, `onSurface` text, radius `xs`/`sm`); caption `bodySmall` `onSurfaceVariant`: "Columns are fixed. CSV is UTF-8 with comma separators." (copy only, valid per `ListToCsvConverter`; verify the encoding statement with `FileSaveService.saveStringFile` before shipping copy: UNVERIFIED, leave the second sentence out if unsure).
5. Action bar: `ExportActionBar` (sticky on compact) with `FilledButton.icon` "Export <Type> CSV" (`Icons.file_download_rounded`). Disabled with an inline explanation under the cards when there are zero entries: `EmptyState`-lite "No <type> entries to export" (UI only).

Success: `RigSnack(success)` "CSV exported successfully". Failure: `ErrorBanner` with Retry and a Details expander for `$e`.

Width: compact sticky bar, 16 dp padding; medium 24 dp, cap 600; expanded cap 720 centered, hover on chips, `Cmd+Enter` exports, Esc goes back.

State table
| State | Behavior |
|---|---|
| Default | all cards, Export enabled when entries > 0 |
| Loading | button spinner and text "Exporting..." plus a 2 px linear bar; controls disabled |
| Empty | explanation block, button disabled |
| Error | invalid date order inline; export failure banner |
| Disabled | Export when 0 entries, invalid range, or exporting |

Motion: chips and segmented 150 ms; column card count cross-fade 150 ms.

Tokens: same as the PDF screen (spacing s2 s3 s4 s6; radius md, lg, sm; type titleMedium, bodyMedium, bodySmall, labelLarge; colors primary, primaryContainer, surface, surfaceContainer, onSurface, onSurfaceVariant, negative, negativeContainer).

Components: `RigScaffold`, `RigAppBar`, `RigCard`, `RigChipRow`, `RigSegmented`, `RigDateField`, `StatusPill`, `EmptyState`, `ErrorBanner`, `RigSnack`, `PeriodPresetRow`, `ExportActionBar`.

## 5. Logic touchpoints that must stay untouched

- `ExportType` values and labels; `Model.csvHeaders` and `toCsvRow()` for all five models (content frozen); `ListToCsvConverter().convert(rows)`.
- Queries: `getAllLedgerEntries`, `getLedgerEntriesByDateRange`, `getXEntriesByVehicle(vehicleId)`, `getXEntriesByDateRange(vehicleId, start, end)`; `DatabaseService.currentVehicleId`.
- File names (`rigledger_<type>_export_all_<yyyyMMdd>.csv`, `rigledger_<type>_export_<start>_to_<end>.csv`), `FileSaveService.saveStringFile(shareSubject: 'RigLedger <type> CSV Export', dialogTitle: 'Save CSV Export')`.
- `isSideBoreProvider` hides PVC.
- Defaults: `_exportAll = true`, range now-30d to now.

## 6. Acceptance criteria

1. The screen shows the active rig name and the entry count for the chosen scope; the count equals the number of data rows in the exported file.
2. Choosing "All entries" exports exactly what it exported before (same rows, headers, file name); choosing "Date range" with a valid range exports the same rows as before for that range.
3. From after To disables Export and shows the inline error.
4. With zero entries Export is disabled and the explanation is visible.
5. PVC chip is absent for a side-bore rig.
6. While exporting the button shows a spinner and "Exporting..." and cannot be activated twice.
7. Type chips, segmented control, date fields and button meet 48 dp on mobile and are keyboard operable on macOS.
8. At text scale 200 percent header chips wrap and nothing overflows.
9. No `Colors.*`, hex, or `BoxShadow` remains.
10. Success and error feedback appear as specified; raw exception text is only inside Details.

## 7. Performance notes

- Compute `entriesCount` once when type, scope or dates change (store in State), not in `build`; `_getHeaders()` returns a static list, call it once per type change.
- Replace `ref.watch(isSideBoreProvider)` inside the `where` by one `final isSideBore = ref.watch(isSideBoreProvider);` at the top of `build`, or use `ref.watch(isSideBoreProvider)` through a `Consumer` around the chip row so only the chip row rebuilds.
- Column header chips are static per type: extract `_HeaderChips(type)` as a `const`-friendly widget keyed by type.
- `DateFormat` instances become `static final`.
- Large exports: `ListToCsvConverter().convert` and entries mapping run on the UI isolate; offloading to `compute` is a logic change (logic_g3.md), so only show progress first (`await Future<void>.delayed(Duration.zero)` before the work).

## Reconciliation 2026-10-13 (Apple look, Android only)

Scope: the screen only. CSV CONTENT is frozen: `Model.csvHeaders`, `toCsvRow()` for the five models, `ListToCsvConverter`, file names, queries. The CSV keeps its own formats (no rupee sign, its own date text). Dropped: macOS and desktop items (Cmd+Enter, Esc, hover, expanded and medium widths). Old text stays above.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Mockup function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Export to CSV | `SC.exportCsv` | `lib/features/export/csv_export_screen.dart` (`CsvExportScreen`) | LargeTitleScaffold ("Export to CSV"), RigChipRow (type), RigGroup with a RigRow and RigSwitch ("Export all entries"), RigGroup/RigFormRows From and To when the switch is off, RigCard "Columns to export" (static header list), pinned RigButton filled "Export <Type> CSV" | PVC chip hidden for Side Bore (`isSideBoreProvider`) |

### R2. What changes in the redesign (supersedes section 4)

Layout (360 dp and 412 dp):
1. LargeTitleScaffold "Export to CSV" (34 collapsing to 17).
2. "EXPORT TYPE" label then RigChipRow: Ledger, Diesel, PVC, Bit, Hammer; selected = inverse chip; 48 dp boxes, 32 dp pills; PVC hidden for Side Bore.
3. "DATE RANGE": RigGroup with one RigRow "Export all entries", subtitle "Export the entire dataset" (mockup text, see conflicts for its accuracy), trailing RigSwitch (on by default, `_exportAll = true`). The old RigSegmented "All entries / Date range" is DROPPED: the mockup keeps the switch. When the switch is off a second RigGroup appears with From and To RigFormRows in the export format `dd MMM yyyy` (default now minus 30 days to now), the same inline error and disabled pill when From is after To (UI only).
4. "PREVIEW" label (the mockup keeps the word) over a RigCard 13 sp `labelSecondary`, line height 1.5: "Columns to export:" followed by the header names. Flutter prints the real `Model.csvHeaders` of the chosen type (Ledger has 21: Date, Bill Number, Agent Name, Address, Depth Type, Depth (feet), Depth Rate/ft, Step Rate, PVC Type, PVC (feet), PVC Rate/ft, MS Pipe Type, MS Pipe (feet), MS Pipe Rate/ft, Extra Charges, Total, Received, Balance, Less, Notes, Commission). The mockup's list is illustrative and shorter (it uses the old import header names); do not copy it. Also show "N entries" for the scope on this card (display only) and a scope sentence ("All entries" or "12 Sep 2026 to 12 Oct 2026").
5. Pinned bar (inset + 12): RigButton filled "Export <Type> CSV" (50 dp pill). While exporting: spinner and "Exporting...", disabled.
6. Zero entries: pill disabled and the card shows "No <type> entries to export" (UI only).
7. Success RigSnack "CSV exported successfully"; failure ErrorBanner with Retry and the raw text only in Details.
8. Rig context ("Rig: <name>", old item 1): not in the mockup; shown only as a 13 sp footer under the type chips if the developer confirms (open).

Roles: `inverseChip`, `onInverseChip`, `accentButton`, `fill`, `labelSecondary`, `moneyOutText`, RigSwitch track `moneyIn`. Spacing 20/12, radius 20, pills full.

States:

| State | Behaviour |
|---|---|
| Default | all sections, pill enabled when entries are above 0 |
| Loading | pill spinner and "Exporting...", controls inert |
| Empty | explanation line, pill disabled |
| Error | invalid date order inline; export failure banner |
| Disabled | pill when zero entries, invalid range or exporting |

Motion: chip and switch 150 to 200 ms; zero under reduced motion.

Old section 4 items:

| Old item | Verdict |
|---|---|
| RigScaffold, maxContentWidth 720 | CHANGED (LargeTitleScaffold) |
| Rig context row | CHANGED (optional footer) |
| ChoiceChips with check | CHANGED (inverse selected chip) |
| RigSegmented All entries or Date range | DROPPED (switch row kept) |
| PeriodPresetRow, StatusPill | DROPPED (not in the mockup) |
| "Columns" title instead of "Preview" | DROPPED for now (the mockup says "Preview"); the word is a copy question (conflicts_r4.md) |
| Non-interactive header chips | CHANGED (plain text list in a RigCard, as in the mockup) |
| ExportActionBar, EmptyState-lite, ErrorBanner with Retry and Details | KEPT in the new component names (pinned pill, EmptyState, ErrorBanner) |
| Expanded cap, Cmd+Enter, Esc, hover | DROPPED |

### R3. Logic touchpoints and LR items

Untouched: `ExportType` values and labels, `Model.csvHeaders` and `toCsvRow()`, `ListToCsvConverter().convert(rows)`, queries (`getAllLedgerEntries`, `getLedgerEntriesByDateRange`, `get{Diesel,Pvc,Bit,Hammer}EntriesByVehicle` and `...ByDateRange`), `DatabaseService.currentVehicleId`, file names, `FileSaveService.saveStringFile(shareSubject: 'RigLedger <type> CSV Export', dialogTitle: 'Save CSV Export')`, `isSideBoreProvider`, defaults `_exportAll = true` and now minus 30 days.

| Id | Dependency | Status |
|---|---|---|
| LR-32 | export cannot start twice | approved (UI guard) |
| LR-31 | the app's own export must re-import: this export format is the input of the mapping fix | approved (Phase 1, import side only) |
| L3 L-09 | CSV generation off the UI isolate | not scheduled |
| L3 L-18 | reversed date range | inline UI error only |
| none new | scope wording "entire dataset" vs the active rig (UNVERIFIED whether `getAllLedgerEntries` is current-rig scoped) | open question |

### R4. Acceptance criteria delta

1. The screen follows the mockup order at 360 dp and 412 dp, light and dark; the pinned pill never covers the last card.
2. "Export all entries" is on by default; turning it off shows From and To; turning it on again hides them.
3. The Columns card lists exactly `Model.csvHeaders` of the chosen type, and the entry count equals the number of data rows in the exported file.
4. From after To disables the pill and shows the inline error.
5. With zero entries the pill is disabled and a reason is visible.
6. PVC chip absent for a Side Bore rig.
7. The pill shows a spinner and "Exporting..." and cannot be activated twice.
8. Chips, switch row, date rows and pill are 48 dp or more; the RigSwitch has a 48 dp target.
9. At text scale 130 and 200 percent the header text wraps and nothing overflows.
10. No rupee sign or compact amounts appear (this screen has no amounts).

### R5. Parity delta

Changes on purpose: line 41 (header list is plain text in a card, not chips; the switch row is unchanged), line 44 (a visible reason when disabled). Must stay identical: line 41 defaults, entry count equals rows, header list equals the CSV header row (21 columns for Ledger), line 42 file names, line 43 active rig only and PVC hidden for Side Bore, line 45 file content identical.

### R6. Performance and Android notes

- Insets: edge to edge; pinned pill at `viewPaddingOf(context).bottom + 12`; list padding adds the bar height.
- Back: pops the screen; nothing to discard.
- Compute `entriesCount` when type, scope or dates change, not in `build`; headers are static per type; one `Consumer` around the chip row for `isSideBoreProvider`; `DateFormat` as `static final`.
- Paint progress before work (`await Future<void>.delayed(Duration.zero)`); conversion stays on the UI isolate.
- No BackdropFilter; budgets p90 build and raster under 8 ms, p99 under 16 ms.
