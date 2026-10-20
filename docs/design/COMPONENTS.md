# Shared Component Catalogue

> RECONCILED 2026-10-13 for the Apple-inspired Android direction (DESIGN_DIRECTION_APPLE.md, mockup/TOKENS.md). The names in section 0 are the names every task and screen doc uses. Sections 1 to 9 keep the earlier Material-era catalogue as history and as the list of duplicates found; where a name differs, section 0 wins. Desktop and macOS items (RigSidebar, sidebar, title bar, MenuAnchor popups, hover and context menus) are DROPPED (macOS frozen, not edited).

## 0. Reconciled catalogue (Android, light and dark)

All components read colours only through `RigColors` / `ColorScheme`, sizes through `RigSpace` / `RigRadius`, and text through `RigTheme` text styles. None owns business logic: they take values and callbacks (logic freeze). States: D default, P pressed (ink), F focus (keyboard or switch access), X disabled, L loading (Skeleton), E error, M empty. Every tappable has a 48 dp hit box.

| Component | Props | States | Replaces | Used by (Flutter files) |
|---|---|---|---|---|
| `LargeTitleScaffold` | title, subtitle?, actions, leading, bottomBar (RigTabBar slot), body slivers, statusStrip?, backAction | D, collapsed | `RigScaffold`, `RigAppBar`, `AdaptiveHeader`, 14 gradient header Containers, 20 `AppBar`s | every page; Ledger home uses statusStrip (B4) |
| `RigTabBar` | destinations (Ledger, Portfolio, Agents, Accounts, Settings), index, onSelected | D, selected, hidden (keyboard open) | `BottomNavigationBar`, `RigNavigationBar` | `main_navigation.dart` |
| `RigGroup` | header?, footer?, children (RigRow / RigFormRow) | D | per-screen bordered cards and `ListView`s | settings, agents, accounts, forms, lists |
| `RigRow` | leading, title, subtitle, value, trailing/chevron, onTap, onLongPress, swipe actions | D, P, F, X | `ListTile`s, `_buildSettingTile`, cashbook rows, agent card | all lists |
| `RigFormRow` | label, field (text, amount, date, dropdown, switch), error, helper | D, F, E, X | ~100 `InputDecoration` blocks, `RigTextField` family | all forms |
| `RigCard` | child, tone (surface, tinted), padding 16 | D, P | per-card `BoxShadow` containers | bill card, summary cards, stats |
| `RigMetricCard` | label, MoneyText value, caption?, tone (in, balance, commission, neutral) | D, P (tap = full value), L | `_SummaryItem`, `_buildHighlightBox` x4, `_MetricCard` | Ledger summary, Portfolio |
| `RigRing` | received, billed, label | D, L, animated reveal off under reduced motion | none (new) | Ledger summary card |
| `MoneyText` | value, style, tone, allowCompact (false by default), semantics | D | `Text('rupee' + NumberFormat)` in about 60 places | every amount |
| `MoneyTile` | label, value, tone, icon, caption | D, P (full value popover) | `AmountTile`, `AmountGrid` | highlights only (the one place compact L and Cr is allowed) |
| `DepthTile` | label ("7\" Depth" etc.), feet, tone | D | `_FeetItem`, `FeetTile`, `_buildMiniStatDouble` | Ledger summary (3 columns, 5 tiles wrap 3 + 2) |
| `CategoryTile` | category (diesel, pvc, bit, hammer), count, amount, onTap | D, P | `_buildCategoryCard` x2 | Side Ledger home (gradient tiles) |
| `RigChipRow` | chips, selected, onSelected | D, selected (inverse chip), F | `_buildPeriodChip` x2, `_buildRangeChip`, `CashbookPeriodTabs` | period rows (same order everywhere) |
| `RigSegmented` | segments, selected, onChanged | D, F | hand-built toggles | Daily/Calendar, This rig/All rigs, Income/Expense |
| `RigButton` | label, variant (filled, tonal, text, destructive), icon?, busy | D, P, X, L | `ElevatedButton` 35, `TextButton` 57 | all screens (one filled per screen) |
| `RigAlertDialog` | title, message, actions (stacked 48 dp, destructive in `moneyOutText`) | D | `ConfirmDialog`, 29 `AlertDialog` | all confirms |
| `RigSheet` | title?, child, grabber, keyboard insets, full-height flag | D | `showModalBottomSheet` variants, `RigDialogShell` | forms, pickers, filters |
| `RigSnack` (`showRigSnack`) | message, kind, action | D | 115 `SnackBar`s | everywhere (floating capsule above the tab bar and inset) |
| `RigSwitch`, `RigCheck` | value, onChanged | D, X | themed `Switch` and `Checkbox` (circle) | settings, notebook |
| `EmptyState` | icon, title, hint, action | M | per-screen empties | all lists |
| `ErrorBanner` | message, retry | E | ad hoc | sync, import, export |
| `Skeleton` | shape | L | none | first frame after rig switch or restore only |
| `RigRigSheet` | rigs, current, onSelected | D, P | `_showVehicleSwitcher`, desktop popup | Ledger, Portfolio headers (B1); calls `switchRig` |
| `RowActions` | edit, delete (existing flows), long-press menu plus a trailing more button; NO swipe, no new dependency (Q-O7) | D | none (new) | bill, agent, side, Account Ledger rows |
| `UnsavedChangesGuard` | dirty, child, onDiscard | D | none (new) | every form route (`PopScope`), LR-25 |
| `DatePickerSheet` | initial, first, last | D | `showDatePicker` calls | B2 Daily, form date fields (bounds passed by callers) |
| `RigFormat` | money, moneyCompact, qty, ftq, dRow, dGroup, dFull, dMonth | n/a | NumberFormat/DateFormat constructions | everywhere |

