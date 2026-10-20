# Inconsistency Inventory (B3)

> RECONCILED 2026-10-13: the resolving tokens and components are now the Apple-inspired Android set (DESIGN_SYSTEM.md section R, COMPONENTS.md section 0, mockup/TOKENS.md). The table "Resolution status" at the end maps every lead item (I-xx) to its new resolver and the task that applies it. Items A1 to A3 name Material-era components in their rows: translate them with the old-to-new name table in COMPONENTS.md section 0.

Numbered inventory of UI inconsistencies found across RigLedger on 2026-10-12, from grep counts over `lib/` (excluding generated files) and reading the screens. Every item names the evidence and the token or shared component that resolves it. Because of this inventory, the foundation tasks (tokens, formatters, shared components) come first in MIGRATION_PLAN.md (T-U01 to T-U08), then the B3 fix tasks (T-U10 to T-U19) that apply them screen by screen.

Counts are `grep` line counts, so they are lower bounds. IDs are stable: MIGRATION_PLAN.md and PARITY_CHECKLIST.md refer to them. Items prefixed A1 to A3 are merged from the per-area audits at the end of this file.

## 1. Color

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-01 | Text colors that fail WCAG AA are used for money: Received green #10B981 (2.54:1), Balance amber #F59E0B (2.15:1), error #EF4444 (3.76:1), hint #94A3B8 (2.56:1), commission teal #0490B6 (3.70:1) | `app_colors.dart:27-30`, `ledger_list.dart` `_ValueDisplay`, `summary_row.dart`, `portfolio_view.dart` | tokens `moneyIn`, `outstanding`, `negative`, `commission`, `textMuted` (DESIGN_SYSTEM.md 3.2) |
| I-02 | Mobile headers use white 80 percent text over gradient stop #618DCE (about 2.7:1) | `combined_home_screen.dart:113-132`, `stats_screen.dart:75-84`, `adaptive_header.dart` | `headerSurface` (flat seed) or two-stop `headerGradient` ending at the seed |
| I-03 | Raw named colors instead of roles: `Colors.red` 41, `Colors.green` 28, `Colors.blue` 24, `Colors.grey(.shadeN)` about 50, `Colors.orange` 12, `Colors.purple` 10, `Colors.brown` 8, plus `Colors.indigo/teal/cyan` | 62 files; worst: `summary_row.dart:104-155` (blue, indigo, teal, cyan, orange for 5 feet tiles) | semantic roles; `categoryDiesel/Pvc/Bit/Hammer`; one neutral for feet tiles (`onSurfaceVariant` label, `primary` value) |
| I-04 | Hex literals outside `app_colors.dart` (7): the gradient triple is copied into form app bars, hammer brown in forms | `diesel_form_screen.dart:204`, `bit_form_screen`, `hammer_form_screen`, `pvc_form_screen`, `side_bore_form_screen`, `combined_home_screen` (1), `cashbook_common.dart` (2) | `RigColors` extension |
| I-05 | Success and error SnackBars use three different sources: `AppColors.error` (14), `Colors.red` (10), `AppColors.success` (12), `Colors.orange` (1), `AppColors.warning` (2) | grep `SnackBar(` 115 sites in 18 files | `showRigSnack(kind)` |
| I-06 | Balance color flips to the "received" green when the balance is zero or below, so a credit reads as received | `ledger_list.dart` balance color expression | explicit rule in the card spec (`outstanding` above zero, `moneyIn` at zero or less, never `negative`) and label unchanged |
| I-07 | Unused palette entries: `gradient4`, `gradient5`, `accentLight`, `chartColors` partly used, `primaryGradient` and `cardGradient` used only in calendar and few places | `app_colors.dart` | token cleanup (T-U20) |

## 2. Typography

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-10 | 16 font sizes in use: 8 (5), 9 (7), 10 (16), 11 (9), 12 (92), 13 (26), 14 (56), 15 (7), 16 (54), 18 (28), 20 (21), 22, 24, 28, 30, 32 | grep `fontSize:` 334 lines in 51 files | type scale (DESIGN_SYSTEM.md 4.1), floor 11 sp |
| I-11 | Inline `TextStyle(fontSize:..., fontWeight:..., color:...)` instead of `Theme.of(context).textTheme`; the theme `textTheme` is defined but almost unused | `app_theme.dart:150-230`, 334 inline sizes | `RigType` tokens via `TextTheme` |
| I-12 | No tabular figures anywhere, so right-aligned amounts do not line up | all amount `Text`s | `amount*` styles with `FontFeature.tabularFigures()` |
| I-13 | System font per platform (Roboto on Android, SF on macOS); Noto Sans is bundled only for PDFs | `pubspec.yaml` fonts, `main.dart` theme has no `fontFamily` | one bundled family (Q-Brand) |
| I-14 | Screen title size differs: mobile 20 sp w600 (`adaptive_header`, home, stats), desktop headers 18 sp, `cashAppBar` 18 on desktop and 20 on mobile, title bar 16 | `adaptive_header.dart:77,138`, `cashbook_common.dart:24-27`, `desktop_shell.dart` title bar | `headlineSmall` 20 everywhere, title bar `titleMedium` |
| I-15 | Amount sizes in one card: bill card 14 sp values, summary 16 sp, group header 14 sp, portfolio hero 24-30 sp | `ledger_list.dart`, `summary_row.dart`, `portfolio_view.dart` | `amountSmall/Medium/Large`, `displayAmount` |

