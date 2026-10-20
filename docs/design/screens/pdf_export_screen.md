> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# pdf_export_screen (lib/features/export/pdf_export_screen.dart, 1595 lines)

Scope: ONLY the configuration screen (lines 1-900 and `_exportPdf`, 1552-1594). The PDF CONTENT generators `_generatePdf`, `_generateDieselPdf`, `_generatePvcPdf`, `_generateBitPdf`, `_generateHammerPdf`, `_generateSideLedgerPdf` (lines 896-1550, about 650 lines) are FROZEN: layout, columns, fonts, `PdfColors`, row counts (22 per page), file names and the "Rs." text must not change. Also in this file: `PdfExportType` enum (line 15-29) and `PdfColumn` (31).

## 1. Purpose and primary user task

Choose what to export (Ledger, Diesel, PVC, Bit, Hammer for the active rig), a date range, and for Ledger the columns; check a short summary; preview the PDF; then export (share/save). Typical use: month-end report for an agent or the accountant.

## 2. Current structure

- `PdfExportScreen` (ConsumerStatefulWidget) with `_PdfExportScreenState`: fields `_startDate` (now minus 30 days), `_endDate` (now), `_isGenerating`, `_isPreviewMode`, `_exportType`, `_selectedColumnIds` (Set, all columns by default), formatters `_currencyFormat`, `_feetFormat`, `_dateFormat`.
- `build` (205) computes `_getEntriesCount()` (a Hive range query by type, 179-202), then `Scaffold` with `AppBar(backgroundColor: primary, white)` whose actions toggle preview (`Icons.preview` / `Icons.close`), body = `_buildPdfPreview()` (printing `PdfPreview`, maxPageWidth 700) or `_buildOptions`.
- `_buildOptions` (241): `ListView(padding 16)`: export type card (`Wrap` of `GestureDetector` pills, 325-391; PVC hidden for side bore), date range card (two `InkWell` date boxes, 393-493), column card (`FilterChip`s plus All/None text buttons, only for Ledger, 495-572), summary card (`_buildSummaryCard` to ledger/diesel/pvc/bit/hammer summary, 574-837), a 50 dp "Export PDF" `ElevatedButton.icon` with an in-button spinner and "Generating...", a 50 dp "Preview" `OutlinedButton`, and an amber info box when there are zero entries.
- Reads: `DatabaseService.currentVehicleId`, `getCurrentVehicle()`, `getLedgerEntriesByDateRange`, `getDieselEntriesByDateRange` (and pvc, bit, hammer) directly (no providers, so the screen does not react to data changes while open).
- Writes: none except `FileSaveService.saveFile(context, bytes, fileName, shareSubject, dialogTitle)` in `_exportPdf`.

## 3. Problems found