Rules: one filled `RigButton` per screen; compact money only in `MoneyTile` and `RigMetricCard`; destructive actions use `moneyOutButton` fill with a white label (5.8:1 light, 4.6:1 dark); never use `lb3` for text that carries meaning.

Old name to new name: `RigAppBar`/`RigScaffold` to `LargeTitleScaffold`; `RigCard` stays; `AmountText` to `MoneyText`; `AmountTile`/`AmountGrid` to `MoneyTile` in a 2 x 2 grid; `FeetTile` to `DepthTile`; `RigTextField`/`RigDropdownField`/`RigDateField`/`RigAmountField`/`RigTimeField` to `RigFormRow` hosting the field; `RigListRow` to `RigRow`; `ConfirmDialog`/`RigDialogShell` to `RigAlertDialog` (confirm) or `RigSheet` (input); `RigSwitcher` to `RigRigSheet`; `RigNavigationBar` to `RigTabBar`; `RigSidebar` DROPPED; `HighlightsPanel` stays as the composition of `RigRing` + `RigMetricCard`s + `DepthTile`s; `EntryFilterSheet` stays but is a `RigSheet`; `SideEntryCard` becomes a `RigRow` variant in a `RigGroup`; `CollapsingLedgerHeader` becomes the `LargeTitleScaffold` status strip; `PeriodNavigator` stays inside the large-title area; `pickRigDate` becomes `DatePickerSheet`.


Spec only. Names are proposals; they are the names the screen docs use. All components live under `lib/core/widgets/rig/` and read only theme tokens (DESIGN_SYSTEM.md). None owns business logic: they take values and callbacks, so provider calls and validators stay in the screens (logic freeze).

Notation: Props are constructor parameters. States: default (D), pressed (P), hover (H, desktop), focus (F), disabled (X), loading (L), error (E), empty (M).

## 1. Foundations

| Component | Props | States | Used by | Replaces (duplicates found) |
|---|---|---|---|---|
| `RigAppBar` | title, subtitle?, leading?, actions, bottom?, collapsible (bool) | D | all screens except shells | `AdaptiveHeader` (2 users: agents, settings); hand-built gradient `Container` headers in combined_home, stats, side_ledger, 4 side list screens, vehicle_management, about, cashbook_header, cashbook_hub, calendar_view, home_screen; 20 Material `AppBar(...)` with different colors |
| `RigScaffold` | appBar, body, fab?, bottomBar?, maxContentWidth, scrollable | D | all pages | per-screen `Scaffold` plus `_DesktopContentWrapper` plus `AdaptiveContent` |
| `RigSection` | title, trailing?, children | D | settings, portfolio, forms | `_buildSectionTitle` x3, ad hoc section headings |
| `RigCard` | child, onTap?, padding(16), tone (surface, container, semantic) | D, P, H, F | every card | ~60 `Container(decoration: BoxDecoration(... BoxShadow ...))` cards, `Card` with elevation 2 |
| `RigDivider` | inset | D | lists | `Divider`, `Container(width:1,height:40,color:divider)` in summary_row |

