> RECONCILED 2026-10-13. The visual direction is now the approved Apple-inspired Android mockup (mockup/rigledger_apple_mockup.html). Android only, portrait phone, light and dark. Decisions: DESIGN_DIRECTION_APPLE.md section 7. Values: mockup/TOKENS.md. Each section below carries a status tag (KEPT, CHANGED, DROPPED) and section R at the end lists the new values. Where an old value conflicts with TOKENS.md, TOKENS.md wins. macOS and desktop content is DROPPED (frozen code, not edited).

# RigLedger Design System (proposal)

Status: specification only. No code was changed. Every value below is a proposal for approval.
Brand status: logo and brand colors are PENDING. The seed color #315D9A is PROVISIONAL (it is today's `AppColors.primary`). The app name RigLedger does not change.

Evidence base: `lib/core/theme/app_colors.dart`, `app_theme.dart`, grep counts across `lib/` on 2026-10-12, and emulator screenshots (kept in docs/design/ref, ignored by git).

## 1. Design direction  [KEPT (rules 1 to 3) plus rule 4, see R1]

Calm, trustworthy, data-first, professional finance tool for a field business. Three rules drive every decision:

1. Numbers are the product. Amounts get the largest, most stable, tabular type and never clip.
2. One component per job. A header, a card, a chip, a dialog looks and behaves the same on every screen.
3. Color carries meaning, not decoration. Green means money in, amber means outstanding, red means negative or destructive. Brand color is for navigation and primary actions only.

Current state that this fixes (full list in INCONSISTENCIES.md): 12 different corner radii, 16 font sizes (including 8, 9, 10 and 11), 28 distinct EdgeInsets forms, raw `Colors.red/green/blue/orange/purple/brown/grey` in about 150 places, three currency formats, eleven date formats, and a mobile header that spends 285 of 900 logical pixels (about 32 percent) before any content.

## 2. Token architecture (how one seed color updates the whole app)  [CHANGED: hand-built light and dark schemes plus RigColors, one accent token, see R2]

All color is read through semantic roles. No widget reads a hex value or a `Colors.x` name.

- `RigTheme.fromSeed(Color seed)` builds a `ColorScheme` with `ColorScheme.fromSeed(seedColor: seed, dynamicSchemeVariant: DynamicSchemeVariant.fidelity)` so `primary` stays the seed itself, then overrides the roles in section 3 that must keep a fixed meaning.
- `RigColors` is a `ThemeExtension<RigColors>` holding the semantic money roles (moneyIn, outstanding, negative, commission, info, and their containers) so screens call `context.rig.moneyIn`, never a literal.
- `RigSpace`, `RigRadius`, `RigMotion`, `RigType` are `const` classes (no allocation per build).
- Changing the brand: change ONE value (`kBrandSeed`) and the app bar, primary buttons, selected chips, tab indicator, focus ring, charts (first series) and the nav indicator all follow. Semantic money colors do not follow the seed, by design, because their meaning must not change when the brand changes.
- Dark mode: tokens are defined as light/dark pairs in section 3 so it can be added later. It is NOT part of this revamp unless approved (CONVENTIONS.md says light only). See final question in the questions list.

## 3. Color roles (light)  [CHANGED: TOKENS.md section 2 replaces 3.2 and 3.3; 3.1 findings stay as history]

Contrast ratios computed with the WCAG 2.x relative luminance formula (2026-10-12). AA needs 4.5:1 for text under 18 sp (3:1 for large text and icons).

### 3.1 Findings on today's palette

| Current color | Hex | On white | Verdict |
|---|---|---|---|
| success (green text) | #10B981 | 2.54 | FAILS AA, used for Received amounts |
| warning (amber text) | #F59E0B | 2.15 | FAILS AA, used for Balance amounts |
| error | #EF4444 | 3.76 | FAILS for small text |
| info | #3B82F6 | 3.68 | FAILS for small text |
| accent (commission teal) | #0490B6 | 3.70 | FAILS for small text |
| textHint | #94A3B8 | 2.56 | FAILS (placeholder and caption text) |
| textSecondary | #64748B | 4.76 | passes |
| primary | #315D9A | 6.64 | passes |
| white on gradient stop 3 | #618DCE | 3.38 | fails for 14 sp text; the 80 percent white subtitle over this stop is about 2.7 |
| border | #E2E8F0 | 1.23 | decorative only, acceptable for dividers, not for input borders (needs 3:1) |

