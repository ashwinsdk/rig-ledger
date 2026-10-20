> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# main_navigation.dart (Android shell) and the add-entry chooser

File: `lib/features/navigation/main_navigation.dart`, 245 lines. Mobile only (`main.dart` picks `DesktopShell` on desktop). Also defines `homeTabIndexProvider`.

## 1. Purpose and primary user task

Move between the five top-level areas (Ledger, Portfolio, Agents, Accounts, Settings) and start a new entry from the Ledger area.

## 2. Current structure

- `MainNavigation` (ConsumerStatefulWidget, local `_currentIndex`): `Scaffold(body: IndexedStack(5 screens), floatingActionButton: only when index 0, bottomNavigationBar: Container(shadow) > SafeArea > BottomNavigationBar)`.
- Screens in the stack: `CombinedHomeScreen`, `StatsScreen`, `AgentsScreen`, `CashbookRootScreen`, `SettingsScreen`. All five stay alive (IndexedStack): state is retained, but every tab's providers keep rebuilding while hidden.
- FAB: Ledger tab opens `LedgerFormScreen` or `SideBoreFormScreen` (by `currentVehicleProvider.vehicleType`); Side Ledger tab opens `_showAddSideLedgerSheet` (modal bottom sheet with 4 options: Diesel, PVC, Bit, Hammer, `Icons.local_gas_station`, `Icons.plumbing`, `Icons.settings`, `Icons.hardware`) which pushes the matching form.
- Tapping Portfolio (index 1) calls `refresh()` on ledger, diesel, pvc, bit, hammer providers (lines 90-97).
- Labels: Ledger, Portfolio, Agents, Accounts, Settings.

## 3. Problems found

1. `BottomNavigationBar` inside a shadow `Container` is a Material 2 pattern; Material 3 is enabled (`useMaterial3: true`) so the selected state has no indicator pill and the shadow duplicates the elevation (main_navigation.dart:70-80, app_theme.dart bottomNavigationBarTheme).
2. The label for the same destination differs by platform: "Accounts" (mobile) vs "Account Ledger" (desktop sidebar), and the screen's own title differs again.
3. Icons mix outlined and filled (inactive `_outlined`, active filled): fine for state but the rest of the app uses default filled; one rule is needed (DESIGN_SYSTEM.md section 9).
4. The FAB has no label or tooltip, and it opens different things on different tabs (a form vs a chooser sheet) without a visual hint. It is also not shown on Portfolio/Agents (Agents has its own add control).
5. Add chooser sheet: icons for Bit (`Icons.settings`, a gear) and Hammer (`Icons.hardware`) differ from the icons used on the category tiles (`Icons` for bit tile is a circle-style icon in screenshot 05), so one concept has two symbols.
6. `setState` on tab tap rebuilds the whole shell; the `refresh()` calls on Portfolio switch hide a data-freshness problem (the Portfolio should read live providers) and run on the UI thread each tap.
7. Android system UI is immersive sticky (ARCHITECTURE.md): the bottom bar is the only persistent chrome; with the redesigned collapsing header (B4) the nav bar stays pinned.
8. Orientation locked to portrait; no landscape or tablet layout (an expanded layout is out of scope unless approved, see questions: Platform).
9. 5 labels at 12 sp (`labelSmall`) with `type: fixed`; at 200 percent text scale labels truncate ("Portfolio" and "Accounts" at 411 dp).

## 4. Redesign

### 4.1 Shell

- `RigNavigationBar` (M3 `NavigationBar`): height 80 dp, 5 destinations, labels always shown (`labelSmall` 11 sp w500; the floor), indicator `primaryContainer` 64 x 32 pill, icons 24 dp rounded (`Icons.menu_book_rounded`, `Icons.pie_chart_rounded`, `Icons.groups_rounded`, `Icons.account_balance_wallet_rounded`, `Icons.settings_rounded`; selected uses the same icon, state conveyed by indicator and `primary` color), background `surface`, top border 1 px `outlineVariant`, no shadow. At text scale over 130 percent, labels use `NavigationDestinationLabelBehavior.onlyShowSelected` so nothing truncates.
- Labels unified across platforms: Ledger, Portfolio, Agents, Accounts, Settings. Desktop sidebar uses the same words (the full name "Account Ledger" stays as the page title). Decision needed in the final questions (Brand/Scope).
- Body: keep `IndexedStack` (state retention is a decision, see PERFORMANCE.md section 4). The shell holds only `_currentIndex`; use a `ValueNotifier<int>` or keep `setState` (rebuilds only the shell, children are `const`).
- FAB: 56 dp, `primary`, `Icons.add_rounded`, tooltip "New entry" (Ledger tab) and "Add purchase" (Side Ledger tab), semantics label the same. Position above the nav bar with 16 dp margin, bottom list padding 88 dp. When the keyboard is up it hides (default).

### 4.2 Add chooser (Side Ledger FAB)