## 2. Money and numbers

| Component | Props | States | Used by | Replaces |
|---|---|---|---|---|
| `AmountText` | value, style (large, medium, small, hero), tone (neutral, moneyIn, outstanding, negative, commission), compact (auto, never, always), showSign, semanticsLabel | D | every amount | `Text('₹${NumberFormat(...)}')` in about 60 places |
| `AmountTile` | label, value, tone, icon?, caption?, fullValueOnTap (bool) | D, P (tap shows full value), F | main summary, side summary, portfolio, agent card | `_SummaryItem` (summary_row), `_buildSummaryItem` x4, `_buildHighlightBox` x4, `_SummaryCard` (stats) |
| `AmountGrid` | tiles, minTileWidth (140), columns by width (see HIGHLIGHTS_AND_COLLAPSE.md) | D | highlights | hard-coded 4-in-a-row and 5-in-a-row `Row`s |
| `FeetTile` | label, feet, tone | D, P | depth/PVC/MS pipe highlights | `_FeetItem`, `_buildMiniStatDouble` |
| `AmountField` | controller, label, validator (passed through), onChanged | D, F, E, X | all forms | `TextFormField(keyboardType: numberWithOptions...)` repeated 80+ times |
| `MoneyLabelValueRow` | label, value, tone, emphasized | D | bill summary, payment totals, export screens | `_buildSummaryRow` (pdf export), ad hoc label/value Rows |

## 3. Inputs

| Component | Props | States | Used by | Replaces |
|---|---|---|---|---|
| `RigTextField` | controller, label, hint, keyboard, validator (passed through), textInputAction, maxLines | D, F, E, X | all forms | 100+ `InputDecoration(...)` blocks (19 in ledger_form_screen alone) |
| `RigDropdownField<T>` | items, value, onChanged, label, validator (passed through) | D, F, E, X | forms, filter sheet | 14 `DropdownButtonFormField`/`DropdownButton` |
| `RigDateField` | value, onChanged, first, last, label | D, F, E | forms | `InkWell + InputDecorator + showDatePicker` repeated in 18 files |
| `RigSearchField` | controller, onChanged, hint | D, F | search sheet, cashbook search | home search sheet, cashbook `_searching` toolbar |
| `RigSegmented` | segments, selected, onChanged | D, F | Daily/Calendar toggle, This rig/All rigs, Income/Expense | hand-built `GestureDetector` toggles in combined_home (2), portfolio_view |
| `RigChipRow` | chips, selected, onSelected, scrollFade | D | period chips (main, side, portfolio, cashbook) | `_buildPeriodChip` x2, `_buildSideLedgerPeriodChip`, `_buildRangeChip`, `CashbookPeriodTabs` |

## 4. Navigation and switching

| Component | Props | States | Used by | Replaces |
|---|---|---|---|---|
| `RigNavigationBar` | destinations, index, onSelected | D, selected | mobile shell | `BottomNavigationBar` in a shadow `Container` |
| `RigSidebar` | items, index, onSelected, collapsed | D, H, selected | desktop shell | `_DesktopSidebar`, `_SidebarItem` |
| `RigSwitcher` (rig selector) | vehicles (read from provider by caller), current, onSelected, presentation (sheet on compact, popup on expanded) | D, P, F | Ledger header, Portfolio header (B1), desktop title bar | `_showVehicleSwitcher` bottom sheet (combined_home) AND `PopupMenuButton<Vehicle>` (desktop title bar) |
| `PeriodNavigator` | label, onPrevious, onNext, onLabelTap?, canNext | D, X (edge), F | month/year nav in Ledger and Side Ledger, Account Ledger period bar, B2 date picker entry | duplicated chevron rows (month, year) x2 per tab, `CashbookPeriodBar`, `CashPeriodSelector` |
| `RigTabBar` | labels, controller | D, selected | Ledger/Side Ledger, Portfolio tabs, Account Ledger tabs | two hand-built white pill `TabBar`s |

## 5. Lists