## 3. Shape, spacing, elevation

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-20 | 12 radii: 12 (68), 16 (46), 8 (29), 20 (20), 6 (8), 4 (8), 10 (5), 25 (4), 2 (4), 3 (1), 18 (1) | grep `BorderRadius.circular` 185 lines | `RigRadius` xs..full with the mapping in DESIGN_SYSTEM.md 6 |
| I-21 | Spacing: 28 distinct `EdgeInsets` forms; off-grid values 6, 10, 14 | grep: `all(16)` 83, `all(12)` 28, `symmetric(horizontal:16,vertical:8)` 7, `vertical:14` 4, `vertical:10` 3, `vertical:6` 4 | `RigSpace` |
| I-22 | Card elevation recipes: `Card` elevation 2 (theme), `BoxShadow` blur 10 alpha 0.05 (bill card), blur 10 alpha 0.1 (summary), blur 8 alpha 0.05 (side summary), 1 px border without shadow (feet card, cashbook) | `app_theme.dart:44-49`, `ledger_list.dart`, `summary_row.dart:23-29`, `combined_home_screen.dart` (side card), `calendar_view.dart:55-62` | `RigCard` level 1 |
| I-23 | Content width: `AdaptiveContent` default 800, About 700, cashbook `CashPageBody` 700, forms 700 (convention) but `_DesktopContentWrapper` does not constrain at all | `adaptive_header.dart:166`, `about_screen.dart:36`, `cashbook_help_screen.dart:58`, `desktop_shell.dart` wrapper | `RigScaffold.maxContentWidth` (1100 lists, 640 forms) |
| I-24 | Bottom padding for FAB differs: 100 (ledger list), unspecified elsewhere | `ledger_list.dart:57` | list sliver padding 88 token `fabClearance` |

## 4. Headers and navigation chrome

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-30 | Five header recipes: (a) hand-built gradient `Container` + `SafeArea` (home, stats, list screens, vehicle management, calendar), (b) flat `AppColors.primary` `AppBar` (ledger form, PDF export), (c) gradient via `flexibleSpace` with literal hexes (4 side forms), (d) `cashAppBar` (white on gradient mobile, dark text on white desktop), (e) `AdaptiveHeader` (2 users). `GradientAppBar` in `gradient_widgets.dart` has no users | `ledger_form_screen.dart:526-529`, `diesel_form_screen.dart:197-205`, `pdf_export_screen.dart:210-213`, `cashbook_common.dart:16-40`, `adaptive_header.dart`, `gradient_widgets.dart` | `RigAppBar` |
| I-31 | Account Ledger is visibly a different app: light app bar on desktop, "Rs." money, `MMM-dd-yyyy` dates, red/green flat full-width buttons, no cards (screenshot 03 vs 00) | `cashbook_common.dart`, `cashbook_home_screen.dart`, `cashbook_totals_strip.dart` | shared tokens and `RigCard`, `RigListRow`, `AmountText` |
| I-32 | Tabs: two white pill `TabBar`s (Ledger tabs, Portfolio tabs) with different heights, plus underline-less hand-built toggles (Daily/Calendar) | `combined_home_screen.dart:150-190, 280-340`, `stats_screen.dart:88-113` | `RigTabBar`, `RigSegmented` |
| I-33 | Period chip sets and orders differ: Month, 3 Mo, 6 Mo, Year, Custom, All (Ledger); Month, 3 Mo, 6 Mo, Year, Custom, All (Side Ledger, in body, white); Day, Month, 3 Mo, 6 Mo, Year, All, Custom (Portfolio); All, Daily, Weekly, Monthly, Yearly (Account Ledger) | `_buildPeriodChip`, `_buildSideLedgerPeriodChip`, `_buildRangeChip`, `CashbookPeriodTabs` | `RigChipRow` plus one copy decision (question) |
| I-34 | Chips clipped without affordance: "All" shows as "Al" in Portfolio and Side Ledger on 411 dp | screenshots 01 and 05 | `RigChipRow` fade edge and scroll-into-view |
| I-35 | Bottom nav (mobile) labels "Accounts"; sidebar "Account Ledger"; screen title varies | `main_navigation.dart`, `desktop_shell.dart:57-60` | single label set |
| I-36 | Nav shells: `BottomNavigationBar` in a shadow `Container` (M2) with M3 theme; desktop sidebar custom | `main_navigation.dart:70-80` | `RigNavigationBar`, `RigSidebar` |
| I-37 | Rig switcher in two forms: bottom sheet "Switch Vehicle" (mobile) and popup "Switch vehicle" (desktop), icons `precision_manufacturing` vs `directions_car`; strings use "vehicle" while the UI says "rig" | `combined_home_screen.dart:1081`, `desktop_shell.dart` title bar | `RigSwitcher` and one wording decision (question) |

## 5. Buttons, inputs, forms

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-40 | Buttons: 35 `ElevatedButton`, 5 `OutlinedButton`, 57 `TextButton`, 0 `FilledButton`; Save buttons are `ElevatedButton` with padding 12 or 14 or 16, radii 10 or 12; Account Ledger Income/Expense are custom full-width colored buttons | grep; `desktop_shell.dart` sidebar button radius 10; `app_theme.dart:97-117` radius 12 | button theme + `RigButton` variants, one primary per screen |
| I-41 | Form fields: about 100 `InputDecoration(...)` blocks written per field (19 in `ledger_form_screen.dart`), some override the theme border, others rely on it | grep `InputDecoration(` | `RigTextField`, `RigDropdownField`, `RigDateField`, `RigAmountField` |
| I-42 | Dropdowns: 14 `DropdownButtonFormField`/`DropdownButton`, plus `Autocomplete`, plus `PopupMenuButton` (7) for pick-one lists | filter_sheet (5), ledger_form_screen (4), payment_log_editor, csv_import, cashbook forms | `RigDropdownField`; `RigSheet` pickers for long lists |
| I-43 | Date input: `InkWell + InputDecorator + showDatePicker` rebuilt in 18 files with different `firstDate`/`lastDate` (2000 to now, 2000 to 2100, custom) | grep `showDatePicker` 20 lines | `RigDateField`, `pickRigDate` (bounds passed by caller, existing bounds preserved) |
| I-44 | Keyboards: amount fields do not all use `numberWithOptions(decimal: true)`; text fields do not set `textInputAction` or capitalization consistently | forms (see g1 audit) | `RigAmountField`, `RigTextField` defaults |
| I-45 | Validation timing differs per form (on submit only vs per field) | forms | `AutovalidateMode.onUserInteraction` after first submit |