`RigSheet` titled "Add to Side Ledger", four `RigListRow`s (leading 40 dp tinted icon in the category container color, title, chevron), min row height 56, in the same order as today (Diesel, PVC, Bit, Hammer; PVC hidden for side bore as today). Icons identical to the Side Ledger category tiles (one icon per concept). Desktop uses the same list in a `RigDialogShell` (max 360).

### 4.3 State table

| State | Behavior |
|---|---|
| Default | 5 destinations, current selected |
| Pressed | ripple inside indicator |
| Disabled | none |
| Badge | none (no new feature) |

### 4.4 Motion

Destination change: indicator slides 200 ms (built in), body switches instantly (IndexedStack, no cross-fade) to avoid fighting scroll positions.

## 5. Logic touchpoints that must stay untouched

`homeTabIndexProvider` (declared here, written by `CombinedHomeScreen`), `currentVehicleProvider` (vehicle type decides which form opens), the destination order (indices 0 to 4 are referenced by name in ARCHITECTURE.md and by `desktopNavIndexProvider`), the `refresh()` calls on tapping Portfolio, form screen constructors, FAB visibility rule (index 0 only).

## 6. Acceptance criteria

1. Five destinations with the same labels and order as before; selection state shows the indicator pill.
2. Tapping each destination shows the same screen as today; state of each tab is retained when returning.
3. Tapping Portfolio still refreshes the five listed providers.
4. The FAB appears only on Ledger; on the Ledger tab it opens the right form for main bore and side bore rigs; on Side Ledger it opens the chooser, which lists PVC only for main bore rigs.
5. At 200 percent text scale no label is truncated mid-word (only selected label shown).
6. Nav bar and FAB do not cover the last list row (88 dp padding).
7. TalkBack reads "Ledger, tab 1 of 5, selected".

## 7. Performance notes

- `NavigationBar` removes the extra shadow `Container`. Shell stays small; screens are `const`.
- IndexedStack keeps five heavy screens alive; see PERFORMANCE.md decision D-1.
- Avoid rebuilding the shell when `homeTabIndexProvider` or `currentVehicleProvider` change: today `build` watches both (lines 38-39) only for the FAB; move the FAB into its own `Consumer`.


## Reconciliation 2026-10-13 (Apple look, Android only)

Mockup source: `render` (the `#nav` capsule and the `NAV` array), `fabTap`, `addEntrySheet`, `rigSheet` in `docs/design/mockup/rigledger_apple_mockup.html`. The Material `NavigationBar` of section 4.1 is REPLACED by the floating RigTabBar. The FAB is DROPPED (the Add action moves into the large title row). Desktop labels and `desktopNavIndexProvider` stay frozen and are not part of this redesign.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Home (Ledger, Daily) (the tab bar is on every root tab) | `render` + `#nav` | `lib/features/navigation/main_navigation.dart` | RigTabBar (floating capsule, 5 tabs), `IndexedStack` kept | hidden on pushed screens and while the keyboard is open |
| Add Entry sheet | `addEntrySheet` | `main_navigation.dart` (`_showAddSideLedgerSheet`) | RigSheet, CategoryTile 2 x 2 | shared with `desktop_shell.dart`'s chooser only by design, not by code (frozen) |
| Switch Vehicle sheet | `rigSheet` | `lib/features/home/combined_home_screen.dart` and `lib/features/stats/stats_screen.dart` | RigRigSheet | the sheet is shared by the Ledger and Portfolio headers; `switchRig` (LR-01) |
| Rig sheet from Portfolio (B1) | `rigSheet` | same | RigRigSheet | see portfolio.md |

### R2. What changes in the redesign (supersedes section 4)

RigTabBar (REPLACES 4.1):
- A capsule 62 dp high, 16 dp side margin, floating `viewPaddingOf.bottom + 8` dp above the bottom, radius 31, fill `barSolid` (94 percent surface) with a 1 dp `sep` border and `RigElevation.bar` shadow, padding 4. It is an overlay inside a `Stack` over the body (not `bottomNavigationBar`), `extendBody` content scrolls under it. With the Glass blur toggle ON (default OFF) the fill is `glassBar` with one `BackdropFilter` clipped to the capsule.
- Five equal items in the existing order and labels: Ledger (`book`), Portfolio (`pie_chart`), Agents (`people`), Accounts (`account_balance_wallet`), Settings (`settings`), rounded icons 26 dp over an 11 to 12 sp label. Selected item: `glassSelected` capsule fill with `accentText` icon and label, others `lb2`. Each item is at least 48 dp wide and 54 dp tall.
- At text scale 190 percent and above the labels of unselected items are hidden (selected label only) so nothing truncates.
- Hidden when a screen is pushed over the shell and while the keyboard is open (`viewInsetsOf.bottom > 0`, conflict C-13); screens reserve `62 + viewPaddingOf.bottom + 8 + 24` at the end of their lists.
- Labels are one set: Ledger, Portfolio, Agents, Accounts, Settings (the desktop sidebar is frozen and unchanged).

Body: `IndexedStack` kept for Ledger and Accounts (built at launch, Q-O3). Portfolio, Agents and Settings are lazy: built the first time their tab is selected, then kept alive (a lazy-stack wrapper: a `List<bool> visited`; unvisited children are `SizedBox.shrink`; `AutomaticKeepAliveClientMixin` is not needed with `IndexedStack`). The shell holds only `_currentIndex` (`ValueNotifier<int>`).