| Component | Props | States | Used by | Replaces |
|---|---|---|---|---|
| `RigListRow` | leading, title, subtitle, trailing, onTap, onLongPress, dense | D, P, H, F, X | agents, settings, accounts, vehicles | many `ListTile`s and custom rows |
| `LedgerEntryCard` | entry view-model fields only (bill no, agent, depth text, amounts, commission), onTap | D, P, H | main ledger list | `_LedgerEntryCard` (ledger_list.dart) |
| `SideEntryCard` | kind (diesel, pvc, bit, hammer), title, lines, amount, onTap | D, P | the 4 side lists | `_DieselEntryCard`, `_PvcEntryCard`, `_BitEntryCard`, `_HammerEntryCard` (near duplicates) |
| `DayGroupHeader` | date, total, count? | D, pinned | main list, cashbook list | `_DateGroup` header, `CashbookDayHeader` |
| `EntryFilterSheet` | sections (range, text, dropdown), onApply (caller keeps provider writes) | D | filter for 4 side lists and main | `FilterSheet` (home) plus `_DieselFilterSheet`, `_PvcFilterSheet`, `_BitFilterSheet`, `_HammerFilterSheet` |
| `CategoryTile` | icon, title, count, amount, tone, onTap | D, P | side ledger home | `_buildCategoryCard` x2 |

## 6. Feedback and overlays

| Component | Props | States | Used by | Replaces |
|---|---|---|---|---|
| `EmptyState` | icon, title, hint?, action? | M | every list | per-screen empty `Column`s with different icon sizes |
| `ErrorBanner` | message, onRetry? | E | sync, import, export | ad hoc `Container`s and snackbars |
| `RigSnack` (helper `showRigSnack(context, message, kind, action?)`) | message, kind (success, error, info), action | D | all 115 SnackBar sites | `SnackBar(backgroundColor: Colors.red/AppColors.error/...)` |
| `ConfirmDialog` | title, message, confirmLabel, destructive | D | delete flows (20 sites) | `AlertDialog` copies |
| `RigSheet` | title, child, showHandle, maxWidth | D | sheets (11 sites) | `showModalBottomSheet` with local handles, shapes, `backgroundColor: Colors.transparent` |
| `RigDialogShell` | title, content, actions, maxWidth | D | dialogs that own controllers (see MEMORY.md gotcha: dialogs own and dispose their controllers) | local `AlertDialog` shapes |
| `DatePickerLauncher` (function `pickRigDate`, `pickRigDateRange`) | initial, first, last, helpText | D | all pickers | 20 `showDatePicker`/`showDateRangePicker` calls with different first/last dates |

## 7. Collapsing ledger header (B4)

| Component | Props | Notes |
|---|---|---|
| `CollapsingLedgerHeader` | pinned (title row), collapsible (tabs, period, view toggle, highlights), revealBuilder | built with `SliverAppBar` or `SliverPersistentHeader` inside a `NestedScrollView`/`CustomScrollView`; full spec in HIGHLIGHTS_AND_COLLAPSE.md |
| `HighlightsPanel` | tiles, layout (grid, wrap), compact policy | B5 spec |

## 8. Duplicates and dead code found during the audit

1. `lib/features/home/home_screen.dart` (378 lines) is never instantiated; `CombinedHomeScreen` is the live screen. Same for `lib/features/side_ledger/side_ledger_screen.dart` (200 lines, `SideLedgerScreen` never instantiated; the Side Ledger tab is `_buildSideLedgerContent` in combined_home_screen.dart). Both duplicate header, chips and summaries. Delete only after the live screens are migrated (BUGS_FOUND.md B-18, MIGRATION_PLAN.md cleanup).
2. Vehicle switcher: bottom sheet in combined_home_screen.dart (line 1081) versus popup in desktop_shell.dart `_DesktopTitleBar`. Same refresh calls written twice, and the sheet version refreshes only 6 providers while the convention says 8 (`vehiclesProvider` and `currentVehicleProvider` not refreshed there; verify, BUGS_FOUND.md).
3. Add-entry choice: `_showAddSideLedgerSheet` in main_navigation.dart and `_buildAddOption` in desktop_shell.dart.
4. Period chips: main (`_buildPeriodChip`), side (`_buildSideLedgerPeriodChip`), portfolio (`_buildRangeChip`), Account Ledger (`CashbookPeriodTabs`). Four implementations, four label sets (Month/3 Mo/6 Mo/Year/Custom/All versus Day/Month/3 Mo/6 Mo/Year/All/Custom versus All/Daily/Weekly/Monthly/Yearly).
5. Four side list screens (diesel, pvc, bit, hammer) each define their own card, filter sheet and empty state.
6. Four screens each define `_buildSummaryItem`/`_buildHighlightBox`.
7. Date range pickers: `_pickMainLedgerDateRange` (combined_home), side equivalent, `_buildCustomDateRangePicker` (stats), `pickCashDateRange` (cashbook).