### 3.2 Proposed roles

| Token | Light value | Use | Ratio on surface (white) |
|---|---|---|---|
| `brandSeed` (PROVISIONAL) | #315D9A | single source for brand | 6.64 |
| `primary` | seed | primary buttons, selected chip, links, active nav | 6.64 |
| `onPrimary` | #FFFFFF | text on primary | 6.64 |
| `primaryContainer` | #E3ECF8 (seed tint, tone 92) | selected tile, tonal chip, banner | text #1F3F6B 8.89 |
| `headerSurface` | seed (flat) | mobile top bar | white text 6.64 |
| `headerGradient` (optional, see Q-Brand) | stops: seed darkened to tone 25 (#252B49 today) then seed | top bar only; never use stop #618DCE with text | 13.81 and 6.64 |
| `background` | #F8FAFC | scaffold | n/a |
| `surface` (level 0) | #FFFFFF | cards, sheets, dialogs | n/a |
| `surfaceContainer` (level 1) | #F1F5F9 | summary strips, input fill when disabled, table header | n/a |
| `surfaceContainerHigh` (level 2) | #E8EDF4 | pressed state, selected row on desktop | n/a |
| `onSurface` | #1A1A2E | primary text | 17.06 |
| `onSurfaceVariant` | #566275 | secondary text | 6.18 |
| `textMuted` | #6B7280 | captions, hints, disabled labels (replaces #94A3B8) | 4.83 |
| `outline` | #8A97A8 | input borders, checkbox edge (3:1 for UI components) | 3.1 |
| `outlineVariant` | #E2E8F0 | card borders, dividers | 1.23 (decorative) |
| `moneyIn` | #047857 | Received, Income, positive totals | 5.48 |
| `outstanding` | #9A4A06 | Balance, Pending, due amounts | 6.26 |
| `negative` | #B91C1C | Expense, negative balance, destructive text | 6.47 |
| `commission` | #0B6E87 | Commission figures (not part of total) | 5.84 |
| `info` | #1D5FBF | informational banners, links in dialogs | 6.10 |
| `warning` (non-text fill) | #F59E0B | badges, filter-active dot (never as text) | 2.15, fill only with dark text 10.1 |
| `moneyInContainer` | #E6F4EE | tonal chip and tile behind moneyIn text | text 4.84 |
| `outstandingContainer` | #FDF0E1 | behind outstanding text | text 5.58 |
| `negativeContainer` | #FBE9E9 | behind negative text, error banners | text 5.53 |
| `scrim` | black 32 percent | modal barrier | n/a |

Rules:
- A semantic money color is used for the figure and its small icon only. Labels stay `onSurfaceVariant`.
- Total keeps the `primary` color (Total is neutral, not an outcome). Received = moneyIn, Balance = outstanding, Commission = commission. The business meaning and label text of Balance, Less, Received, Step Rate are not changed.
- Category colors for the side ledger (Diesel, PVC, Bit, Hammer; today amber, blue, green, brown #8B4513) become `categoryDiesel`, `categoryPvc`, `categoryBit`, `categoryHammer` tokens, each with a text-safe tone (>= 4.5) and a container tone. They are identity colors for icons and tiles, not status colors.
- Chart series colors come from `chartSeries[0..7]`, derived from the seed plus fixed hues (section 13).
- Replace every `Colors.red`, `Colors.green`, `Colors.blue`, `Colors.orange`, `Colors.purple`, `Colors.brown`, `Colors.grey(.shadeN)`, `Colors.indigo`, `Colors.teal`, `Colors.cyan` and the 7 `Color(0x...)` literals outside `app_colors.dart` with a role above (list in INCONSISTENCIES.md I-03).

### 3.3 Dark proposal (not scheduled)

| Role | Dark value |
|---|---|
| background | #0F141B |
| surface level 0 / 1 / 2 | #151B24 / #1B2330 / #232D3C |
| onSurface / onSurfaceVariant / textMuted | #E6EAF0 / #B4BECC / #8E9AAD |
| primary | seed tone 80 (about #A9C4EE), onPrimary #0B2447 |
| moneyIn / outstanding / negative / commission | #4CC79A / #F0B25A / #F08A8A / #5CC3DC |
Contrast to be re-verified with the same script before approval.

## 4. Typography  [CHANGED: Inter 400/500/600/700, see R3]

One bundled family, no runtime font download. Today the UI uses the platform default (Roboto on Android, SF on macOS), so digit widths and line heights differ between platforms. Proposal: bundle one family and set it as `ThemeData.fontFamily`.

- Candidate: Noto Sans (already bundled as `assets/fonts/NotoSans-Regular.ttf` with OFL notice, used for PDFs; Noto Sans Tamil is already the Tamil fallback). Add weights 500 and 600 only (about 2 files). Acceptance: a test render proves `FontFeature.tabularFigures()` works in the chosen files; if not, choose another OFL family with tabular figures (Q-Brand).
- Minimum size 11 sp. Today there are sizes 8 (5 uses), 9 (7), 10 (16) that fail the readability floor.

### 4.1 Scale (sp / line height / weight)

| Token | Size / LH | Weight | Replaces today | Use |
|---|---|---|---|---|
| `displayAmount` | 28 / 36 | 700, tabular | 24, 30, 32 | portfolio hero profit |
| `headlineSmall` | 20 / 28 | 600 | 20, 22 | screen title (mobile app bar, desktop header 18 -> 20) |
| `titleMedium` | 16 / 24 | 600 | 16, 18 | card title, section title, agent name |
| `titleSmall` | 14 / 20 | 600 | 14 w600 | group header, table header |
| `bodyLarge` | 16 / 24 | 400 | 16 | form input text |
| `bodyMedium` | 14 / 20 | 400 | 13, 14, 15 | list body |
| `bodySmall` | 12 / 16 | 400 | 11, 12 | captions, helper text |
| `labelLarge` | 14 / 20 | 500 | 14 w500 | buttons, chips, tabs |
| `labelMedium` | 12 / 16 | 500 | 12 w500 | field labels, badge text |
| `labelSmall` | 11 / 16 | 500 | 8, 9, 10 | bottom-nav label, tiny meta (floor) |
| `amountLarge` | 20 / 28 | 600, tabular | 18, 20 | card total, balance |
| `amountMedium` | 16 / 24 | 600, tabular | 16 | summary values, row amounts |
| `amountSmall` | 14 / 20 | 500, tabular | 12, 14 | secondary amounts, group totals |

Rules: every amount style sets `fontFeatures: [FontFeature.tabularFigures()]`. Text never sits in a fixed-height box (text scale up to 200 percent, section 15).

## 5. Spacing (4 pt grid)  [CHANGED: margin 20, gap 12]

`RigSpace`: `s0=0, s1=4, s2=8, s3=12, s4=16, s5=20, s6=24, s8=32, s10=40, s12=48`.
- Screen horizontal padding: 16 (compact), 24 (medium), 32 (expanded, content also capped at max width).
- Card inner padding: 16; dense card (list row): 12.
- Gap between cards: 8 (list) or 12 (dashboard grid).
- Section gap: 24.
- Replace the odd values 6, 10, 14 (used 4 + 3 + 4 times as EdgeInsets) with the nearest scale step.

## 6. Radii  [CHANGED: card 20, sheet 28, alert 14, tile 28, pill full]

`RigRadius`: `xs=4` (tiny badges), `sm=8` (chips, snackbars, menus), `md=12` (inputs, buttons, tiles), `lg=16` (cards), `xl=24` (bottom sheet top corners, dialogs), `full=999` (pills, tab indicator, drag handle).
Mapping from today (count): 12 (68) -> md, 16 (46) -> lg, 8 (29) -> sm, 20 (20) -> xl, 6 (8) -> sm, 4 (8) -> xs, 10 (5) -> md, 25 (4) -> full, 2 (4) and 3 (1) -> full, 18 (1) -> lg.

## 7. Elevation (tonal, not shadow)  [CHANGED: no borders in dark, soft shadow in light only, glass bars off by default]

| Level | Fill | Border | Shadow | Use |
|---|---|---|---|---|
| 0 | background | none | none | scaffold |
| 1 | surface | 1 px outlineVariant | none | cards, list rows, summary tiles |
| 2 | surfaceContainer | none | none | strips, table headers |
| 3 floating | surface | none | one soft shadow (blur 8, y 2, black 10 percent) | FAB, popup menu, dialog, sheet |

Why: today's cards use `elevation: 2` plus extra `BoxShadow(blur 10)` in about 27 places; blurred shadows in long lists cost raster time (PERFORMANCE.md) and make cards look heavier than the data they hold.

## 8. Motion  [KEPT plus press feedback by ink and reveal animations]

| Token | Value | Use |
|---|---|---|
| `fast` | 150 ms | state change (chip select, ripple settle, icon swap) |
| `base` | 200 ms | expand/collapse, header slide, sheet content |
| `slow` | 300 ms | route and sheet entrance |
| `curveEnter` | `Curves.easeOutCubic` | things appearing |
| `curveExit` | `Curves.easeInCubic` | things leaving |
| `curveStandard` | `Curves.easeInOutCubic` | moves within the screen |

Honor reduced motion: when `MediaQuery.disableAnimationsOf(context)` is true, durations become zero and the collapsing header snaps. No motion longer than 300 ms. No parallax, no bounce on data screens.

## 9. Iconography  [KEPT]

- Built-in `Icons` class, rounded variants (`Icons.account_balance_wallet_rounded`). Today: 94 `_outlined`, 4 `_rounded`, the rest are default filled. One style app-wide removes the mixed look. Each rounded variant must exist at implementation time (compile check); where one does not, use the closest rounded glyph, never a different style. No new icon package.
- Sizes: 16 (inline with 12 to 14 sp text), 20 (inside buttons, list leading, chips), 24 (app bar, nav, default), 48 (empty-state illustration; today 64 in 7 places).
- Colors: `onSurfaceVariant` by default, semantic role only when the icon repeats the meaning of the figure beside it.
- Active nav icon: filled rounded; inactive: rounded outline is not available in `Icons`, so use `Icons.x_rounded` for both and show state through the M3 indicator pill plus color.
- No emoji glyphs anywhere, including snackbar and empty-state text.

## 10. Money, numbers, dates  [CHANGED: TOKENS.md section 7 formatter rules; rupee sign, en-IN, paise only when present]

### 10.1 One formatter (`RigFormat`)

Today: `NumberFormat('#,##0.00')` (14 places, western grouping, symbol hard-coded as a string) vs `NumberFormat.currency(locale: 'en_IN', symbol: '₹')` (9 places) vs `Rs.` text in Account Ledger and PDFs.

| Function | Output example | Use |
|---|---|---|
| `money(v)` | `₹1,27,000.00` | everywhere an amount is shown in full (Indian lakh grouping if approved, Q-Brand) |
| `moneyCompact(v)` | `₹1.27 L`, `₹3.4 Cr`, `₹12.5 K` | only inside space-limited highlights, with the full value on tap or long press |
| `moneySigned(v)` | `-₹4,500.00` | negative values; minus sign, never parentheses, `negative` color |
| `feet(v)` | `1,250 ft` (`1,250.5 ft` when fractional) | depth, PVC, MS pipe |
| `plain(v)` | `1,27,000.00` | table cells where the column header holds the unit |
Instances are `static final`, created once (PERFORMANCE.md). Rounding and values are untouched: the formatter only formats a `double` that the existing providers produce. PDF and CSV content is NOT changed (Logic freeze: export content).

### 10.2 Alignment

- Amounts in tables and rows are right-aligned with tabular figures so decimals line up.
- Zero renders `₹0.00` in `textMuted` in lists, in the semantic color in highlights.
- Negative amounts keep the sign and use `negative`.

### 10.3 Dates (one set)

| Token | Pattern | Use |
|---|---|---|
| `dateShort` | `dd MMM yyyy` (12 Oct 2026) | cards, forms, ranges |
| `dateGroup` | `EEE, dd MMM yyyy` (Mon, 12 Oct 2026) | list day headers |
| `monthTitle` | `MMMM yyyy` | month navigation |
| `timeShort` | `h:mm a` or `HH:mm` per Account Ledger setting | Account Ledger rows (setting preserved) |
| range | `12 Oct 2026 - 18 Oct 2026`; same day collapses to one date | all range labels |
Today there are 11 patterns including `dd/MM/yyyy` (12), `MMM-dd-yyyy`, `MMM d, yyyy`, `EEE, MMM dd yyyy`. The Account Ledger date format is a user setting (cashbook settings); the setting stays, and its default aligns to `dateShort`. Storage and file-name formats (`yyyyMMdd`, `yyyy-MM-dd`) are unchanged.

## 11. Components, in brief (full catalogue in COMPONENTS.md)  [CHANGED: new component names, see COMPONENTS.md]

- App bar: one `RigAppBar` (mobile: flat `headerSurface`, 56 dp, title 20 sp; desktop: 48 dp surface with bottom border). Replaces `AdaptiveHeader` (used by 2 screens), 14 hand-built gradient `Container` headers and 20 `AppBar(...)` variants.
- Buttons: filled (primary action, one per screen), tonal (secondary), outlined (cancel-like), text (dialog actions, inline). Min height 48 on mobile, 40 on desktop with pointer. Radius md. Today: 35 `ElevatedButton`, 57 `TextButton`, 0 `FilledButton`; Account Ledger uses flat colored Income/Expense buttons that match neither.
- Cards: level 1, radius lg, padding 16.
- Chips: `ChoiceChip` for single-select period/filter chips, `FilterChip` for multi, height 32 visual, 48 hit target, scrollable row with fade edge so a clipped chip is obvious (today "All" is cut to "Al" in Portfolio and Side Ledger).
- Snackbars: floating, radius sm, background `inverseSurface`, a leading semantic icon (success, error), 4 s, action when undoable. Today 10 use `Colors.red`, 14 use `AppColors.error`, 12 use `AppColors.success`, 0 set a duration.

## 12. Forms  [CHANGED: forms are full-height sheets with inset grouped rows]

- Field: outlined, filled with surface, radius md, 56 dp, label floats, helper text slot reserved (no layout jump on error). One `RigTextField` / `RigDropdownField` / `RigDateField` / `RigAmountField` set (COMPONENTS.md).
- Order: identity (date, bill no, agent) -> work (depth, rates) -> money (total, payments) -> notes. Keep each form's existing field order unless a screen doc says otherwise; the parity checklist pins it.
- Keyboard: amounts `TextInputType.numberWithOptions(decimal: true)`, phone `phone`, names `TextCapitalization.words`, notes `sentences`; `textInputAction.next` through the form, `done` on the last. (UI-only; validators untouched.)
- Validation timing: `AutovalidateMode.onUserInteraction` after the first submit attempt. The validator functions are untouched.
- Sticky primary action: Save bar pinned at the bottom (`SafeArea`), above the keyboard (`resizeToAvoidBottomInset`), so Save is reachable on long forms.
- Desktop forms: centered, max width 640, two-column grid for short numeric fields at expanded width.
- Dropdowns: replace the 14 `DropdownButtonFormField` with the same decorated field; on desktop the menu is capped at 320 high.

## 13. Lists, charts, states  [CHANGED: inset groups, sticky day headers, RowActions]

### 13.1 List row anatomy
`[leading 40 icon or avatar] [title 16 w600 / subtitle 12 muted] [trailing amount 16 tabular right]`, min height 56 dp (72 for two-line rows), 16 horizontal padding, divider inset 72, whole row is the tap target, press state `surfaceContainerHigh`. Swipe actions are not added (no new behavior).

### 13.2 Charts (fl_chart ^0.66)
- Series colors from `chartSeries`, max 6 slices then "Other" only if the existing data already groups so (no logic change; otherwise unchanged).
- Labels outside the plot, 12 sp `onSurfaceVariant`, values formatted by `RigFormat`.
- No gradient fills, no shadows, grid lines `outlineVariant` at 1 px, touch tooltip `inverseSurface`.
- Always show the legend as text rows (color chip plus label plus value) so color is never the only signal.

### 13.3 Empty, loading, error
| State | Pattern |
|---|---|
| Empty | 48 dp icon (muted), titleMedium message, bodySmall hint, optional tonal button for the primary create action. One `EmptyState` widget. Today the copy and icon size differ per screen. |
| Loading | skeleton rows for lists with more than 200 ms latency; inline `CircularProgressIndicator` (24 dp) in buttons; sync shows the existing status chip. |
| Error | inline `ErrorBanner` (negativeContainer) with message and Retry where a retry exists; transient errors use a snackbar. Never a silent failure (CONVENTIONS.md). |

### 13.4 Dialog versus bottom sheet versus page
- Confirm and destructive: dialog (max 400 wide), destructive action is a text button in `negative`, cancel on the left, never the default focus.
- Pick one of N, filters, quick add: bottom sheet on compact; on expanded width the same content opens as a dialog or popover (max 560).
- More than 3 fields, or anything with a Save that can fail validation: full page route.
- Date picking: `showDatePicker` styled by theme (compact), dialog on desktop (see B2 in screens/accounts_home.md).

## 14. Navigation  [CHANGED: floating RigTabBar, no sidebar]

- Mobile: Material 3 `NavigationBar`, 5 destinations (Ledger, Portfolio, Agents, Accounts, Settings), 80 dp, labels always visible, indicator pill `primaryContainer`. Replaces `BottomNavigationBar` wrapped in a shadow `Container`. FAB only on Ledger, positioned above the bar, hidden while the collapsing header is hidden is NOT required (see HIGHLIGHTS_AND_COLLAPSE.md).
- macOS: custom title bar (52 px today) plus sidebar; sidebar width 220 expanded, 72 collapsed below 1000 px window width; selected item uses `primaryContainer`; keyboard hints stay (Cmd+1..5, Cmd+N, Cmd+S). Rig switcher stays in the title bar and is reused by Portfolio (B1).
- Window: min 900 x 600 (unchanged). Content max width 1100 for dashboards, 640 for forms.

## 15. Desktop density and behavior  [DROPPED (macOS out of scope, frozen)]

- `VisualDensity.compact` on desktop only; hit targets 40 dp minimum with pointer.
- Hover: rows and cards show `surfaceContainerHigh`; clickable text shows pointer cursor (`SystemMouseCursors.click`).
- Focus: visible 2 px `primary` focus ring on all focusable controls; Tab order follows reading order; Esc closes dialogs and sheets; Enter submits single-field dialogs.
- Context menu: right-click on a ledger row offers Edit, Duplicate (only if it exists today), Delete (same actions as the existing row menu; no new actions).
- Scrollbars always visible on desktop for long lists.

## 16. Accessibility  [KEPT plus the AA text-variant rule and 48 dp targets]

- Text scale: every screen must lay out at 100, 130 and 200 percent without overflow or clipping (stress table in HIGHLIGHTS_AND_COLLAPSE.md). Use `TextScaler`-aware minimum heights, never fixed height around text.
- Tap targets 48 x 48 dp on mobile; chips and icon buttons use `MaterialTapTargetSize.padded`.
- Contrast: section 3 roles meet 4.5:1 for text; icons and input borders meet 3:1.
- Semantics: amounts carry `semanticsLabel` with the full plain value ("one lakh twenty seven thousand rupees" is not required; "127000 rupees" is acceptable); compact values announce the full value; icon-only buttons have `tooltip`; the collapsing header exposes a `Semantics(button, label: 'Show filters')` reveal control.
- Color is never the only signal: Received/Balance/Expense also carry their text labels and, in tables, a sign or column.
- Focus order and screen reader order follow visual order on both shells.

## 17. Token to code map (for MIGRATION_PLAN foundation tasks)  [CHANGED: see R4]

| New | Replaces |
|---|---|
| `lib/core/theme/rig_tokens.dart` (space, radius, motion) | scattered numeric literals |
| `lib/core/theme/rig_colors.dart` (ThemeExtension) | `AppColors` semantic part; `AppColors` kept as a thin alias during migration |
| `lib/core/theme/rig_theme.dart` | `AppTheme.lightTheme` |
| `lib/core/format/rig_format.dart` | 33 `NumberFormat` and 39 `DateFormat` constructions |
| `lib/core/widgets/rig/*` | see COMPONENTS.md |

## R. Reconciliation with the Apple-inspired Android direction (2026-10-13)

### R1. Design direction rule 4
"Apple-inspired look on Android: large titles, inset groups, floating bars; Android behaviour (insets, system back, 48 dp targets, ink ripple, keyboard handling)." Rules 1 to 3 stand: numbers are the product, one component per job, colour carries meaning.

### R2. Token architecture
- Two hand-built `ColorScheme`s (light, dark) plus `ThemeExtension<RigColors>`; NOT `ColorScheme.fromSeed`. Mapping table: TOKENS.md section 6.
- ONE accent: `RigColors.accent`, `accentText`, `accentButton`, `onAccent`, `accentTint`. Default system blue (#007AFF light, #0A84FF dark). #315D9A is a documented alternate. A new logo or brand colour is a ONE-token change (the five accent roles derive from one source `Color`).
- `ThemeMode.system` by default; Appearance setting System, Light, Dark stored in the Hive settings box (LR-23, LR-35), no schema bump.
- Glass tokens (`glass`, `glassBar`, `bar`, `scrim`) exist, but the blur flag defaults OFF: bars use `barSolid` (94 percent surface plus hairline). `BackdropFilter` is only ever applied to the tab bar and the collapsed header, never inside scrolling content.
- Gradient entries (`appBarGradient`, `primaryGradient`, `cardGradient`, `gradient1..5`) are deleted at the end; the only gradients left are the Side Ledger category tiles (category colour to 62 percent white).

### R3. Typography
Inter 400, 500, 600, 700 (OFL notice kept) with `FontFeature.tabularFigures()` on every amount style; Noto Sans only for PDFs; Noto Sans Tamil stays the Tamil fallback. Scale (TOKENS.md section 4): t34 bold large title, t28, t22 bold, t20, t17 inline title, t15, t13, t12, t11 (minimum), hero 44 bold. Old 4.1 table is superseded by the mockup classes.

### R4. Token to code map (replaces section 17)
| New | Replaces |
|---|---|
| `lib/core/theme/rig_colors.dart` (`RigColors`, light and dark instances) | `AppColors` semantic part, later `AppColors` removed |
| `lib/core/theme/rig_theme.dart` (`RigTheme.light`, `RigTheme.dark`, component themes: switch, checkbox, chip, snackbar, dialog, bottom sheet, page transitions, ink splash) | `AppTheme.lightTheme` |
| `lib/core/theme/rig_tokens.dart` (`RigSpace` s2 8, s3 12 gap, s5 20 margin; `RigRadius` card 20, sheet 28, alert 14, tile 28, pill 999; `RigMotion`) | scattered literals |
| `lib/core/format/rig_format.dart` | 33 NumberFormat and 39 DateFormat constructions in screens |
| `lib/core/widgets/rig/*` | see COMPONENTS.md |
| `assets/fonts/Inter-*.ttf` or the variable font; `pubspec.yaml` `fonts:` | system font |
| `lib/core/settings/appearance_provider.dart` (`themeModeProvider`) | none (new, LR-23) |

### R5. Dark mode
Scheduled (was "not scheduled"). Dark values: TOKENS.md section 2 (true black canvas `#000000`, surfaces `#1C1C1E` and `#2C2C2E`). Every text token has a passing AA contrast row in TOKENS.md section 5; the contrast matrix becomes a unit test input (T-F06).

### R6. Platform
Portrait phone only, portrait lock stays, smallest width 360 dp, test widths 360 and 412. Edge to edge: `SystemChrome.setEnabledSystemUIMode(edgeToEdge)`, insets from `MediaQuery.viewPaddingOf`. System back: `PopScope`; predictive back flag in the manifest. Section 14 (sidebar) and 15 (desktop) and every "expanded" width class are dropped.