## 6. Dialogs, sheets, feedback

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-50 | 36 `showDialog` (29 `AlertDialog`), 14 `showModalBottomSheet`; sheets use local `backgroundColor: Colors.transparent` plus their own rounded `Container`, or the theme shape, or a custom `borderRadius: 20` | `filter_sheet.dart:42-48`, `combined_home_screen.dart:1085`, `search_sheet.dart` | `RigSheet`, `ConfirmDialog`, `RigDialogShell` |
| I-51 | Destructive confirmations differ: some use red `TextButton`, some `ElevatedButton` red, some have no confirm | grep delete flows | `ConfirmDialog(destructive: true)` |
| I-52 | SnackBar: 115 sites, no duration set anywhere (default 4 s), no action, floating from theme but bottom offset ignores the nav bar on some screens | grep | `showRigSnack` |
| I-53 | Empty states: icon sizes 64 (7 places), 48 (2), none; copy style varies ("No entries yet", "No vehicles found", "No books found", "No payments yet", "No transactions"); cashbook shows a muted hint | `ledger_list.dart:20-45`, `combined_home_screen.dart:1127`, `cashbook_book_picker_dialog.dart:86`, `payment_log_editor.dart:123` | `EmptyState` |
| I-54 | Error states: errors are shown only as SnackBars or `AlertDialog`; no inline error component; no retry affordance | settings sync, import screens | `ErrorBanner` |
| I-55 | Loading states: `CircularProgressIndicator` in different sizes/colors (grep `CircularProgressIndicator`), no skeletons | settings, export, import | `RigProgress` sizes (24 inline, 40 page) |

## 7. Formats

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-60 | Currency symbol and grouping: `NumberFormat('#,##0.00')` with literal `'₹'` string (14 + about 40 string sites), `NumberFormat.currency(locale: 'en_IN', symbol: '₹')` (9), `Rs.` prefix (cashbook calculator, 2 files, PDFs) | grep; MEMORY.md open decision "Rs. vs the rupee sign" | `RigFormat.money` (decision Q-Brand: symbol and Indian grouping) |
| I-61 | 11 date patterns: `dd/MM/yyyy` (12), `dd MMM yyyy` (9), `MMMM yyyy` (3), `EEE, dd MMM yyyy` (3), `MMM-dd-yyyy` (2), `MMM d, yyyy`, `EEE, MMM dd yyyy`, `HH:mm`, and storage formats | grep `DateFormat(` | `RigFormat` date tokens (storage and file names unchanged) |
| I-62 | Range label repeats a single day ("Oct-12-2026 -> Oct-12-2026") and uses "->" while the home screen uses "To" via string replace | `cashbook_calculator.dart:197`, `cashbook_home_screen.dart:105` | one range formatter (same day collapses) |
| I-63 | Feet: summary `#,##0 ft` (no decimals), bill card `'${depthInFeet}ft'` raw double, PDF uses its own `_feetFormat` | `summary_row.dart`, `ledger_list.dart`, `pdf_export_screen.dart` | `RigFormat.feet` (UI only; PDF unchanged) |
| I-64 | `NumberFormat`/`DateFormat` instances constructed inside `build` (33 and 39 sites, many per list item) | e.g. `ledger_list.dart` `_LedgerEntryCard.build` | static cached formatters |
| I-65 | Quantity units: "ft", "ft" without space ("500.0ft" in bill card vs "450 ft" in summary), "pcs", "L" | `ledger_list.dart`, `summary_row.dart`, `combined_home_screen.dart` | `RigFormat.feet/pieces/litres` (space before unit) |

## 8. Icons and list rows

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-70 | Icon styles: `_outlined` 94, `_rounded` 4, plain filled for the rest of 355 `Icons.*`; sizes 10, 14, 16, 18, 20, 22, 24, 28, 32, 48, 64 | grep `Icons.` and `size:` | rounded only; sizes 16/20/24/48 |
| I-71 | One concept, several icons: Bit tile vs Bit add option (`Icons.settings` gear) vs list; PVC `format_paint_outlined` in card, `plumbing` in chooser; rig `directions_car` vs `precision_manufacturing` | `main_navigation.dart:~175-200`, `ledger_list.dart`, `desktop_shell.dart` | icon map in COMPONENTS (`CategoryTile`, `RigSwitcher`) |
| I-72 | List rows: `ListTile`, custom `Row` cards, `InkWell` cards, cashbook flat rows with different heights (56 to 96) and divider styles | agents, settings, accounts, vehicles | `RigListRow` |
| I-73 | Tap targets below 48 dp: 10 dp edit icon, 14 dp icons in chips, `IconButton`s with `visualDensity: compact`/constraints, 8 dp filter dot as sole indicator | `ledger_list.dart` `_ValueDisplay`, `combined_home_screen.dart:135-150` | `MaterialTapTargetSize.padded`, min 48 rule |
| I-74 | Desktop interactions missing on custom widgets: `GestureDetector` toggles and `MouseRegion` sidebar items have no focus ring, no keyboard activation, no semantics | `combined_home_screen.dart:280-340`, `desktop_shell.dart:660-730` | `RigSegmented`, `RigSidebar` using `InkWell`/`Focus` |

## 9. Mobile versus desktop

| ID | Inconsistency | Evidence | Resolved by |
|---|---|---|---|
| I-80 | Only 8 files branch on `PlatformHelper.isDesktop`; every other screen is the phone layout stretched, with no max width in the shell | `adaptive_header.dart`, `settings_screen.dart`, `cashbook_home_screen.dart`, `cashbook_common.dart` (2), `cashbook_header.dart`, `cashbook_hub_screen.dart`, `cashbook_entry_form_screen.dart`, `main.dart` | width classes (compact/medium/expanded) from `LayoutBuilder`, not platform checks |
| I-81 | Different navigation idioms for the same data: bottom sheets on mobile, dialogs on desktop for the same chooser | `main_navigation.dart` vs `desktop_shell.dart` add chooser | `RigSheet` adaptive presentation |
| I-82 | `PlatformHelper.isDesktop` includes Windows and Linux although macOS is the only desktop target | `platform_helper.dart` (BACKLOG) | width classes plus `isMacOS` only where chrome differs |
| I-83 | Keyboard hint text (`Cmd 1-4`) out of date; shortcuts only partly wired (Cmd+F empty) | `desktop_shell.dart:362,648` | hints from one shortcut table |