## 9. Additional components requested by the screen audits

### Forms and side ledger (g1)


Names follow COMPONENTS.md. Components not in the catalogue are marked NEW.

| Name | Props | States | Used by | Replaces |
|---|---|---|---|---|
| `FormSaveBar` (NEW) | total (ValueListenable<double>?), secondaryLabel and value (ValueListenable<double>?), tone, primaryLabel, onPrimary, saving (bool) | default, saving (spinner, disabled), disabled | main bill form, side bore form, diesel, PVC, bit, hammer forms | the end-of-scroll Save `ElevatedButton`s |
| `UnsavedChangesGuard` (NEW) | child, isDirty (callable), onDiscard | default, prompting | all 6 forms | missing discard behavior (B-G1-14) |
| `SideEntryCard` (catalogue) | kind (diesel, pvc, bit, hammer), title, subtitle, total, statusPaid, dueAmount, typeChips (list), nameChip?, detailsRows (list, optional), onTap, menuItems (Edit, Delete) | default, pressed, hover, focus, loading (skeleton) | the four side lists | `_DieselEntryCard`, `_PvcEntryCard`, `_BitEntryCard`, `_HammerEntryCard` |
| `EntryFilterSheet` (catalogue) | sections: text(label, hint), chips(options, single), dateRange, onApply, onClear, initial values | default, with keyboard (scrollable), error (range) | four side lists | four `_XFilterSheet` classes |
| `ActiveFilterBar` (NEW, thin wrapper of `RigChipRow`) | labels, onRemove(index), onClearAll | hidden when no filter | four side lists | the 8 dp filter dot as the only signal |
| `SideSummaryStrip` (NEW, composition of `AmountGrid`) | tiles, chips (optional pieces by type), accent token | default | four side lists | four gradient summary cards and `_buildSummaryItem` x4 |
| `TypeChipSelector` (NEW, `RigChipRow` multi-select preset) | options, selected (Set), onToggle, unknownSelected (list) | default, disabled chip for unknown legacy type | PVC, bit, hammer forms | three `FilterChip` wraps with per-type hues |
| `TypeCountRateCard` (NEW) | typeLabel, countController, rateController, lineTotalListenable | default, error (inline messages) | PVC, bit, hammer forms | three copies of the per-type container |
| `CommissionSection` (existing widget, restyle) | unchanged API | default, manual override | main and side bore forms | local container/icon/colors |
| `PaymentLogEditor` (existing widget, restyle) | unchanged API | empty, populated | both bill forms | local container and `ListTile`s |
| `AmountField` (catalogue) | controller, label, helper, validator (passed), onChanged, textInputAction, manualMarker (bool), onAuto | default, focus, error, manual | all forms | 80 numeric `TextFormField` blocks with the repeated regex |
| `pickRigDate` (catalogue function) | initial, first, last, helpText | n/a | all forms and filters | 20 `showDatePicker` calls; clamps `initialDate` |


### Account Ledger (g2)


| Name | Props | States | Used by |
|---|---|---|---|
| `RigMenuButton` | items (label, value, checked?, icon?, divider before?), onSelected, tooltip (required) | D, P, F, X | home overflow, notebook, trash, entry form |
| `RigTimeField` | value, onChanged, use24Hour (from CashSettings), label | D, F, E | entry form, transfer, note form |
| `TypeBadge` | isIncome | D | home rows, trash rows, all-transactions rows |
| `CashTotalsCard` | totals, previousBalance?, settings-formatted strings, layout (row, stacked) | D | home, summary, account summary, all transactions, calendar |
| `RigStatStrip` | cells (label, value string, tone) | D | notebook stats, totals card (3 cells) |
| `RigChoiceDialog<T>` | title, options (label, value), current, presentation (sheet or dialog) | D, P, F | settings choosers, copy chooser, restore chooser, report format, book row menu, trash row menu |
| `FilterSummaryBar` | chips (label, onRemove), onClearAll | D | home |
| `LedgerRowTile` | CashLedgerRow view fields, settings-formatted strings, layout (compact, table), onTap, onSecondaryTap | D, P, H, F | home, all transactions (variant with book name) |
| `LedgerActionBar` | onIncome, onExpense, totals child | D, X | home |
| `HubPanel` | items grouped, selectedId?, collapsed | D, H, selected | hub |
| `CalendarDayCell` | day, income string?, expense string?, isToday, onTap | D, P, X (no entries), F | calendar |
| `CalcKey` | label or icon, kind (digit, operator, action) | D, P, F, X | calculator sheet |
| `RigSwitchRow` | title, subtitle?, value, onChanged | D, F, X | settings, add account (Receiver book), import (notebook) |