Hierarchy and feedback
1. Which rig is being exported is not shown anywhere on the options screen (only inside the generated PDF header). On a two-rig account the user can export the wrong rig without noticing. The info is available: `DatabaseService.getCurrentVehicle()?.name`.
2. Two ways to preview (app bar icon 215-224 and the outlined button 284-297) and the app bar icon is hidden when entries are 0; both are redundant. The preview mode replaces the whole body and has no on-screen Export/Share button except what `PdfPreview` renders (its own action bar with default Material colors, unstyled by the theme).
3. Date range: from/to boxes (419-489) allow From after To with no validation or message; the result is "No entries found" (299-320) which hides the real cause. `firstDate: 2000, lastDate: 2100` (874-875) lets the user pick absurd years. Date format `dd MMM yyyy` (242) while the file name uses `yyyyMMdd` (889): fine, but CSV defaults differ (CSV defaults to "all", PDF to last 30 days): two screens that look alike have different defaults without explanation.
4. No quick range chips (This month, Last month, Year) although the app has them everywhere else (Portfolio, Ledger).
5. Column card: "None" is allowed (537) and the Export button still enables because only `entriesCount == 0` disables it (269). Exporting zero columns is undefined: `_selectedColumns` is empty (176) and the table builder in the frozen generator receives no columns. UNVERIFIED outcome (could produce an empty table or a divide-by-zero in the flex layout). Needs a disabled state and a message.
6. "All" resets to all columns including PVC columns on a side-bore rig (528-529), but `_visibleColumns` hides them at display, so the visible chips and the set diverge harmlessly. 18 chips in a `Wrap` is a long block; no grouping (Identity, Depth, PVC, MS pipe, Money) and no indication that Date, Bill# are expected.
7. Summary card: totals use `'Rs. ${_currencyFormat.format(...)}'` with western grouping (675-681) while Ledger/Portfolio use rupee sign and Indian grouping; summary rows are 14 sp `textSecondary` label and w500 value, not right-aligned in a table; "Commission (not in total)" label is long and wraps at 200 percent: `Row(spaceBetween)` without `Flexible` (856-866) will overflow with long labels plus values (e.g. 'Commission (not in total)' 'Rs. 12,34,567.00' at 200 percent). Real overflow.
8. The summary only tallies 7" and 8" depth/PVC (612-622): other depth strings are dropped from the on-screen feet totals. This mirrors the PDF's own summary logic (frozen), so the screen shows the same numbers as the PDF; do not "fix" in the redesign (logic_g3.md note).
9. Large amounts: `Text(value)` not `FittedBox`; no `AmountText`.
10. No progress detail: the button shows "Generating..." with a 20 dp spinner (270-281). The PDF generation runs on the UI isolate (`pw.Document.save()`), so the spinner can freeze for large ranges. Cancel is not possible.
11. After export the user only gets a generic success snack (1570-1577); no file name, no where it was saved (desktop shows a save dialog, mobile shares), no "Open"/"Share again".
12. Error: `Failed to export: $e` raw exception text (1581).

