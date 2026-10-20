> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# core_theme_and_widgets

Files covered (one doc): `lib/core/theme/app_colors.dart` (77 lines), `lib/core/theme/app_theme.dart` (255), `lib/core/widgets/adaptive_header.dart` (186: `AdaptiveHeader`, `_DesktopHeader`, `_MobileHeader`, `AdaptiveContent`), `lib/core/widgets/gradient_widgets.dart` (117: `GradientAppBar`, `GradientContainer`, `GradientButton`). Token names come from docs/design/DESIGN_SYSTEM.md; component names from COMPONENTS.md. Usage counts were measured with grep over `lib/` on 2026-10-12 (excluding the defining files).

## 1. Purpose and primary user task

These files are the visual foundation for every screen: they define the palette, the Material theme (what an unstyled `AppBar`, `Card`, `TextField`, button, chip, dialog, sheet and snackbar look like) and two header/content wrappers. Nobody "uses" them directly; their job is to make every screen look like one product and to change the brand by editing one value. The redesign replaces them by `RigTheme`, `RigColors`, `RigSpace`, `RigRadius`, `RigMotion`, `RigType`, `RigAppBar` and `RigScaffold`.

## 2. Current structure

- `AppColors` (static consts): 5 gradient stops (`gradient1` #252B49, `gradient2` #315D9A, `gradient3` #618DCE, `gradient4` #0490B6, `gradient5` #B7CDED), semantic aliases (`primary`, `primaryDark`, `primaryLight`, `accent`, `accentLight`), surfaces (`background`, `surface`, `cardBackground`), text (`textPrimary`, `textSecondary`, `textHint`, `textOnPrimary`), status (`success`, `warning`, `error`, `info`), lines (`border`, `divider`), `shadow`, `chartColors` (8), `primaryGradient` (5 stops), `appBarGradient` (stops 1, 2, 3), `cardGradient` (stops 2 and 4).
- `AppTheme.lightTheme` (static getter, creates a new `ThemeData` per access): Material 3, `ColorScheme.light(...)` with only 10 roles overridden, `appBarTheme` (transparent background, white foreground, centered 20 w600 title, elevation 0), `cardTheme` (elevation 2, shadow, radius 16), FAB, `bottomNavigationBarTheme` (fixed, elevation 8, labels 12), `inputDecorationTheme` (filled white, radius 12, 1 px `border` #E2E8F0, focus 2 px primary, error `error`), elevated / outlined / text button themes (radius 12, 24x12 padding, 16 or 14 w500), `chipTheme`, `dividerTheme`, `dialogTheme` (radius 20, elevation 8), `bottomSheetTheme` (top radius 20), `snackBarTheme` (floating, `primaryDark` background, radius 8), a full `textTheme` (13 styles).
- `AdaptiveHeader`: desktop = flat white bar (padding 20 x 12, 18 sp w600 title, 14 sp subtitle, bottom border); mobile = full gradient (`appBarGradient`), `SafeArea(bottom: false)`, `Padding(16)`, centered 20 sp white title, optional 14 sp 80 percent white subtitle, `actions`, optional `bottom`. Users: agents_screen.dart and settings_screen.dart only.
- `AdaptiveContent`: on desktop centers child in `ConstrainedBox(maxWidth: 800)`; on mobile returns the child. Users: 6 form screens (ledger_form, side_bore_form, diesel, pvc, bit, hammer).
- `GradientAppBar`, `GradientContainer`, `GradientButton`: no references anywhere in `lib/` or `test/` (dead code).

## 3. Problems found

Theme traps and contrast
1. `appBarTheme.backgroundColor: Colors.transparent` with white foreground (app_theme.dart:25-36): any `AppBar` that does not add `flexibleSpace` or an explicit color is white-on-near-white (about 1.05:1). Screens repair it by hand 20 times with `flexibleSpace` gradient or `backgroundColor: AppColors.primary` (about, vehicle_management, 3 export screens, ...). `showLicensePage` and any plugin page (printing's `PdfPreview` actions, file pickers' fallbacks) are exposed. UNVERIFIED on device for `showLicensePage`, certain from the code.
2. `ColorScheme.light(...)` overrides only primary, primaryContainer (#618DCE), secondary, secondaryContainer (#B7CDED), surface, error and the `on*` colors (lines 13-24). Every other role (surfaceContainer*, outline, outlineVariant, onSurfaceVariant, inverseSurface, tertiary) falls back to the baseline Material purple-tinted defaults: pop-up menus, `SegmentedButton`, `NavigationBar`, date pickers and dropdown menus pick a lavender surface tint that is not in the palette. `primaryContainer` is #618DCE (white text on it = 3.38:1) which M3 widgets use as a tonal fill with dark text.
3. `chipTheme` (128-136) sets `selectedColor: primary` but `labelStyle` color `textPrimary` (#1A1A2E): a selected `ChoiceChip`/`FilterChip` that does not override its label has dark text on dark blue, about 2.5:1. Screens work around it per chip.
4. Contrast of the palette (white background unless noted): `success` #10B981 2.54, `warning` #F59E0B 2.15, `error` #EF4444 3.76, `info` #3B82F6 3.68, `accent` #0490B6 3.70, `textHint` #94A3B8 2.56 (2.45 on #F8FAFC), `border` #E2E8F0 1.23, gradient stop 3 #618DCE with white text 3.38, `gradient5` #B7CDED 1.62. The status colors are used as TEXT colors in 47 + 43 + 46 places.
5. `inputDecorationTheme` border `border` #E2E8F0 is 1.23:1 against white and against #F8FAFC (UI component boundary should be at least 3:1). `hintStyle` uses `textHint` (2.56:1).
6. Snackbar theme defaults to `primaryDark` with white text (good, 13.8:1), but 115 `SnackBar` call sites override `backgroundColor` with `success` (2.54:1 with white text), `error` (3.76:1), `warning` (2.15:1) or `Colors.orange` (2.16:1), `Colors.red`.
7. Text sizes below the 11 sp floor: `labelSmall` is 10 sp (line 248); the app uses 8, 9 and 10 sp in 28 places.

Consistency
8. `textTheme.titleMedium` is 14 w500, `titleLarge` 16 w600, `headlineSmall` 18: different from Material defaults, so built-in widgets (ListTile title, dialogs, date picker) render with these sizes while custom `Text(style: TextStyle(fontSize: 16, ...))` bypasses the theme: 16 distinct font sizes in use (DESIGN_SYSTEM section 1).
9. Two systems for elevation: `cardTheme` elevation 2 and 27 hand-built `BoxShadow` containers (blur 10, black 5 to 10 percent, y 2). Both co-exist on the same screen (Vehicle management uses `Card`, Settings uses a shadow `Container`).
10. Button theme: `ElevatedButton` is the filled primary (elevation 2) used 35 times and `FilledButton` 0 times; `TextButton` 14 w500 used 57 times. Primary and destructive actions look the same except for per-call color overrides (red, amber).
11. `bottomNavigationBarTheme` is theme-level but the navigation is rebuilt with a custom shadow container in the mobile shell (see main_navigation doc); the theme is partly dead.
12. `AppColors.shadow` (#1A000000) is used 26 times with `.withOpacity(0.05)`, which REPLACES the alpha (5 percent black): a barely visible shadow that still costs a blur (radius 10) per card. `withOpacity` is deprecated and used 125 times (18 uses of `withValues`).
13. `AppTheme.lightTheme` is a getter: a new `ThemeData` per access (about 255 lines of allocations) each `MaterialApp` rebuild.
14. No `fontFamily`, no `visualDensity` per platform, no `TextSelectionTheme`, no `SwitchTheme`/`CheckboxTheme`/`RadioTheme`, no `NavigationBarTheme`, no `PopupMenuTheme`, no `TabBarTheme`, no `ScrollbarTheme`, no `TooltipTheme`, no `ListTileTheme` (so a Switch and ListTile look default Material baseline).

Widgets
15. `AdaptiveHeader` mobile layout: the title is centered in a `Column` with `crossAxisAlignment.center` inside an `Expanded`, but `actions` are appended in the same `Row` without a leading counterweight, so the title is not truly centered when there are actions (agents has 1 action, so the title shifts left by 24 dp). Padding 16 on all sides plus `SafeArea` makes the bar about 56 + status bar (Android) but subtitle adds 20: 285 of 900 logical px is the Ledger header (other screen), not this one.
16. Mobile header color: white 80 percent subtitle on gradient stop 3 (#618DCE) is about 2.7:1.
17. Desktop header uses 18 sp title and a 12 vertical padding; titles elsewhere on desktop (cashbook header) differ (see cashbook docs).
18. `AdaptiveContent` default max width 800 versus the 640 form width in DESIGN_SYSTEM; on mobile it returns the child unchanged, so forms also lack the horizontal padding handled by each screen (padding is per screen).
19. `GradientAppBar`/`GradientContainer`/`GradientButton` are dead code (0 references), `GradientButton` adds a blurred shadow and a gradient that the design system drops, `GradientAppBar` uses a different height rule (`kToolbarHeight` + `SafeArea` inside the sized box, so the SafeArea eats into the height).
20. Hand-built duplicates of the header: 14 gradient `Container` headers (COMPONENTS.md section 1), plus cashbook_header.dart which re-implements the AdaptiveHeader rule (its own doc comment says "same rule as AdaptiveHeader").
21. Raw hex outside the palette: 7 `Color(0x...)` literals (combined_home_screen.dart:543 brown #8B4513, cashbook_common.dart:10-11 income #059669 and expense #DC2626, side_bore_form 396 and 4 side forms repeating the three gradient stops as raw literals instead of `AppColors.appBarGradient`).

## 4. Redesign

### 4.1 Token map: every `AppColors` member to its replacement

| Current (hex) | Uses in lib/ | Contrast on white | Replacement role (hex proposal) | Rule |
|---|---|---|---|---|
| `primary` #315D9A | 115 | 6.64 | `primary` = `kBrandSeed` (PROVISIONAL) | unchanged value; one seed |
| `primaryDark` #252B49 | 1 (ledger_list.dart:162) + snackbar theme | 13.81 | `inverseSurface` for snackbars; ledger_list use becomes `onSurface` or `headerGradient` start per its own doc | no direct alias kept |
| `primaryLight` #618DCE | 0 external (theme `primaryContainer`) | 3.38 | removed; `primaryContainer` = #E3ECF8 (seed tone 92) | M3 tonal fill with `primary` text (8.9:1) |
| `accent` #0490B6 | 12 (commission, icons, entries card, agent card) | 3.70 | commission figures: `commission` #0B6E87 (5.84); non-commission uses: `info` #1D5FBF or `chartSeries[3]` by context | per-use, listed in each screen doc |
| `accentLight` #B7CDED | 7 (+ chip bg, `secondaryContainer`) | 1.62 | `primaryContainer` for pill backgrounds; `chartSeries` only for chart slices | never as text or thin lines |
| `background` #F8FAFC | 23 | n/a | `background` #F8FAFC | unchanged |
| `surface` #FFFFFF | 53 | n/a | `surface` #FFFFFF | unchanged |
| `cardBackground` #FFFFFF | 0 external | n/a | removed, use `surface` | duplicate |
| `textPrimary` #1A1A2E | 49 | 17.06 | `onSurface` | |
| `textSecondary` #64748B | 94 | 4.76 | `onSurfaceVariant` #566275 (6.18) | slightly darker, safer on #F1F5F9 |
| `textHint` #94A3B8 | 23 | 2.56 | `textMuted` #6B7280 (4.83) | hints, captions, disabled labels |
| `textOnPrimary` #FFFFFF | 0 external | n/a | `onPrimary` | |
| `success` #10B981 | 47 | 2.54 | text and icons: `moneyIn` #047857 (5.48); tonal fill: `moneyInContainer` #E6F4EE; success snackbar icon uses `moneyIn` on `inverseSurface` | meaning "money in" and "done" |
| `warning` #F59E0B | 43 | 2.15 | text: `outstanding` #9A4A06 (6.26) for Balance/Pending; fill-only amber `warning` for badges with dark text; container `outstandingContainer` #FDF0E1 | never as text on white |
| `error` #EF4444 | 46 | 3.76 | text and destructive buttons: `negative` #B91C1C (6.47); container `negativeContainer` #FBE9E9 | |
| `info` #3B82F6 | 3 | 3.68 | `info` #1D5FBF (6.10) | |
| `border` #E2E8F0 | 33 | 1.23 | decorative lines: `outlineVariant` #E2E8F0; input and checkbox borders: `outline` #8A97A8 (3.1) | split by purpose |
| `divider` #F1F5F9 | 10 (+ theme) | 1.1 | `outlineVariant` (dividers) / `surfaceContainer` (fills) | |
| `shadow` #1A000000 | 26 | n/a | removed from cards (tonal elevation); only level-3 floating uses one soft shadow (blur 8, y 2, 10 percent) | |
| `gradient1..5` | 0 external (defining file only) | n/a | removed; `headerGradient` optional (Q-Brand: stops seed tone 25 to seed) | never carries text at stop 3 |
| `primaryGradient` | 2 (both dead in gradient_widgets.dart) | n/a | removed | |
| `appBarGradient` | 18 | n/a | `headerSurface` (flat seed) by default, or `headerGradient` if approved | `RigAppBar` is the only consumer |
| `cardGradient` | 3 (calendar_view, portfolio_view, agents avatar) | n/a | removed: avatar uses `primaryContainer` + `primary`; portfolio hero card is specified in portfolio.md | decorative gradients dropped |
| `chartColors` (8) | 2 (stats_screen.dart:626, 656) | #252B49 13.8; #315D9A 6.64; #618DCE 3.38; #0490B6 3.70; #B7CDED 1.62; #4A6FA5 5.11; #7BA3D3 2.62; #2E8B9F 3.95 | `chartSeries[0..7]` (derived from the seed plus fixed hues, adjacent contrast at least 1.5 and each at least 3:1 against `surface`); screens use 0 to 5 | see stats_screen_charts.md |
| raw `Colors.red/green/blue/orange/grey/brown` | about 150 | varies | role tokens per INCONSISTENCIES.md I-03 | |
| `Color(0xFF8B4513)` hammer brown | 1 | 7.10 | `categoryHammer` | |
| `Color(0xFF059669)`, `Color(0xFFDC2626)` (cashbook income/expense) | 2 | 3.77 / 4.83 | `moneyIn` / `negative` | owned by cashbook group |

### 4.2 Theme map: every `ThemeData` property

| Current | New |
|---|---|
| `useMaterial3: true`, `brightness: light` | same; `RigTheme.fromSeed(kBrandSeed)` with `dynamicSchemeVariant: fidelity`; light only |
| `ColorScheme.light(...)` partial | full scheme from seed, then override the money roles; all surface roles defined (surface, surfaceContainerLowest..Highest map to the 4 levels in DESIGN_SYSTEM section 7), `outline` #8A97A8, `outlineVariant` #E2E8F0, `onSurfaceVariant` #566275, `inverseSurface` #1A1A2E: removes lavender defaults |
| `appBarTheme` transparent + white | solid `headerSurface` background, `onPrimary` foreground, `elevation 0`, `scrolledUnderElevation 0`, centered false on desktop and true on mobile, title `headlineSmall`; therefore any default `AppBar` (license page, plugin pages) is legible |
| `cardTheme` elevation 2 + shadow, radius 16 | elevation 0, `surface`, 1 px `outlineVariant` border, radius `RigRadius.lg` (16), margin 0 |
| `floatingActionButtonTheme` primary, elevation 4 | `primary`, elevation level 3 (one soft shadow), radius `lg`, extended variant label `labelLarge` |
| `bottomNavigationBarTheme` | replaced by `NavigationBarThemeData`: height 80, indicator `primaryContainer` pill, labels `labelSmall` 11 always shown, selected `primary`, unselected `onSurfaceVariant` |
| `inputDecorationTheme` (filled white, radius 12, border #E2E8F0) | filled `surface`, radius `md` (12), enabled border 1 px `outline` (3:1), focused 2 px `primary`, error `negative`, disabled fill `surfaceContainer`, label `onSurfaceVariant`, hint `textMuted`, helper/error `bodySmall`, `isDense: false` (56 dp), content padding 16 x 16 |
| `elevatedButtonTheme` | removed from use; `filledButtonTheme`: `primary` / `onPrimary`, min height 48 (40 on desktop pointer), radius `md`, text `labelLarge`; `filledTonalButtonTheme`: `primaryContainer`; `outlinedButtonTheme`: 1 px `outline`, `primary` text; `textButtonTheme`: `primary` text, min 48 x 48; destructive style helper `RigButtonStyles.destructive` uses `negative` |
| `chipTheme` | `ChoiceChip`/`FilterChip`: selected `primaryContainer` + `primary` label + check, unselected `surface` + 1 px `outlineVariant`, label `labelLarge`, visual height 32, `materialTapTargetSize: padded`, radius `sm` |
| `dividerTheme` | `outlineVariant`, thickness 1, space 1 |
| `dialogTheme` | `surface`, radius `xl` (24), elevation level 3, title `headlineSmall`, content `bodyMedium` `onSurfaceVariant`, max width 400 for confirm and 560 for forms (`RigDialogShell`) |
| `bottomSheetTheme` | `surface`, top radius `xl`, drag handle `full`, showDragHandle true, max width 560 on wide screens |
| `snackBarTheme` | floating, `inverseSurface`, `onInverseSurface` text, radius `sm`, 4 s duration, optional action in `primaryContainer`; kinds (success, error, info) add a leading icon only, never a background color: removes 115 background overrides |
| `textTheme` (13 styles) | `RigType` scale (section 4 of DESIGN_SYSTEM): displayAmount 28/36 w700, headlineSmall 20/28 w600, titleMedium 16/24 w600, titleSmall 14/20 w600, bodyLarge 16/24, bodyMedium 14/20, bodySmall 12/16, labelLarge 14/20 w500, labelMedium 12/16 w500, labelSmall 11/16 w500, amountLarge 20/28, amountMedium 16/24, amountSmall 14/20 (tabular figures). Mapping: current `displayLarge 32` and `displayMedium 28` become `displayAmount`; `displaySmall 24`, `headlineLarge 22` become `headlineSmall`; `headlineMedium 20` same; `headlineSmall 18`, `titleLarge 16` become `titleMedium`; current `titleMedium 14 w500`, `labelLarge 14` become `labelLarge`; `titleSmall 12`, `labelMedium 12` become `labelMedium`; `bodyLarge 16`, `bodyMedium 14`, `bodySmall 12` unchanged sizes; `labelSmall 10` becomes 11. Font family: bundled Noto Sans (see DESIGN_SYSTEM section 4) |
| (missing) | add `SwitchThemeData` (track `primary`, thumb white, off track `outline`), `CheckboxThemeData`, `RadioThemeData` (`primary`), `PopupMenuThemeData` (surface, radius `sm`), `TooltipThemeData`, `ScrollbarThemeData` (desktop always visible), `TabBarThemeData`, `ListTileThemeData` (min height 56, icon color `onSurfaceVariant`), `TextSelectionThemeData`, `VisualDensity.compact` on desktop only |

Access pattern: `static final ThemeData light = RigTheme.fromSeed(kBrandSeed);` (built once). Semantic money colors live in `RigColors extends ThemeExtension<RigColors>` read as `context.rig.moneyIn`; `RigSpace`, `RigRadius`, `RigMotion` are `const` classes.

### 4.3 Widget map

| Current | Decision |
|---|---|
| `AdaptiveHeader` (agents, settings) | replaced by `RigAppBar`. Mobile: 56 dp flat `headerSurface`, title `headlineSmall` `onPrimary`, left-aligned or centered per screen but with a leading/trailing reservation (48 dp each) so the title is truly centered; subtitle `bodySmall` `onPrimary` at 100 percent opacity over the flat seed (6.64:1). Desktop: 48 dp `surface` bar, 1 px `outlineVariant` bottom border, title `headlineSmall` (20 sp), subtitle `bodyMedium` `onSurfaceVariant`, actions right |
| `_DesktopHeader`, `_MobileHeader` (private) | removed (internal branches of `RigAppBar`) |
| `AdaptiveContent` (6 form screens) | replaced by `RigScaffold.maxContentWidth` (640 for forms, 720 for settings and export, 1100 for dashboards) and the shared horizontal padding rule 16 / 24 / 32; centered on desktop only (as today) |
| `GradientAppBar` | DELETE (unused) |
| `GradientContainer` | DELETE (unused) |
| `GradientButton` | DELETE (unused); primary buttons are `FilledButton` |
| `AppColors` | kept only as a thin alias layer during migration (`AppColors.primary` forwards to the seed; every other member marked `@Deprecated` pointing to its role) and removed when the migration counts reach zero |
| `AppTheme` | replaced by `RigTheme` |

Unused or duplicate widgets in this group, in one list: (1) `GradientAppBar` unused; (2) `GradientContainer` unused; (3) `GradientButton` unused; (4) `AppColors.primaryGradient` only used by the two unused widgets; (5) `AppColors.gradient1..5` only referenced from `app_colors.dart` itself plus raw copies of the same hex in 5 form screens (they duplicate `appBarGradient` as literals); (6) `AppColors.cardBackground`, `AppColors.primaryLight`, `AppColors.textOnPrimary`: 0 external uses (referenced only by the theme); (7) `AdaptiveHeader` duplicates 14 hand-built headers and `cashbook_header.dart`; (8) `_DesktopHeader`/`_MobileHeader` duplicate the same row layout twice; (9) `AdaptiveContent` duplicates per-screen `ConstrainedBox` code in about_screen.dart (700) and `_DesktopContentWrapper` (does not constrain despite its comment, desktop_shell.dart:793).

State table (header component)
| State | Behavior |
|---|---|
| Default | bar with title, optional subtitle and actions |
| Loading | optional 2 px `LinearProgressIndicator` along the bottom edge when a screen passes `loading: true` |
| Empty | n/a |
| Error | n/a |
| Disabled | action icons use `onSurfaceVariant` at 38 percent when disabled |

Motion: the optional collapsing behavior of the Ledger header is specified elsewhere (HIGHLIGHTS_AND_COLLAPSE.md); `RigAppBar` itself has no motion; theme transitions off.

Tokens used by the foundation: spacing s1..s12; radius xs, sm, md, lg, xl, full; type scale as above; every color role in DESIGN_SYSTEM section 3.

## 5. Logic touchpoints that must stay untouched

- `AppColors.primary` value #315D9A remains the seed until the developer provides the brand (PROVISIONAL).
- `AdaptiveHeader` constructor contract (`title`, `subtitle`, `actions`, `bottom`) and `AdaptiveContent(child, maxWidth)` stay valid during migration (screens migrate one by one); `PlatformHelper.isDesktop` is the only branch.
- `registerAppLicenses()` and the license asset declaration are unrelated to the theme and untouched.
- Hive, providers and services: none are referenced from these files.

## 6. Acceptance criteria

1. A single constant (`kBrandSeed`) change updates app bar, primary buttons, selected chips, tab indicator, focus ring, nav indicator and first chart series; semantic money colors do not change.
2. Every text/background pair produced by the theme meets 4.5:1 (3:1 for large text and icons); verify the table in DESIGN_SYSTEM section 3.2 with the same script, and verify `primaryContainer` text, `chipTheme` selected state and snackbar text.
3. Any `AppBar` created without extra styling (for example `showLicensePage`) has legible title and back icon.
4. Menus, dropdowns, switches and date pickers show no lavender tint: `surfaceContainer*` roles are defined.
5. Input borders are at least 3:1 against `surface`.
6. `grep -rn "Colors\.\(red\|green\|blue\|orange\|purple\|brown\|grey\|indigo\|teal\|cyan\)" lib` returns 0 and `grep -rn "Color(0x" lib` returns only the theme files after migration.
7. `GradientAppBar`, `GradientContainer`, `GradientButton`, `AdaptiveHeader`, `AdaptiveContent` are removed when their reference counts reach 0; `flutter analyze` is clean.
8. `RigTheme.light` is built once (single allocation); `withOpacity` count drops from 125 to 0 (use token containers or `withValues`).
9. Snackbars show a leading icon for success and error and use `inverseSurface` background in all 115 call sites (through `showRigSnack`).
10. At text scale 200 percent the app bar title does not clip (single line ellipsis with tooltip on desktop; mobile title may wrap to two lines up to 72 dp height).

## 7. Performance notes

- `static final` theme; `RigColors` is a `const`-constructible `ThemeExtension` with `lerp` implemented (no per-frame allocations).
- Replace the 27 shadowed `Container` cards by `RigCard` (border, no blur): removes about 27 `saveLayer`-prone blur shadows per list screen. Remove `ClipRRect` + shadow combinations (settings card) which force clipping layers.
- Prefer `const` for `RigSpace`/`RigRadius` and use `SizedBox`/`Padding` with const values; no `EdgeInsets.symmetric` created per build inside list items.
- Bundle two font weights only (500 and 600) in addition to Regular to keep app size down; `FontFeature.tabularFigures()` constants shared in `RigType`.
- `RigAppBar` is a stateless widget with no `MediaQuery` dependency beyond `padding.top`; use `MediaQuery.paddingOf` / `viewPaddingOf` (not `MediaQuery.of`) to avoid rebuilds on keyboard changes.

## Reconciliation 2026-10-13 (Apple look, Android only)

The proposal above (seed #315D9A, Noto Sans UI, gradient or flat header, 1 px outlined cards, NavigationBar, desktop AppBar variants) is replaced by the approved mockup tokens. The token values are in `docs/design/mockup/TOKENS.md` sections 2 to 7 (resolved light and dark values; do not retype them in code from this file). Dropped: every desktop, macOS, hover, `VisualDensity.compact` for desktop, `ScrollbarThemeData` always visible, 1100 and 720 dp max width and `AdaptiveContent` width rule. Old text stays above.

### R1. Mockup screens and Flutter mapping

No J screen draws the foundation. The mapping is token source to Flutter file:

| Mockup source | Flutter file (new) | Widgets and classes | Notes |
|---|---|---|---|
| `:root` colour tokens, TOKENS.md sections 1 to 3, 6 | `lib/core/theme/rig_colors.dart` | `RigColors extends ThemeExtension<RigColors>` (light and dark instances, `lerp`) | replaces `app_colors.dart` |
| ColorScheme mapping, TOKENS.md section 6 | `lib/core/theme/rig_theme.dart` | `RigTheme.light`, `RigTheme.dark` (`static final`, hand built `ColorScheme`s, not `fromSeed`) | replaces `app_theme.dart` |
| Formatter rules, TOKENS.md section 7 | `lib/core/utils/rig_format.dart` | `RigFormat.money`, `moneyCompact`, `qty`, `ftq`, `dRow`, `dGroup`, `dFull`, `dMonth` | replaces `inr`, `inrS`, `rs`, `grp`, `num` call sites and the scattered `NumberFormat` and `DateFormat` instances |
| Scale, spacing, radius, motion, TOKENS.md section 4 | `rig_theme.dart` (const holders `RigSpace`, `RigRadius`, `RigMotion`, `RigType`) | const classes: spacing 20 and 12, radii 20, 28, 14, full, motion 200 to 350 ms | the names of these four holders are not in the component list given for the redesign; keep them as plain const holders unless the lead renames them |
| Large title, solid bar, hairline | `lib/core/widgets/large_title_scaffold.dart` | `LargeTitleScaffold` | replaces `RigScaffold`, `RigAppBar`, `AdaptiveHeader` |
| Floating capsule 5 tabs | shell (main_navigation doc) | `RigTabBar` | |
| Inset grouped lists and rows | `lib/core/widgets/` | `RigGroup`, `RigRow`, `RigFormRow` | |
| Cards, metrics, money | `lib/core/widgets/` | `RigCard`, `RigMetricCard`, `RigRing`, `MoneyText`, `MoneyTile`, `DepthTile`, `CategoryTile` | |
| Chips, segments, switches | `lib/core/widgets/` | `RigChipRow`, `RigSegmented`, `RigSwitch`, `RigCheck` (themed Material `Switch` and `Checkbox`) | not custom controls |
| Buttons, dialogs, sheets, snack | `lib/core/widgets/` | `RigButton`, `RigAlertDialog`, `RigSheet`, `RigSnack`, `RigRigSheet`, `DatePickerSheet` | |
| States and gestures | `lib/core/widgets/` | `EmptyState`, `ErrorBanner`, `Skeleton`, `RowActions`, `UnsavedChangesGuard` | |
| Fonts | `assets/fonts/` | Inter 400, 500, 600, 700 (OFL notice kept) | Noto Sans stays for PDFs only |

### R2. What changes in the redesign (supersedes section 4)

#### R2.1 Token map: every AppColors member to its replacement

Replacement names are `RigColors` fields (or the Material `ColorScheme` role in brackets). Values come from TOKENS.md section 2; light and dark both exist for every row.

| Current `AppColors` member | Replacement | Verdict |
|---|---|---|
| `primary` #315D9A | `accent` (graphic), `accentButton` (fill behind a white label, `[primary]`), `accentText` (text and links); default system blue, five derived roles `accent`, `accentText`, `accentButton`, `onAccent`, `accentTint`; #315D9A kept only as a documented alternate, not a setting | CHANGED |
| `primaryDark` #252B49 | removed; snack background is `label` (primary label colour) with `onInverseChip` text | DELETED |
| `primaryLight` #618DCE | removed; tinted fills use `accentTint` (`[primaryContainer]`) | DELETED |
| `accent` #0490B6 (commission, icons) | commission uses `commission` and `commissionText`; other uses `accent` or `accentText` per screen doc | CHANGED |
| `accentLight` #B7CDED | `accentTint` for pill backgrounds; never text | DELETED |
| `background` #F8FAFC | `canvas` (`[surface]`: light #F2F2F7, dark #000000) | CHANGED |
| `surface` #FFFFFF | `surface1` (cards, inset groups, `[surfaceContainerLow]`); sheets `sheet` and elevated card `surface1Elevated` (`[surfaceContainer]`, `[surfaceContainerHigh]`) | CHANGED |
| `cardBackground` | `surface1` | DELETED (duplicate) |
| `textPrimary` | `label` (`[onSurface]`) | CHANGED |
| `textSecondary` | `labelSecondary` (`[onSurfaceVariant]`, AA variant, light rgba(60,60,67,.8)) | CHANGED |
| `textHint` | `labelTertiary` for chevrons and decoration only; text that carries meaning uses `labelSecondary` | CHANGED |
| `textOnPrimary` | `onAccent` | DELETED |
| `success` | `moneyIn` (graphic), `moneyInText` (text), `moneyInButton` (button fill) | CHANGED |
| `warning` | `outstanding` (graphic) and `outstandingText` (text) | CHANGED |
| `error` | `moneyOut`, `moneyOutText`, `moneyOutButton` (`[error]`, `[errorContainer]` for fills); `danger` and `warning` roles alias these | CHANGED |
| `info` | `accent` and `accentText` (no separate info hue) | DELETED |
| `border` | `separator` (`[outlineVariant]`, hairline 0.5 dp); input boundaries use `fill` surfaces, not borders | CHANGED |
| `divider` | `separator` | DELETED (duplicate) |
| `shadow` | `RigElevation.card` (light only, `--sh`) and `RigElevation.bar` (`--sh-bar`); dark has no card shadow | CHANGED |
| `gradient1` to `gradient5` | removed. The only gradients left are the four `CategoryTile` gradients (category colour to a 62 percent mix with white, label `--on-tile` black) | DELETED |
| `primaryGradient`, `appBarGradient`, `cardGradient` | removed (`headerGradient`, `appBarGradient` and every `AppColors` gradient entry are deleted, not migrated) | DELETED |
| `chartColors` (8) | `chartSeries` is built from `accent`, `catDiesel`, `catPvc`, `catBit`, `catHammer`, `moneyIn`, `moneyOut`, `commission` graphic colours; final order is set by the Portfolio and Stats docs | CHANGED |
| raw `Colors.*` (about 150) and `Color(0x...)` | role tokens; hammer brown becomes `catHammer` (pink), income and expense hexes become `moneyIn` and `moneyOut` | DELETED |
| (new) unselected pill, switch off track | `fill`, `fillStrong` (`[surfaceContainerHighest]`) | NEW |
| (new) selected chip | `inverseChip`, `onInverseChip` | NEW |
| (new) categories | `catDiesel`, `catPvc`, `catBit`, `catHammer` and `-Text` variants (orange, teal, purple, pink) | NEW |
| (new) glass | `glass`, `glassBar`, `glassBorder`, `glassSelected`, `bar`, `scrim`; defaults use `barSolid` and `glassBarSolid` (94 percent) because the blur toggle is OFF | NEW |
| (new) pressed feedback | `pressOverlay`, `pressOverlayOnFill` (ink colours) | NEW |

Deleted at the end of the migration: gradient entries, `AdaptiveHeader`, `GradientAppBar`, and the `AppColors` aliases (a thin deprecated alias layer exists only while screens migrate and goes when the grep counts reach zero).

#### R2.2 Theme map

| Current `ThemeData` property | New |
|---|---|
| `useMaterial3: true`, light only | Material 3, two hand built schemes, `RigTheme.light` and `RigTheme.dark`, `ThemeMode.system` by default, no dynamic colour; both `static final` |
| `ColorScheme.light(...)` partial | full hand built scheme per TOKENS.md section 6 (surface = `canvas`, `surfaceContainerLow` = `--s1`, `surfaceContainer` = `--sheet`, `surfaceContainerHigh` = `--s1e`, `surfaceContainerHighest` = `--s2`/`--s3`, `onSurface` = `--lb`, `onSurfaceVariant` = `--lb2`, `outline` = `--lb3`, `outlineVariant` = `--sep`, `primary` = `--acc-btn`, `onPrimary` = `--onacc`, `primaryContainer` = `--acc-tint`) |
| `appBarTheme` transparent with white foreground | flat `surface` at 94 percent (solid, hairline `separator`), foreground `label`, elevation 0, `scrolledUnderElevation` 0; any default `AppBar` (license page, plugin pages) is legible in both themes; the real header is `LargeTitleScaffold` |
| `cardTheme` elevation 2 | `RigCard`: `surface1`, radius 20, margin 20 x 12, soft shadow in light only, no border in dark |
| `floatingActionButtonTheme` | no FAB in the redesign (header add buttons); theme left at defaults |
| `bottomNavigationBarTheme` | removed; `RigTabBar` is a custom floating capsule (62 dp, 16 dp side margin, `barSolid`, 5 tabs, selected `glassSelected`); no `NavigationBar` |
| `inputDecorationTheme` (filled, bordered) | fields live in `RigFormRow`: label left, value right, no border, focus ring 2 dp `accent`, error text `moneyOutText`, helper 13 sp `labelSecondary`; `InputDecoration.collapsed` inside the row |
| `elevatedButtonTheme` | removed; `RigButton` = `FilledButton` (50 dp pill, `accentButton` on `onAccent`), `FilledButton.tonal` (`accentTint`, `accentText`), `TextButton` (`accentText`, min 48 dp); destructive uses `moneyOutButton`; `StadiumBorder` |
| `outlinedButtonTheme` | removed from use |
| `chipTheme` | `RigChipRow`: unselected `fill`, selected `inverseChip` with `onInverseChip`, label 15 sp, visible pill 32 dp inside a 48 dp box, radius full, `MaterialTapTargetSize.padded` |
| `dividerTheme` | `separator`, 0.5 dp, inset 16 in groups |
| `dialogTheme` | `RigAlertDialog`: radius 14, width 270 dp, `alert` surface, stacked 48 dp buttons with hairlines, centered title 17 sp w600 |
| `bottomSheetTheme` | `RigSheet`: top radius 28, grabber (`showDragHandle`), `sheet` surface, `isScrollControlled`, keyboard insets added, scrim `scrim` (no blur) |
| `snackBarTheme` | `RigSnack`: floating capsule radius 26, background `label`, text `onInverseChip` 15 sp, 1.9 s, above the tab bar; no per-call colours |
| `textTheme` (13 styles) | Inter 400, 500, 600, 700, tabular figures on every amount (`FontFeature.tabularFigures()`); scale: 34/1.2 bold large title, 28, 22/1.25 bold, 20, 17/1.3, 15, 13, 12, 11 minimum, hero 44 bold; all through `MediaQuery.textScalerOf` |
| (missing) | `SwitchThemeData` (51 x 31 as close as Material allows, `trackOutlineColor` transparent, thumb white, on `moneyIn`, off `fillStrong`, padded 48 dp), `CheckboxThemeData` (`CircleBorder`, 2 dp side, `accent` when selected, check `onAccent`), `PopupMenuThemeData`, `TooltipThemeData`, `TextSelectionThemeData`, `pageTransitionsTheme` with `PredictiveBackPageTransitionsBuilder`, `splashFactory: InkSparkle.splashFactory`, `highlightColor` and `splashColor` from `pressOverlay`; no desktop density, no always visible scrollbar |

Font: Inter replaces Noto Sans for all UI text (Inter 400, 500, 600, 700, SIL OFL, notice in `assets/fonts/`). Noto Sans and Noto Sans Tamil stay in `assets/fonts/` and are used only by the PDF code through `CashbookExportService.loadFonts()`; the Tamil fallback for on-screen notes stays Noto Sans Tamil. Frozen PDF code is not edited.

Formatters (`RigFormat`): `money` (rupee sign, en-IN grouping, two decimals only with paise, minus before the sign, `--` for non-finite), `moneyCompact` (L from 1,00,000, Cr from 1,00,00,000, only inside `MoneyTile` and Portfolio metric cards, never in lists, rows, group headers or the Account Ledger strip), `qty`, `ftq` (feet up to one decimal with trailing .0 hidden, 350 or 350.5, rounded to one decimal before hiding), `dRow` (`d MMM`), `dGroup` (`EEE, d MMM yyyy`), `dFull` (`d MMM yyyy`), `dMonth` (`MMMM yyyy`). Each `NumberFormat` and `DateFormat` is a `static final`. The PDF and CSV exports and the Export screens keep their own formats (`Rs. 282,910.00`, `dd MMM yyyy`).

#### R2.3 Widget map

| Current | Decision |
|---|---|
| `AdaptiveHeader` (agents, settings) | DELETED, replaced by `LargeTitleScaffold` (the desktop and mobile branches both go) |
| `_DesktopHeader`, `_MobileHeader` | DELETED |
| `AdaptiveContent` (6 form screens) | DELETED; forms become full height sheets or pushed screens, one width (360 dp minimum), margin 20 |
| `GradientAppBar`, `GradientContainer`, `GradientButton` | DELETED (already unused) |
| `AppColors` | aliases only during migration, then DELETED |
| `AppTheme` | DELETED, replaced by `RigTheme` |

Deletion order: gradient entries and the three Gradient widgets first (zero references), then `AdaptiveHeader` after Agents and Settings migrate, then `AdaptiveContent` after the six forms migrate, then the `AppColors` aliases when `grep -rn "AppColors\." lib` returns 0 outside the file. The cleanup commit records the grep and `flutter analyze` evidence.

State table (foundation): Default = themed widgets; Loading = `Skeleton` (grey rounded boxes, no shimmer required); Empty = `EmptyState`; Error = `ErrorBanner`; Disabled = control at 38 percent opacity.

Motion: 200 to 350 ms ease-out for sheets, alerts, ring and bar reveal, tab fade; pressed feedback is the ink overlay (`pressOverlay`), no scale; zero duration under `MediaQuery.disableAnimationsOf`.

### R3. Logic touchpoints and LR items

Untouched: Hive, providers and services are not referenced from these files; `registerAppLicenses()` and the license asset declaration; `PlatformHelper` stays (frozen desktop code still reads it). During migration `AdaptiveHeader(title, subtitle, actions, bottom)` and `AdaptiveContent(child, maxWidth)` remain valid so screens migrate one by one; macOS code that uses them keeps compiling until the final cleanup (verified by `flutter analyze` only, answer 15).

| Id | Dependency | Status |
|---|---|---|
| LR-23, LR-35 | the two themes and the stored Appearance choice | approved |
| LR-24 | `RigFormat.money` is the single formatter; the Account Ledger default number style and date format change (rupee sign, `d MMM yyyy`) | approved for the rupee sign; date default to confirm (Q-O8) |
| LR-13, LR-30 | `ftq` display rule, input limit | LR-13 decided (one decimal, trailing .0 hidden), LR-30 proposed |
| answer 3 | compact only in `MoneyTile` and Portfolio metric cards | approved |
| L2-r4-4 | whether macOS-only code that imports `AppColors` or `AdaptiveHeader` (desktop shell) may keep a frozen copy of the old alias layer so the macOS build still compiles after the final cleanup | proposed, new (see temp/design_wip/logic2_r4.md) |

### R4. Acceptance criteria delta

1. Replaces old 1 and 8: `RigTheme.light` and `RigTheme.dark` are each built once (`static final`); changing the five accent roles in one place recolours buttons, selected states, links, the ring and the switch tint; the money and category colours do not change.
2. Replaces old 2: every text and background pair in both themes passes 4.5:1 (3:1 large text and icons) for the tokens in TOKENS.md section 5; the check is repeated by `qa/shoot.mjs` in the mockup and by a Flutter golden or unit contrast test over `RigColors` pairs.
3. An unstyled default `AppBar` (license page) has a legible title and back arrow in light and dark.
4. No lavender Material tint: all `surfaceContainer*` roles are defined; menus, dropdowns and the date picker use them.
5. `grep -rn "Colors\.\(red\|green\|blue\|orange\|purple\|brown\|grey\|indigo\|teal\|cyan\)" lib` returns 0 and `grep -rn "Color(0x" lib` returns only the theme file; `withOpacity` count drops to 0.
6. `GradientAppBar`, `GradientContainer`, `GradientButton`, `AdaptiveHeader`, `AdaptiveContent`, `AppColors` gradient entries and `AppTheme` are removed when their reference counts reach 0; `flutter analyze` is clean.
7. Every amount uses Inter with tabular figures; digits do not shift width when values change.
8. `RigSwitch` and `RigCheck` are themed Material `Switch` and `Checkbox` with 48 dp tap targets; `RigSnack` shows the same capsule in both themes with no per-call background colour.
9. At text scale 130 and 200 percent the large title and the inline title do not clip (single line ellipsis for the inline 17 sp title; the large title wraps to two lines).
10. Dark canvas is true black `#000000`; cards `#1C1C1E`; no card borders in dark; card shadow in light only.

### R5. Parity delta

Changes on purpose (theme-level): lines 62 and 63 (accent system blue, legible default app bars in both themes); every `Rs.` outside the PDF and CSV exports becomes the rupee sign through `RigFormat.money` (LR-24); every UI "Vehicle" becomes "Rig". Must stay identical: the numbers shown, PDF and CSV content (including `Rs.` text inside the PDF), the Export screen summary strings, snackbar message strings.

### R6. Performance and Android notes

- `static final` themes; `RigColors` const-constructible with `lerp`; fixed `const` holders for spacing, radius and motion.
- No `BackdropFilter` inside scrolling content; the glass blur toggle is one flag, default OFF, solid 94 percent surfaces with a hairline; profile on the reference device (not yet named, Q-O4) before enabling.
- Remove the shadowed `Container` cards (about 27) in favour of `RigCard` with a single const `BoxShadow` in light and none in dark; avoid `ClipRRect` plus shadow stacks per row (clip once per `RigGroup`).
- Inter: four static weights (or one variable file if 400 to 700 is verified) keep the size small; tabular figure feature constant shared.
- Use `MediaQuery.viewPaddingOf`, `viewInsetsOf`, `textScalerOf` and `disableAnimationsOf` (never `MediaQuery.of`) so keyboard and scale changes rebuild only what needs it; read the bottom inset, never hard code 24.
- `InkSparkle.splashFactory` on Android 12 and above, `InkRipple` fallback; no scale animation on press.
- Budgets: p90 build and raster under 8 ms, p99 under 16 ms, janky under 2 percent, tab switch under 100 ms.