### Agents, settings, exports, stats (g3)


Each: name, props, states, used by. All read tokens only and own no business logic.

- `AgentAvatar`: props initial (String), size (default 40). States: default. Fill `primaryContainer`, glyph `primary`, `titleMedium`. Used by agents_screen (could be reused by Accounts later).
- `StatusPill`: props label, tone (neutral, moneyIn, outstanding, negative, info, commission, primary), icon?, dense. States: default. Min height 24, text `labelSmall`/`labelMedium`, fill the tone container, text the tone. Used by vehicle cards (Active), export summary (N entries), import review (Valid, Errors), "Required" marker in mapping rows.
- `ProgressDialog`: props title, message, determinate value?, dismissible false. States: indeterminate, determinate. Built on `RigDialogShell`, max width 360. Used by settings (restore, clear all, backup).
- `TypedConfirmDialog`: props title, body (widget), keyword ("DELETE"), confirmLabel, onConfirm (callback owned by the caller), extra action (e.g. "Create backup first"). States: default, keyword mismatch (confirm disabled), confirming. Dialog owns and disposes its `TextEditingController`. Used by settings Clear All Data.
- `PeriodPresetBar`: props options (list of id + label), selectedId, onSelected, captionText (e.g. "1 Oct 2026 to 31 Oct 2026"), scrollFade. Behavior: scrolls the selected chip into view; ChoiceChips with check icon. States: default, selected, focus, disabled. Generalizes `RigChipRow`. Used by the Stats page (all three tabs, hosted by the lead's header), could replace Ledger and Portfolio chips.
- `CustomRangeRow`: props start, end, onStartChanged, onEndChanged, errorText?. Two `RigDateField`s that stack below 360 dp or at text scale >= 1.5. Used by Stats custom range; PDF/CSV export date ranges.
- `PeriodPresetRow` (export screens): same as `PeriodPresetBar` with fixed presets (This month, Last month, Last 30 days, This year) that only set two dates in the screen's State. Used by pdf_export_screen, csv_export_screen.
- `ExportActionBar` (also `FlowActionBar`): props primaryLabel, primaryIcon, onPrimary, secondary (optional button), loading, loadingLabel, leading (Back). Sticky bottom bar on compact (`SafeArea`, level 1 surface, 1 px top `outlineVariant`), inline at the end of the column on expanded. Shows a 2 px `LinearProgressIndicator` on top while loading. Used by pdf_export_screen, csv_export_screen, csv_import_screen.
- `ImportStepHeader`: props steps (labels), current, completed. Semantics "Step N of M, label, state". Used by csv_import_screen.
- `MappingRow`: props expectedLabel, required, headers (list ref), selectedIndex, onChanged. Stacks on compact, two columns at >= 600. Used by csv_import_screen.
- `ChartCard`: props title, caption?, child, legend (widget list), emptyState?. `RigCard` with chart header. Used by stats_screen_charts (By Agent, category cards) and Portfolio.
- `DonutChart`: props sections (value, color, label), centerLabel (widget), highlightNotifier (`ValueNotifier<int?>`), size, thickness, semanticsLabel. Wraps fl_chart `PieChart`, no setState, `RepaintBoundary`. Used by stats_screen_charts (agent donut, 4 category donuts), Portfolio expense breakdown.
- `ChartLegendRow`: props swatchColor, swatchShape (filled or hollow), label, amount (widget), percentText, highlighted, onHover/onFocus. Min height 48, stacked amount over percent. Used with `DonutChart`.
- `DetailStatCard`: props title, icon, tone (category), entriesCount, rows (list of label, value, tone, indent). Built on `MoneyLabelValueRow`. Used by stats Side Ledger tab.
- `StartupSplash` and `StartupErrorScreen`: props phaseText / error + onRetry + details. Used by main.dart `StartupGate` (needs developer approval).
- `RigScrollBehavior`: class, enables mouse and trackpad drag and always visible desktop scrollbars. Used by MaterialApp (main.dart).