Accessibility, density
13. Export type pills are `GestureDetector` + `Container` (358-385): height about 36 dp (8 + 20 + 8) below 48 dp, no `Semantics(selected)`, no focus ring on macOS, no keyboard activation; selection is color only (fill primary vs background; text white vs #64748B 4.76:1).
14. Date boxes are `InkWell` over a column with no minimum height: tap area about 70 dp wide x 44 dp (label 12 sp + box 12 padding + 16 icon): close to 48 but the InkWell has no border radius so the ripple is a rectangle outside the rounded box.
15. Warning box (299-320) uses amber on a 10 percent amber tint: `AppColors.warning` #F59E0B text = 2.0:1. Info text unreadable.
16. Cards use shadow `BoxShadow` (331-338) repeated 5 times in this file.
17. App bar is built per screen with `backgroundColor: AppColors.primary` (212) different from the gradient app bars elsewhere; export screens (3) use flat primary, About/Vehicle use gradient.

Performance and correctness
18. `build` calls `_getEntriesCount()` (Hive range scan) on every `setState`, and `_buildSummaryCard` re-runs the same range query and a full aggregation loop again (591-625, 709-782): 2 to 3 range scans per rebuild, rebuilt on every chip tap, date pick and column toggle (each of the 18 chips calls `setState`). With thousands of bills this is visible jank.
19. `_buildPdfPreview` passes a new closure `build: (format) => _generatePdfForType()` each rebuild; `PdfPreview` re-generates the PDF when the `build` callback identity changes, so any parent `setState` while previewing regenerates the document. UNVERIFIED (printing 5.x compares `widget.build != oldWidget.build` in `didUpdateWidget`).
20. `NumberFormat`/`DateFormat` instances are created in the State (good) but `DateFormat('dd MMM yyyy')` is created inside `_buildOptions` every build (242).

## 4. Redesign

Screen = `RigScaffold(appBar: RigAppBar(title: 'Export to PDF'), maxContentWidth: 720, scrollable: true)`. Preview becomes a pushed full-screen route `PdfPreviewPage` (same `PdfPreview` widget and props, `maxPageWidth 700`) with its own `RigAppBar(title: 'Preview', actions: [Export])` so there is one clear "Export PDF" in both places; the in-screen preview toggle (`_isPreviewMode`) is replaced by `Navigator.push` of that page (navigation outcome unchanged: user sees the same preview and can share/print). The standalone Preview button stays as a tonal button; the app-bar preview icon is removed.

Order of cards (top to bottom; single column on all widths, 720 cap):
1. Rig context row (`RigCard`, tone `surfaceContainer`): icon `Icons.directions_car_rounded`, text "Rig: <vehicle name>" (`labelLarge`, `RigCard` tone surfaceContainer). Read-only. (UI only; value from `DatabaseService.getCurrentVehicle()?.name`.)
2. "Export Type": `RigChipRow` of `ChoiceChip`s (Ledger, Diesel, PVC, Bit, Hammer; PVC hidden for side bore as today), 48 dp hit, selected = `primaryContainer` fill + `primary` label + check icon, so selection is not color only; scrollable with edge fade at compact, wrapped at expanded.
3. "Date Range": a `RigChipRow` of presets (This month, Last month, Last 30 days, This year) that only set `_startDate`/`_endDate` in the screen (UI helpers, no provider) followed by two `RigDateField`s "From" and "To" (56 dp, calendar icon `Icons.calendar_today_rounded`, text `dd MMM yyyy`). On compact they sit in one row of two when width allows (>= 360), otherwise stacked. Validation: when From is after To, both fields show an inline error "From date must be on or before To date" and the Export/Preview buttons are disabled. Default range stays the last 30 days (as today). The picker bounds stay 2000 to 2100 as today (changing them is a developer decision, not part of this redesign).
4. "Columns to Export" (Ledger only): header row with `labelLarge` title, count "14 of 18 selected" (`bodySmall`), and `TextButton`s All / None. Chips grouped under `RigSection`-style sub labels inside the card: Identity (Date, Bill#, Agent, Address), Depth (Depth, Depth ft, Depth Rate, Step Rate), PVC (hidden on side bore), MS pipe, Money (Extra, Total, Received, Balance, Less, Commission). Group labels are visual only; the `PdfColumn` ids, labels and order list stay as defined. `FilterChip` 48 dp hit; when none selected an `ErrorBanner` "Select at least one column" shows and Export/Preview are disabled.
5. "Summary": `RigCard` with a header row (title, `StatusPill` "N entries") and a `MoneyLabelValueRow` list: label left (`bodyMedium`, `onSurfaceVariant`, wraps), value right (`amountSmall`, tabular, right-aligned, `Flexible`), Total neutral, Received `moneyIn`, Balance `outstanding`, Commission `commission` (label text kept: "Commission (not in total)"). Currency text keeps the existing `'Rs. ' + _currencyFormat` strings so the on-screen summary matches the PDF; only styling changes. Feet totals subsection title `titleSmall`, rows `plain` with unit text.
6. Primary action bar: a sticky bottom bar (`SafeArea`) on compact with `FilledButton.icon` "Export PDF" (`Icons.picture_as_pdf_rounded`, 48 dp, full width) and a `OutlinedButton` "Preview" beside or above; on expanded the two buttons sit right-aligned at the end of the content column. When generating, the button shows a 20 dp spinner and "Generating..." and the other button is disabled; a `LinearProgressIndicator` (indeterminate, 2 px) spans the top of the bar.
7. Empty/zero: `EmptyState`-lite inside the Summary card instead of the amber box: icon `Icons.inbox_rounded` 48, text "No <type> entries found in the selected date range." (same string) and hint "Try a wider date range" (new copy). Buttons disabled.

Success feedback: `RigSnack(success)` "PDF exported successfully" with an action "Open" only if `FileSaveService.saveFile` ever returns a path (it returns bool; so no action). Error feedback: `ErrorBanner` above the action bar with "Failed to export" + a "Details" expander holding `$e`, and Retry.

Width behavior: Compact: sticky bar, 16 dp padding. Medium: 24 dp padding, content 600 wide, bar inline at the end. Expanded (macOS): content max 720 centered; hover on chips and rows; `Cmd+Enter` triggers Export (shortcut shown in the button tooltip), Esc pops the screen; Tab order: rig chip (skipped, not focusable), type chips, preset chips, From, To, column chips (roving), All, None, Preview, Export.

State table
| State | Behavior |
|---|---|
| Default | all cards, Export enabled |
| Loading | button spinner + linear bar; options remain visible but disabled |
| Empty | summary empty block, buttons disabled |
| Error | date-order inline errors; zero columns banner; export failure banner |
| Disabled | Export and Preview when zero entries, zero columns (Ledger), invalid range, or generating |

Motion: chip selection 150 ms; summary card content cross-fade 150 ms when the type changes (`AnimatedSwitcher`, reduced motion off); preview route 300 ms.

Tokens: spacing s2 s3 s4 s6; radius md (inputs, buttons), lg (cards), full (pills); type titleMedium, titleSmall, bodyMedium, bodySmall, labelLarge, amountSmall; colors primary, primaryContainer, surface, surfaceContainer, onSurface, onSurfaceVariant, moneyIn, outstanding, commission, negative, negativeContainer, outlineVariant.

Components: `RigScaffold`, `RigAppBar`, `RigCard`, `RigSection`, `RigChipRow`, `RigDateField`, `MoneyLabelValueRow`, `StatusPill`, `EmptyState`, `ErrorBanner`, `RigSnack`, `PeriodPresetRow` (new, components_g3.md, shared with csv_export_screen), `ExportActionBar` (new, shared with csv_export_screen).

## 5. Logic touchpoints that must stay untouched

- Entire PDF generation: `_newPdfDocument`, `_generatePdf`, `_generateDieselPdf`, `_generatePvcPdf`, `_generateBitPdf`, `_generateHammerPdf`, `_generateSideLedgerPdf`, `_generatePdfForType`, `rowsPerPage = 22`, A4 landscape, bundled Noto fonts via `CashbookExportService.loadFonts()`, `PdfColors`, "Rs." strings, summary computations (7inch/8inch buckets), column `getValue` lambdas and `flex`, `_getPdfFileName()` (`rigledger_<type>_<yyyyMMdd>_to_<yyyyMMdd>.pdf`).
- `PdfColumn` ids, labels, order, `_pvcColumnIds` filter for side bore, `_isSideBore` (via `DatabaseService.getCurrentVehicle()?.vehicleType == VehicleType.sideBore`).
- Data queries: `DatabaseService.getLedgerEntriesByDateRange`, `get{Diesel,Pvc,Bit,Hammer}EntriesByDateRange(vehicleId, start, end)`.
- `FileSaveService.saveFile(... shareSubject: 'RigLedger <type> Report', dialogTitle: 'Save PDF Report')`.
- Default selected columns = all; default range = now minus 30 days to now.
- `PdfPreview` props (`allowPrinting`, `allowSharing`, `canChangePageFormat: false`, `canChangeOrientation: false`, `canDebug: false`, `pdfFileName`).

## 6. Acceptance criteria

1. The options screen shows the active rig name; switching rig in Settings and returning updates it.
2. With defaults (Ledger, last 30 days, all columns) the exported PDF is byte-for-byte equivalent in structure to the pre-redesign export for the same data (same pages, columns, summary values, file name). Compare page count and the text of page 1.
3. Selecting Diesel/PVC/Bit/Hammer changes the summary card and the PDF content exactly as before; PVC type is absent on a side-bore rig.
4. Setting From after To disables Export and Preview and shows the inline error; fixing it re-enables both.
5. Clicking None in the column card disables Export and Preview and shows "Select at least one column"; All restores them.
6. With zero entries in range both buttons are disabled and the empty message with the type name shows.
7. During generation the Export button shows the spinner and text "Generating..."; Preview and Export cannot be started a second time.
8. The preview page shows the same PDF as before with Share and Print actions; back returns to the options with state preserved (type, range, columns).
9. Export failure shows a banner with Retry; success shows the success snack; the file is saved or shared exactly as before.
10. At text scale 200 percent no summary row overflows and the sticky action bar does not cover the last card (bottom padding equals bar height).
11. Type chips, preset chips, date fields, column chips and both buttons are at least 48 x 48 dp on mobile and reachable by keyboard on macOS.
12. No `Colors.*` / hex; no `BoxShadow` card.

## 7. Performance notes

- Compute the entries and the summary ONCE per (type, start, end) change: hold `_Aggregates` in State recomputed in the handlers that change type or range (not on column toggle, not on build). Column toggles must `setState` only the column card (extract `_ColumnCard` stateful child with a `ValueNotifier<Set<String>>` or callbacks), so 18 chip taps cause no Hive scan.
- `ref` is unused (it is a ConsumerStatefulWidget with no watches): convert to `StatefulWidget` or start watching `ledgerEntriesProvider` to refresh the count when data changes; for the redesign keep as is (logic freeze) and recompute on `didChangeDependencies` only.
- Create the preview build closure once (`late final _buildPdf = (format) => _generatePdfForType();` re-created only when type/range/columns change) so `PdfPreview` does not regenerate on unrelated rebuilds.
- Run generation after the progress UI paints (`await Future<void>.delayed(Duration.zero)`); true isolate offload is a logic change (logic_g3.md).
- `DateFormat('dd MMM yyyy')` becomes a `static final`.
- Split the 1595 line file: `pdf_export_screen.dart` (UI, about 600 lines after redesign), `pdf_ledger_report.dart` and `pdf_side_reports.dart` (frozen generators moved verbatim, no edits to bodies).

## Reconciliation 2026-10-13 (Apple look, Android only)

Scope stays the configuration screen only. PDF CONTENT is frozen: the six generators, columns, fonts, `PdfColors`, 22 rows per page, file names and every "Rs." string inside the PDF. The on-screen summary keeps its own `Rs. 282,910.00` style on purpose (TOKENS.md section 7, C-15), so the screen matches the file. Dropped: macOS and desktop items (Cmd+Enter, Esc, hover, Tab order, expanded layout, medium widths). Old text stays above.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Mockup function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Export to PDF | `SC.exportPdf` | `lib/features/export/pdf_export_screen.dart` (`PdfExportScreen`, config part only) | LargeTitleScaffold ("Export to PDF", trailing Preview button), RigChipRow (export type), RigGroup of two RigFormRows (From, To), column chips as a wrapped RigChipRow with a text button "None" (and "All"), RigGroup of summary RigRows with a footer, pinned bottom bar with RigButton tonal "Preview" and RigButton filled "Export PDF" | PVC chip and PVC columns hidden for a Side Bore rig |
| (preview route, not drawn) | snackbar placeholder "Preview opens here" | same | full screen `PdfPreview` page | `PdfPreview` props frozen |

### R2. What changes in the redesign (supersedes section 4)

Layout (360 dp and 412 dp):
1. LargeTitleScaffold "Export to PDF" (large 34 collapsing to 17). The mockup also puts a trailing "Preview" button in the header; keep ONE preview control: the pinned bar button (the header trailing button is dropped, old problem 2).
2. Section label "EXPORT TYPE" (13 sp uppercase `labelSecondary`) then RigChipRow: Ledger, Diesel, PVC, Bit, Hammer; single select; selected chip is inverse (`inverseChip` fill, `onInverseChip` text); chips are 48 dp touch boxes with a 32 dp visible pill, radius full; PVC hidden for Side Bore.
3. "DATE RANGE": RigGroup with two RigFormRows: From and To, label left, value right in `dFull` form `01 Oct 2026` (this is the export screen's documented own format `dd MMM yyyy`), tap opens the DatePickerSheet (B2 pattern, picker bounds 2000 to 2100 unchanged). When From is after To both rows show an inline error "From date must be on or before To date" and the pinned buttons are disabled (UI only, old problem 3). Default range stays the last 30 days. The preset chips (This month, Last month, Last 30 days, This year) from the old section are NOT in the mockup and are dropped from the first pass (they only set the two dates; they can return as a later UI-only addition).
4. "COLUMNS" row: heading 22 sp "Columns" left and a text button "None" right (the old "All" button comes back when any chip is off, as one text button that reads "All"). 20 chips (Date, Bill#, Agent, Address, Depth, Depth ft, Depth Rate, Step Rate, PVC, PVC ft, PVC Rate, MS Type, MS ft, MS Rate, Extra, Total, Received, Balance, Less, Commission; PVC chips hidden for Side Bore) in a wrapping RigChipRow, selected = on (`inverseChip`) with `aria-pressed`/`Semantics(selected)`, 48 dp boxes. Group sub labels (Identity, Depth, PVC, MS pipe, Money) are NOT in the mockup and are dropped. When none is selected an ErrorBanner "Select at least one column" shows and Export and Preview are disabled (old problem 5).
5. "SUMMARY": RigGroup of RigRows label left (15 sp `labelSecondary`, wraps) and value right (15 sp w600, tabular, `Flexible`, scale down to 75 percent then the 11 sp guard): Total, Received, Balance, Commission with the existing strings `Rs. <western grouping, two decimals>`; footer "The PDF keeps its own amount format. Commission is not part of the total." Value colours stay neutral (the mockup does not colour them); the entries count and the feet or category totals come from the same aggregates as today.
6. Pinned bottom bar (inset + 12 above the system inset, two 50 dp pills side by side, gap 12): RigButton tonal "Preview" and RigButton filled "Export PDF". Generating: the Export pill shows a 20 dp spinner and "Generating..." and both pills are disabled.
7. Zero entries: the summary group is replaced by an EmptyState-lite (icon inbox, "No <type> entries found in the selected date range.", hint "Try a wider date range") and both pills are disabled.
8. Success: RigSnack "PDF exported successfully". Failure: ErrorBanner "Failed to export" with Retry; the raw exception text is not shown inline (Details only).
9. Rig context row "Rig: <name>" (old R-item 1) is not in the mockup. It is kept as a footer line under the Export type chips ("Exporting for <rig name>", 13 sp `labelSecondary`), UI only, open for the developer to confirm because the mockup does not show it.

Colour roles: `inverseChip`, `onInverseChip`, `accentTint` (tonal pill), `accentButton` (filled pill), `labelSecondary`, `moneyOutText` (error text), `fill` (unselected chip). Spacing 20/12; radii 20 group, full chips and pills, 16 banner.

States:

| State | Behaviour |
|---|---|
| Default | all sections, pills enabled |
| Loading | pills disabled, Export shows spinner and "Generating..."; options visible and inert |
| Empty | summary replaced by EmptyState-lite, pills disabled |
| Error | inline date-order errors; zero-columns banner; export failure banner with Retry |
| Disabled | Export and Preview when zero entries, zero columns (Ledger), invalid range or generating |

Motion: chip selection and summary cross fade 150 to 200 ms; preview route uses the default push transition; zero under reduced motion.

Old section 4 items:

| Old item | Verdict |
|---|---|
| Preview as a pushed route with Export in its app bar | KEPT (route outcome unchanged; the mockup only shows a snackbar placeholder) |
| App bar preview icon removed | KEPT (and the mockup header Preview button is dropped to match) |
| Rig context card | CHANGED (footer line, optional) |
| Export type chips with check icon | CHANGED (inverse selected chip, no check icon; selection is still not colour only because the selected pill inverts and `Semantics(selected)` is set) |
| Preset chips row | DROPPED (first pass) |
| Date fields inline errors, disabled buttons | KEPT |
| Column group labels, "N of M selected" count | DROPPED |
| Zero columns banner | KEPT |
| Summary with coloured values, StatusPill count | CHANGED (neutral values, no pill) |
| Sticky bar with Preview and Export, progress bar | CHANGED (two pills, spinner in the Export pill, no linear bar) |
| Empty block instead of the amber box | KEPT |
| Expanded layout, Cmd+Enter, Esc, hover | DROPPED |
| Split of the 1595 line file moving frozen generators | KEPT as a suggestion only; moving code is a refactor with zero body edits and must be a separate commit (see R3) |

### R3. Logic touchpoints and LR items

Untouched: everything in section 5 (generators, `PdfColumn` ids, labels and order, `_pvcColumnIds`, queries `getLedgerEntriesByDateRange` and the side equivalents, `FileSaveService.saveFile(... shareSubject: 'RigLedger <type> Report', dialogTitle: 'Save PDF Report')`, defaults all columns and now minus 30 days, `PdfPreview` props, file name `rigledger_<type>_<yyyyMMdd>_to_<yyyyMMdd>.pdf`).

| Id | Dependency | Status |
|---|---|---|
| LR-32 | Export must not start twice (disable while generating) | approved (UI guard) |
| LR-24 | rupee sign rule does NOT apply here; export content and the on-screen summary keep `Rs.` | approved with the exception stated in TOKENS.md section 7 |
| L3 L-09 | PDF generation off the UI isolate | not scheduled; show progress first |
| L3 L-18 | reversed date range | the inline error is UI only; the range helpers stay untouched |
| BUGS_FOUND (zero columns, UNVERIFIED) | outcome of exporting with zero columns is unknown; the disabled state avoids it | UI guard |

### R4. Acceptance criteria delta

1. At 360 dp and 412 dp, light and dark, the screen matches the mockup order: type chips, date group, columns, summary, pinned two pill bar; the bar never covers the last summary row (bottom padding = bar height + inset).
2. Exactly one Preview control exists.
3. Chips and pills are 48 dp touch targets; the visible chip pill is 32 dp.
4. From after To disables both pills and shows the inline error; fixing it re-enables them.
5. None disables both pills and shows "Select at least one column"; All restores them.
6. The on-screen Total, Received, Balance, Commission equal the PDF summary values and keep the `Rs.` format; no amount in this screen is compact.
7. With defaults the exported PDF is structurally identical to the pre-redesign export (same page count, page 1 text, file name).
8. At text scale 130 and 200 percent no summary row overflows (labels wrap, values shrink to 75 percent then 11 sp) and the chips wrap.
9. With the keyboard not involved there is no text field here; Android back from the screen pops it; back from the preview returns with type, range and columns preserved.
10. Dark mode contrast: chip text, summary text and the destructive error text at least 4.5:1.

### R5. Parity delta

Changes on purpose: lines 33 and 34 (layout and no coloured values); line 36 (the column chips are one wrapping row, order unchanged); line 39 (message text same, new EmptyState look); line 38 (Preview is one button). Must stay identical: line 33 defaults (Ledger, last 30 days, all columns, PVC hidden for Side Bore), line 34 values equal the PDF summary values and keep `Rs.`, line 35, line 37 (file name and message "PDF exported successfully"), line 38 (same document, 22 rows per page), line 40 (page 1 text identical).

### R6. Performance and Android notes

- Insets: edge to edge; the pinned bar uses `viewPaddingOf(context).bottom + 12`; list padding adds the bar height.
- Back: pops the screen; no dirty guard (no unsaved entry fields).
- Compute entries and the summary once per (type, start, end) change and keep them in State; chip toggles rebuild only the column section (no Hive scan per tap); one `DateFormat` as `static final`; create the preview `build` closure once per option change so `PdfPreview` does not regenerate on unrelated rebuilds.
- Paint the progress UI before generating (`await Future<void>.delayed(Duration.zero)`); generation stays on the UI isolate.
- No BackdropFilter; budgets p90 build and raster under 8 ms, p99 under 16 ms.