## 10. Additional items merged from the per-area audits

Appended from the per-area audits. IDs inside each section are the audit's own; the resolving token or component is named in each row.

### A1. Forms, payment log and side ledger


Format: area, what differs (file:line), resolving token or component.

| # | Area | Inconsistency | Resolves with |
|---|---|---|---|
| I-G1-01 | Header | Main bill form: flat `AppColors.primary` AppBar (`ledger_form_screen.dart:526-530`). Side bore form and the four side forms: gradient via `flexibleSpace` with literal hex `0xFF252B49/0xFF315D9A/0xFF618DCE` (`side_bore_form_screen.dart:391-399`, `diesel_form_screen.dart:199-207`, same in pvc/bit/hammer forms). Four list screens: hand-built `Container(AppColors.appBarGradient)` with centered title (`diesel_list_screen.dart:121-172`). | `RigAppBar` (flat `headerSurface`) |
| I-G1-02 | Save button | Main form: `SizedBox(height 50)` + default `ElevatedButton`. Side bore: explicit primary/white, padding 16, radius 12, 16 sp w600 (`side_bore_form_screen.dart:770-787`). Side forms: category-colored (orange, blue, purple, brown) `ElevatedButton`. | `FormSaveBar` + `FilledButton` in `primary` |
| I-G1-03 | Save placement | Every form puts Save at the end of a long scroll. | `FormSaveBar` pinned bottom |
| I-G1-04 | Date field | Main and side bore: bordered `Container` + `InkWell` with calendar and edit icons. Side forms: `Card > ListTile`. Payment dialog: `InkWell + InputDecorator`. Filter sheets: `OutlinedButton.icon`. | `RigDateField` |
| I-G1-05 | Date format | `EEE, dd MMM yyyy` (main/side bore forms, line 522/384), `dd MMM yyyy` (payment log), `dd/MM/yyyy` (side lists, side forms, filters). | `RigFormat.dateShort` |
| I-G1-06 | Currency format | `NumberFormat('#,##0.00')` with literal rupee sign (main form preview, payment log, commission helper `#,##0.##`); `NumberFormat.currency(locale: 'en_IN', symbol)` in side bore form and all side ledger screens; `toStringAsFixed` in card text. | `RigFormat.money` / `AmountText` |
| I-G1-07 | Date picker theme | Main form themes the picker (`ledger_form_screen.dart:320-330`); side bore, side forms, filter sheets and payment dialog use the default; ranges 2000-2100 vs 2020-now+365. | `pickRigDate` |
| I-G1-08 | Field decoration | Main/side bore use the theme default decoration (hint + prefix icon, section title above). Side forms set `border: OutlineInputBorder()` locally on about 9 fields per form. Main-form numeric fields use `labelText`, bill/agent/address/notes use `hintText`. | `RigTextField` / `AmountField` |
| I-G1-09 | Required marker | Side forms: `labelText: 'Bill Number *'`, 'Litres *'; chip group labels with `*` on plain `Text`. Bill forms: none. | `RigTextField(required: true)` rule: label without asterisk, helper "Required" |
| I-G1-10 | Bill number keyboard | Main and side bore: `TextInputType.text`. Side ledger forms: `TextInputType.number` + `digitsOnly`. (Different field meaning; copy only reconciled via helper text.) | `RigTextField` keyboard prop; see logic_g1.md L-07 |
| I-G1-11 | Delete confirm | Main/side bore: filled red `ElevatedButton` (`AppColors.error`), message "cannot be undone". Lists: `TextButton` with `Colors.red`, message names the bill. | `ConfirmDialog(destructive)` |
| I-G1-12 | Snackbars | Main/side bore: success background `AppColors.success` for save, `AppColors.error` for delete. Side forms: default snackbar on success, `Colors.red` on error. Lists: default for delete. | `RigSnack` kinds |
| I-G1-13 | Totals panels | Main: tinted calc preview + text field. Side bore: primary tint box with 24 sp amount. Diesel/PVC: green tint box 20 sp. Balance: side bore amber/green, diesel red/blue, PVC red only. | `AmountTile` with tones |
| I-G1-14 | Category colors | Diesel orange everywhere (consistent). PVC blue. Bit green in form date icon and design system but purple in list/FAB/Save. Hammer brown in list/form but teal (`AppColors.accent`) in dead `SideLedgerScreen`. | `categoryDiesel/Pvc/Bit/Hammer` tokens |
| I-G1-15 | Icons | Mix of filled and outlined (`Icons.receipt` in side forms vs `receipt_outlined` in main; `Icons.warehouse` vs `warehouse_outlined`); Bit and Hammer both use `hardware` family. | rounded variants, one glyph per category |
| I-G1-16 | Card style | Cards: `Card` default elevation (side lists), bordered `Container` (main/payment/commission). Radius 12 vs 8 for calc rows/type blocks vs 16 for summary cards. | `RigCard` radius `lg` |
| I-G1-17 | Spacing | 8, 12, 16, 24 mixed with 10 (highlight box vertical padding 10 in diesel, 8 in others), 6 and 4 chip paddings; highlight box padding differs (10 diesel, 8 other lists); highlight font 16 diesel vs 14 others; summary item font 16 vs 15. | `RigSpace` scale |
| I-G1-18 | Empty state | Icon 64 dp grey, 16 sp grey message; "Clear Filters" `TextButton` only when filtered. Copy differs per list ("No diesel entries yet", "No PVC entries yet", "No bit entries yet", "No hammer entries yet"; capitalization of PVC only). | `EmptyState` |
| I-G1-19 | Filter UI | Diesel: bunk text. PVC: type chips + storage text. Bit and hammer: type chips. Sheet radius 20, title 18 sp bold, `OutlineInputBorder` forced on fields, Apply colored per category. | `EntryFilterSheet` |
| I-G1-20 | Dropdowns | `DropdownButtonFormField` for agent, depth type, PVC type, MS type, payment receiver: hint vs label differ; menu max height default. | `RigDropdownField` |
| I-G1-21 | Add agent dialog | Main: name + phone, snackbar validation. Side bore: name only, silent empty. Both own no controller disposal. | `RigDialogShell` |
| I-G1-22 | Manual override markers | Total/Step Rate/Commission: `Icons.edit` tooltip icon in `AppColors.warning` + "Auto" `TextButton` (main) vs lock icon toggle "Auto/Manual" label showing state (side bore Total). | one pattern: edit marker + "Auto" action, or `RigSegmented` for side bore |
| I-G1-23 | Desktop width | Forms use `AdaptiveContent(700)`; lists have no max width (stretch on macOS). Design system: 640 forms, 720 lists. | `RigScaffold(maxContentWidth)` |
| I-G1-24 | Back button | Lists: custom white `IconButton(Icons.arrow_back)`, no tooltip; forms: framework back button. | `RigAppBar` leading with tooltip "Back" |
| I-G1-25 | Type-name strings | Main bill form: `'7inch'`, `'8inch'`, `'6inch'` (no space); side ledgers: `'7 inch'`, `'6.5 inch'`, `'MS'`. Stored values differ by screen family. | no token; copy parity only (keep stored strings) |