Add action (REPLACES the FAB of 4.1): no FAB. The Ledger tab large title row has an Add glass button (48 dp, `add`, tooltip "Add entry", semantics the same) with the same routing: Ledger sub-tab opens `LedgerFormScreen` or `SideBoreFormScreen` by `currentVehicleProvider` type; Side Ledger sub-tab opens the chooser. It is not shown on other tabs (Agents keeps its own add button in its title row). Footer padding of lists no longer needs 88 dp for a FAB.

Add chooser (REPLACES 4.2): `RigSheet` titled "Add Entry", `CategoryTile` 2 column grid (gap 12, min height 104, radius 28, gradient, black `onTile` label, icon 28): Diesel (`local_gas_station`, `catDiesel`), PVC (`plumbing`, `catPvc`, hidden for side bore), Bit (`circle`, `catBit`), Hammer (`hardware`, `catHammer`). One icon per concept, identical to the Side Ledger category tiles. Selection pushes the matching form as today.

Portfolio tab tap: the `refresh()` calls on the five providers stay (section 5), run after the tab switch frame, not before it.

States: Default 5 items, current selected. Pressed: ink `pressOverlay` inside the item. Disabled: none. Badge: none. Keyboard open: hidden. Pushed screen: hidden.

Motion: selected capsule slides 200 ms ease-out; body switches instantly (no cross-fade); instant under reduced motion.

Old section 4 mapping: 4.1 shell CHANGED (RigTabBar), label unification KEPT, FAB DROPPED, 4.2 chooser CHANGED (tiles instead of rows, desktop `RigDialogShell` variant DROPPED), 4.3 state table CHANGED, 4.4 motion KEPT with new values.

### R3. Logic touchpoints and LR items

Untouched: `homeTabIndexProvider`, `currentVehicleProvider` (vehicle type picks the form), destination order (indices 0 to 4), the `refresh()` calls on Portfolio tap, form constructors, FAB visibility rule (Ledger tab only) now applied to the Add button. 

| Item | Status |
|---|---|
| LR-01 `switchRig` (shared by Ledger and Portfolio rig sheets) | approved |
| Lazy tabs for Portfolio, Agents, Settings | approved (answer 12), not a logic change; parity lines in PARITY_CHECKLIST.md |
| Q-O3 lazy Accounts | open, default: Accounts built at launch |
| Q-O6 back on a root tab | open, default per the brief: `PopScope(canPop: false)` swallows back |
| Proposed, new | none |

### R4. Acceptance criteria delta

1. Five items, same order and labels; selected item shows the `glassSelected` capsule; tap changes the screen; state of visited tabs is retained.
2. RigTabBar is 62 dp high, 16 dp from each side, floating `viewPaddingOf.bottom + 8` dp above the bottom; with 3-button navigation (inset 0) and with gesture navigation (inset 24) the last list row is not covered.
3. Opening the keyboard hides the tab bar; closing it restores it.
4. The tab bar is not shown on pushed screens (forms, About, Export) and returns on back.
5. Portfolio, Agents and Settings are not built until first selected; after the first visit their scroll offset and state are retained.
6. Add button: shown only on the Ledger tab; opens the right form (main bore or side bore) or the chooser (PVC absent for side bore).
7. 200 percent text: no label is truncated mid-word.
8. TalkBack reads "Ledger, tab 1 of 5, selected".
9. Back on a root tab does nothing; back on a pushed screen pops it (forms with edits ask first, LR-25).
10. Light and dark: capsule border and shadow are visible in both; selected label meets 4.5:1.

### R5. Parity delta

Changed on purpose: P-NAV-3 (FAB replaced by the Add button in the title row), P-NAV-1 look only, tabs lazy (P-NAV-2 now also checks that unvisited tabs are not built), Add chooser look (P-NAV-5 same options and order, PVC absent for side bore).
Identical: P-NAV-1 order and labels, P-NAV-2 retained state, P-NAV-4 routing, P-NAV-5 options, P-NAV-6 Portfolio refresh, P-NAV-7 portrait lock. P-DSK lines are DROPPED with macOS.

### R6. Performance and Android notes

- The shell rebuilds only on `_currentIndex`; the tab bar is a small `ValueListenableBuilder`; the Add button lives in the Ledger screen, not in the shell, so `currentVehicleProvider` no longer rebuilds the shell.
- Lazy tabs cut the cold-start cost (target cold start under 2 s, tab switch under 100 ms).
- Insets: `MediaQuery.viewPaddingOf(context).bottom` read per build of the bar; never hard-code 24. System bars transparent, edge to edge.
- Keyboard: the bar is hidden by `viewInsetsOf.bottom > 0` without animating layout of the body.
- Back: a root `PopScope(canPop: false)`; predictive back needs `android:enableOnBackInvokedCallback` (T-A12).
- No `BackdropFilter` unless the blur toggle is on; one saveLayer for the capsule at most.