### A2. Account Ledger


Format: inconsistency - where - resolving token or component.

#### Header
1. Gradient app bar on mobile, white bar with border on desktop, built three ways: `cashAppBar` (widgets/cashbook_common.dart:16-46), `CashHeader` (widgets/cashbook_header.dart:8-58), and a hand-built `AppBar` with gradient `flexibleSpace` in cashbook_all_transactions_screen.dart:58-90 (this one uses the gradient and white text on desktop too, unlike the others). Resolves with `RigAppBar`.
2. Title sizes 18 (desktop) and 20 (mobile) hard-coded in two places (cashbook_common.dart:26, cashbook_header.dart:32). Resolves with `headlineSmall` (20/28).
3. Overflow `PopupMenuButton` without tooltip: entry form (cashbook_entry_form_screen.dart:339), notebook (cashbook_notebook_screen.dart:70), trash (cashbook_trash_screen.dart:89); with tooltip in home (cashbook_home_screen.dart:119). Resolves with `RigMenuButton` (tooltip required).

#### Buttons
4. Primary actions: flat colored `ElevatedButton`s (home 404-422), plain `ElevatedButton` (transfer 151, note form 139, import 192, items dialog uses `TextButton` OK at 194), `OutlinedButton` for Save and exit (entry form 632). Resolves with filled (primary), tonal (secondary), outlined (cancel-like), text (dialogs).
5. Dialog confirm actions are `TextButton` in some dialogs (book dialogs 107, 230; report 119) and `ElevatedButton` in `showCashTextPrompt` (cashbook_common.dart:323). Resolves with `RigDialogShell` (text buttons, primary confirm in `primary`, destructive in `negative`).
6. "ADD ACCOUNT" is an all-caps white `TextButton` in the app bar (cashbook_books_screen.dart:79-84); every other action is Title case. Resolves with `labelLarge` Title case and a tonal "Add account" button plus the row.

#### Cards and rows
7. Entry rows are flat strips (row.dart:68-77), books and notes are `Card`s (books:109, notebook:166), trash and settings are bare `ListTile`s (trash:126, settings:65), all-transactions rows are InkWell + Container with bottom border (all_transactions:136-147). Resolves with `RigCard` / `RigListRow`.
8. Day header band colored `AppColors.divider` (row.dart:18) versus Summary book cards `Card` (summary:49). Resolves with `DayGroupHeader`.
9. Totals strip is a bordered container radius 12 (totals_strip.dart:49-54); notebook stats strip duplicates it with its own container (notebook:133-151). Resolves with one `CashTotalsCard` / `AmountTile` row.

#### Typography
10. Raw sizes in these files: 10 (calendar:138,146), 12 (many), 13 (account_summary:122,158; all_transactions:172), 14 (row icons), 15 (row notes row.dart:94, totals value totals_strip.dart:38, note tile notebook:183, help help:70), 16, 18, 20 (entry form amount, form:461), 22 and 30 (calculator:144,150). Resolves with the type scale (`bodyMedium`, `titleSmall`, `amountLarge`, `displayAmount` is not used here).
11. Column headers "Date", "Income", "Expense" are `w700` default size, with colors #059669/#DC2626 (home:327-350, account_summary:71-100). Resolves with `labelMedium` `onSurfaceVariant` header row.

#### Colors
12. `CashColors.income` #059669 and `CashColors.expense` #DC2626 (widgets/cashbook_common.dart:10-11) differ from the system `moneyIn` #047857 and `negative` #B91C1C; `CashColors.balance` = `AppColors.primary`. Used about 40 times. Resolves with `moneyIn`, `negative`, `primary`.
13. `AppColors.textHint` (#94A3B8) used for empty state text: home:358, summary:42, account_summary:106, all_transactions:124, notebook:125, trash:118. 2.56:1. Resolves with `textMuted` (#6B7280).
14. `AppColors.error` for delete icons and text (books:42, trash:43, items:180, entry form 614-615), `CashColors.expense` for the note form delete button (note_form:130-132). Resolves with `negative`.
15. Calendar today border `AppColors.primary` vs day border `AppColors.border` (calendar:120-122). Resolves with `primary` and `outlineVariant`.

#### Forms and fields
16. Date field styles: custom bordered Row with arrows (entry form 378-422), `CashDateField` InputDecorator (common:164-188), `InkWell + InputDecorator` for time (transfer:129-137, note form 93-102), a bordered container for time in the entry form (form:427-447). Resolves with `RigDateField` and a new `RigTimeField`.
17. Amount fields: `prefixText: 'Rs. '` in entry form (form:465) and transfer (transfer:110), none in opening balance, items rate and quantity. Resolves with `AmountField` (prefix shown only where the field holds money).
18. Dropdowns: `DropdownButtonFormField` with `initialValue` (form:528, transfer:82). Resolves with `RigDropdownField`.
19. No `textInputAction` anywhere in this feature; forms never move focus to the next field. Resolves per form with `next` and `done`.

#### Dialogs and sheets
20. `AlertDialog`, `SimpleDialog`, `showModalBottomSheet` each with default shapes (book dialogs, picker, settings, report, trash, calendar day sheet, calculator sheet). Resolves with `RigDialogShell` and `RigSheet`.
21. Choice dialogs: `SimpleDialog` (settings `_choose`, copy dialog, restore into account, report format) versus bottom sheet (books row menu, trash row menu). Resolves with one `RigChoiceDialog` (dialog on expanded, sheet on compact per DESIGN_SYSTEM 13.4).
22. Snackbars through `showCashSnack` (no duration, no icon, red only for error) versus system `RigSnack`. Resolves with `showRigSnack`.

#### Dates and currency
23. Date patterns on one screen: user setting (rows), 'EEE, MMM dd yyyy' (day header), 'MMM-dd-yyyy -> MMM-dd-yyyy' (range), 'dd MMM yyyy' in the import preview (import:96), calculator-free 'Sun..Sat' labels in the calendar. Resolves with `RigFormat` tokens where no user setting applies and `settings.formatDate` where it does.
24. Currency: "Rs. " everywhere in Account Ledger via `settings.formatMoney`; the rest of the app uses the rupee sign. Open decision (logic_g2.md L-02).

#### Empty and error states
25. Empty text differs per screen ("No transactions", "No notes", "No deleted transactions", "No books found") with no icon; error is a red box only in import (import:124-133). Resolves with `EmptyState` and `ErrorBanner`.

#### Icons
26. Mixed filled, outlined: `Icons.menu`, `Icons.search`, `Icons.chevron_left`, `Icons.arrow_drop_down`, `Icons.date_range` (filled) beside `Icons.copy_outlined`, `Icons.delete_outline`, `Icons.picture_as_pdf_outlined` (outlined) in the same app bars. Resolves with rounded variants only.

#### Layout width
27. `CashPageBody` constrains width only when `PlatformHelper.isDesktop` and with per-screen maxWidth values 600, 700, 800, 900 (home uses the default 900). Android tablets are not constrained. Resolves with `RigScaffold.maxContentWidth` (640 forms, 1100 dashboards) for all platforms.


### A3. Agents, settings, exports, stats and theme


Format: area, what differs, file:line, resolved by.

#### Headers and app bars
- I1 Header styles in this group: agents and settings use `AdaptiveHeader` (gradient on mobile, white bar on desktop) - agents_screen.dart:25, settings_screen.dart:34; about, vehicle management use `AppBar` with gradient `flexibleSpace` - about_screen.dart:28, vehicle_management_screen.dart:171; the three export screens use flat `AppBar(backgroundColor: AppColors.primary)` - pdf_export_screen.dart:210, csv_export_screen.dart:48, csv_import_screen.dart:55; stats uses its own gradient `Container` - stats_screen.dart:66. Resolved by `RigAppBar` (one solid header).
- I2 Title alignment: AdaptiveHeader mobile centers the title, desktop left-aligns, `AppBar` follows the theme (centered). Resolved by `RigAppBar` rule (leading/trailing reserved, one alignment per platform).
- I3 Title sizes: 20 (mobile header), 18 (desktop header, section headings in stats 18), 22 (about name). Resolved by `headlineSmall` 20 for screen titles and `titleMedium` 16 for card titles.

#### Buttons
- I4 Primary actions: `ElevatedButton` (agents dialogs, vehicle dialog, export screens, import stepper), `FloatingActionButton` (agents, vehicles), `TextButton` red/amber (vehicle delete, Drive restore, Drive disconnect) - settings_screen.dart:257 vs 566 vs 523. Resolved by `FilledButton` primary, `negative` text/filled for destructive, one add control per screen.
- I5 Destructive buttons: Restore (file) amber ElevatedButton (settings_screen.dart:257), Restore (Drive) amber TextButton (566), Clear All red ElevatedButton (353), Disconnect red TextButton (523), Delete agent red ElevatedButton (428), Delete vehicle red TextButton `Colors.red` (106). Resolved by `ConfirmDialog` destructive style (`negative`, right side, Cancel left and focused).
- I6 Fixed-height buttons: 50 dp in export screens (pdf_export_screen.dart:267, csv_export_screen.dart:332) versus theme padding-based sizing elsewhere. Resolved by 48 dp min height token.

#### Cards and elevation
- I7 Card styles: shadow `Container` (settings_screen.dart:394, agents_screen.dart:500, export screens, stats 12 places), `Card` with elevation 2 (about_screen.dart:87, vehicle_management_screen.dart:214 with radius 12), bordered boxes (csv_import 165-170). Radii 12 and 16 mixed. Resolved by `RigCard` (level 1, radius lg 16, 1 px `outlineVariant`).
- I8 Shadow recipe repeated verbatim 27+ times (`BoxShadow(color: AppColors.shadow.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))`). Resolved by tonal elevation.

#### Typography
- I9 Section titles: Settings 14 w600 `textSecondary` (settings_screen.dart:192), Stats 18 w600 (stats_screen.dart:237), card titles 16 w600 everywhere, About 14 w700 (about_screen.dart:157). Resolved by `RigSection` (`titleSmall`) and `titleMedium`.
- I10 Sub-11 sp text: 10 sp Paid/Due and "Active" badge (stats_screen.dart:934, vehicle_management_screen.dart:279), 9 sp type subtitle (vehicle_management_screen.dart:523), 11 sp header chips (csv_export_screen.dart:318). Resolved by `labelSmall` 11 floor and 12 sp for chart labels.
- I11 Amount styles: no tabular figures, plain `Text` in cards, `FittedBox` only in `_SummaryCard` (stats_screen.dart:1394). Resolved by `AmountText`.

#### Color
- I12 Status colors as text: success/warning/error as text colors (stats_screen.dart:942, 961; pdf summary; csv import chips). Resolved by `moneyIn`/`outstanding`/`negative` text-safe tones.
- I13 Category colors differ between the mini chart and the detail card: Diesel amber vs primary (stats_screen.dart:710 vs 1006), PVC primary vs accent (737 vs 1067). Resolved by `categoryDiesel/Pvc/Bit/Hammer`.
- I14 Raw material colors: `Colors.red/orange/blue/green/grey` in vehicle_management_screen.dart (53-60, 77-83, 236-294, 449-459, 498-525). Resolved by role tokens.
- I15 Hint colors: `AppColors.textHint` (2.56:1) in agents (50, 65), about (59), stats (544, 558, 849), csv import (261, 280). Resolved by `textMuted`.

#### Forms, dropdowns, dialogs
- I16 Date field: pdf/csv/stats each hand-build a bordered `InkWell` box (pdf_export_screen.dart:419-489, csv_export_screen.dart:171-241, stats_screen.dart:316-373, with no border at all in stats); the vehicle dialog uses `OutlineInputBorder`; theme says filled. Resolved by `RigDateField`.
- I17 Text fields in dialogs: agent dialog fields use theme decoration with prefix icons (agents_screen.dart:123-152), vehicle dialog adds explicit `border: OutlineInputBorder()` (vehicle_management_screen.dart:420-424), rate fields have no prefix. Resolved by `RigTextField`.
- I18 Dropdowns: `DropdownButtonFormField` with `isDense` and custom border radius 8 in import mapping (csv_import_screen.dart:265-275) versus default decoration in the agent reassign dropdown (agents_screen.dart:384-389). Resolved by `RigDropdownField`.
- I19 Dialog actions: Cancel/primary order the same everywhere, but destructive default focus and widths differ; vehicle dialog uses `AlertDialog` with Form, agents use `SingleChildScrollView`, no max widths. Resolved by `RigDialogShell`.
- I20 Selection controls: type selector as `GestureDetector` pills (pdf/csv export, vehicle type tiles), `FilterChip` for columns, `SwitchListTile` for export-all, `RadioListTile` for delete choice, `ChoiceChip` nowhere. Resolved by `RigChipRow`/`RigSegmented`.

#### Formats
- I21 Currency: `₹` + `NumberFormat('#,##0.00')` (agents_screen.dart:595, stats_screen.dart:466 and 5 more), `Rs.` + same format in export summary (pdf_export_screen.dart:675), `toStringAsFixed(2)` without grouping in csv import preview (csv_import_screen.dart:436). Resolved by `RigFormat.money/plain` (PDF/CSV content stays frozen).
- I22 Dates: `dd MMM yyyy` (pdf/csv/stats range), `MMM d, yyyy` (settings last backup, settings_screen.dart:636), `yyyy-MM-dd` (pdf column, import preview `toString().split(' ')[0]`). Resolved by `RigFormat.dateShort`; storage and file name formats unchanged.
- I23 Default scope: CSV export defaults to all entries (csv_export_screen.dart:36), PDF export defaults to last 30 days (pdf_export_screen.dart:53). Resolved by an explicit scope sentence in both.
- I24 "Pending" (stats Ledger tab, stats_screen.dart:506) versus "Balance" (ledger list, PDF). Business label Balance keeps its meaning; flagged for developer confirmation.

#### States and feedback
- I25 Empty states: agents (icon 64, 18 sp), vehicles (icon 64 grey), stats By Agent (icon 48), mini charts ("No data" text), detail cards (row text), export zero entries (amber box in PDF, nothing in CSV). Resolved by `EmptyState`.
- I26 Snackbars: success `AppColors.success`, error `AppColors.error`, warning `AppColors.warning`, `Colors.orange` and none (default) in vehicle management (53-59 vs 134-136) and agents (167 default vs 199 success). Resolved by `showRigSnack`.
- I27 Loading indicators: full-card spinner (Drive card, settings_screen.dart:690), leading spinner replacing icon (766, 786), in-button spinner (export), none (clear all, restore file, import read). Resolved by `ProgressDialog` for blocking work and in-button spinners for local work.
- I28 Icon styles: `_outlined` (agents, settings, about), filled `Icons.add`, `Icons.edit`, `Icons.delete` (vehicle menu, 315-325), `Icons.warning` vs `Icons.warning_amber_rounded`. Resolved by the rounded-only rule.
- I29 Tap target and hover: whole-card tap on agents and vehicles, but additional icon buttons duplicate edit; no hover or context menu on macOS. Resolved by card tap + overflow menu + secondary click.
- I30 Max widths: about 700 (about_screen.dart:36), form pages 800 (`AdaptiveContent`), settings/agents/export none. Resolved by `RigScaffold.maxContentWidth` (640 forms, 720 settings and export, 1100 dashboards).


## Resolution status (2026-10-13, Apple look, Android only)

Status: PLANNED (a task will apply it), RESOLVED BY DESIGN (the new token or component removes the cause; the task still has to adopt it), DROPPED (macOS or desktop, frozen), N/A (no longer true under the new direction).

| ID | Resolved by (new) | Task | Status |
|---|---|---|---|
| I-01 failing text colours | `moneyInText`, `outstandingText`, `moneyOutText`, `commissionText`, `lb2`, contrast test (TOKENS.md section 5) | T-F02, then screen tasks | PLANNED |
| I-02 white text on gradient end | flat canvas, no gradient header | T-F10, T-S04 | RESOLVED BY DESIGN |
| I-03 raw named colours | `RigColors` roles and category tokens | T-F02, every T-S task (grep check) | PLANNED |
| I-04 hex literals outside tokens | `RigColors` | T-F02, T-S43x | PLANNED |
| I-05 snackbar colour sources | `RigSnack` | T-F09 | PLANNED |
| I-06 balance green at zero or credit | Balance tone rule in the bill row | T-S03 | PLANNED |
| I-07 unused palette entries | deleted with the old theme | T-P03 | PLANNED |
| I-10 16 font sizes | Inter type scale, 11 sp floor | T-F01 | PLANNED |
| I-11 inline TextStyles | `RigTheme` text styles | T-F01, T-F03 | PLANNED |
| I-12 no tabular figures | Inter plus `FontFeature.tabularFigures` on every amount style | T-F01, T-F06 | PLANNED |
| I-13 system font per platform | Inter bundled (Android only now) | T-F01 | PLANNED |
| I-14 title size differs | `LargeTitleScaffold` 34 and 17 | T-F10 | PLANNED |
| I-15 amount sizes | `MoneyText` styles | T-F06 | PLANNED |
| I-20 twelve radii | `RigRadius` card 20, sheet 28, alert 14, pill | T-F07, T-F09 | PLANNED |
| I-21 28 padding forms | margin 20, gap 12, `RigSpace` | T-F07 | PLANNED |
| I-22 card elevation recipes | `RigCard` (light shadow only, none in dark, no list shadows) | T-F07 | PLANNED |
| I-23 content width | single compact width class, 360 dp floor; no max width logic | n/a | N/A |
| I-24 FAB bottom padding | list padding = tab bar + inset + 24 | T-F10, T-F11 | PLANNED |
| I-30 five header recipes | `LargeTitleScaffold` | T-F10, all T-S tasks | PLANNED |
| I-31 Account Ledger looks different | shared tokens and components | T-S30 to T-S34 | PLANNED |
| I-32 two pill tab bars | `RigSegmented` | T-F08, T-S04, T-S20 | PLANNED |
| I-33 period chip sets differ | `RigChipRow`, Ledger tab order everywhere (answer 5; Account Ledger keeps All, Daily, Weekly, Monthly, Yearly because they are different periods) | T-F08, T-S04, T-S20 | PLANNED |
| I-34 clipped chips | `RigChipRow` fade edge and scroll into view | T-F08 | PLANNED |
| I-35 tab label differs by platform | one label set | T-S01 | PLANNED |
| I-36 M2 bottom nav | `RigTabBar` | T-F11, T-S01 | PLANNED |
| I-37 two rig switchers | `RigRigSheet` and one `switchRig`; "Rig" wording | T-S04, T-S20, T-X10 | PLANNED |
| I-40 button variants | `RigButton` | T-F08 | PLANNED |
| I-41 100 InputDecoration blocks | `RigFormRow` | T-F07 | PLANNED |
| I-42 dropdown variety | `RigFormRow` host plus `RigSheet` pickers | T-F07, T-F09 | PLANNED |
| I-43 date field per file | `DatePickerSheet` (bounds from callers, clamp) | T-F09 | PLANNED |
| I-44 keyboards | `RigFormRow` defaults | T-F07 | PLANNED |
| I-45 validation timing | form-level autovalidate after first submit | T-S10 and form tasks | PLANNED |
| I-50 dialogs and sheets | `RigAlertDialog`, `RigSheet` | T-F09 | PLANNED |
| I-51 destructive confirms | `RigAlertDialog` (destructive in `moneyOutText`, cancel focused) | T-F09 | PLANNED |
| I-52 snackbar behaviour | `RigSnack` | T-F09 | PLANNED |
| I-53 empty states | `EmptyState` | T-F09 | PLANNED |
| I-54 error states | `ErrorBanner` (sync, import, export only; list loading has no failure path, LR-34) | T-F09 | PLANNED |
| I-55 loading states | `Skeleton` first frame only | T-F09 | PLANNED |
| I-60 currency formats | `RigFormat.money` (rupee sign, en-IN, paise only when present); exports keep their own | T-F05 | PLANNED |
| I-61 eleven date patterns | `dRow`, `dGroup`, `dFull`, `dMonth` | T-F05 | PLANNED |
| I-62 range label | one range formatter (same day collapses; "to") | T-F05 | PLANNED |
| I-63 feet formats | `ftq` with the one-decimal rule | T-F05 | PLANNED |
| I-64 formatters built in build | static cached `RigFormat` | T-F05 | PLANNED |
| I-65 unit spacing | `ftq` ("350 ft") | T-F05 | PLANNED |
| I-70 icon styles | rounded set only | all T-S tasks | PLANNED |
| I-71 one concept, several icons | `CategoryTile` and `RigRigSheet` icon map | T-F12, T-S05 | PLANNED |
| I-72 list rows | `RigGroup` plus `RigRow` | T-F07 | PLANNED |
| I-73 targets under 48 dp | 48 dp rule in every component | T-F07, T-F08 | PLANNED |
| I-74 custom widgets without focus or semantics | `RigSegmented`, `RigRow`, `RigTabBar` use Material ink and semantics | T-F07, T-F08, T-F11 | PLANNED |
| I-80 platform checks for layout | single compact layout; `PlatformHelper.isDesktop` branches stay in frozen code | n/a | DROPPED |
| I-81 sheet versus dialog by platform | `RigSheet` for input, `RigAlertDialog` for confirms, always | T-F09 | RESOLVED BY DESIGN |
| I-82 `isDesktop` includes Windows and Linux | frozen with macOS (Q-O9) | n/a | DROPPED |
| I-83 keyboard hints | macOS shortcuts out of scope | n/a | DROPPED |

For the audit sections A1 (forms and side ledger), A2 (Account Ledger) and A3 (agents, settings, exports, stats and theme): every row's "resolved by" component maps through the old-to-new name table in COMPONENTS.md section 0; rows about sidebars, desktop widths, hover and macOS shortcuts are DROPPED; rows about gradient headers, borders and shadows are RESOLVED BY DESIGN by the flat canvas and `RigCard`; the screen task that adopts the component marks the row PLANNED to DONE in the commit body.
