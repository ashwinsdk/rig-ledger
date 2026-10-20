> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# desktop_shell.dart (macOS shell)

File: `lib/features/navigation/desktop_shell.dart`, 807 lines. Desktop only. Contains `DesktopShell`, `_DesktopTitleBar`, `_SyncIndicator`, `_DesktopSidebar`, `_SidebarItem`, `_ShortcutHint`, `_DesktopPageContent`, `_DesktopContentWrapper`, the macOS `PlatformMenuBar` and the add-entry dialog.

## 1. Purpose and primary user task

Window chrome and navigation for macOS: switch areas (sidebar), switch rig (title bar), see and trigger sync, add an entry (button or Cmd+N), reach everything by keyboard.

## 2. Current structure

- `DesktopShell` (ConsumerStatefulWidget, `WindowListener`): `PlatformMenuBar > CallbackShortcuts > Focus(autofocus) > Scaffold > Column[_DesktopTitleBar (52 px gradient, draggable), Expanded Row[_DesktopSidebar (200 px), VerticalDivider, Expanded(_DesktopPageContent)]]`.
- Starts periodic sync (10 min) and an initial `syncNow()` in `initState`.
- Title bar: 78 px spacer for traffic lights, title "RigLedger" 16 sp, `_SyncIndicator`, spacer, rig switcher `PopupMenuButton<Vehicle>` (only when `vehicles.length > 1`, else plain name), 16 px right padding.
- Sidebar: 5 `_SidebarItem`s (Ledger, Portfolio, Agents, Account Ledger, Settings) with hover state, a "New Entry" `ElevatedButton.icon` and three shortcut hints (the first says `Cmd 1-4`, but there are five tabs).
- Content: `IndexedStack` of the five screens, each wrapped in `_DesktopContentWrapper`, which only removes `MediaQuery` padding; despite its doc comment it does NOT constrain width.
- Keyboard: Cmd+1 to 5 set `desktopNavIndexProvider`; Cmd+N `_handleAdd`; Cmd+F registered with an empty body; Cmd+S `syncNow()`.
- Window: 1280 x 820 default, 900 x 600 minimum, hidden native title bar.

## 3. Problems found

1. Rig switch handler on desktop (lines 107-118) calls `setCurrentVehicle(vehicle)` without `await` and then refreshes providers immediately; it also does not clear the search and filter as the mobile sheet does and does not refresh `currentVehicleProvider`. See BUGS_FOUND.md B-01 (stale data risk) and B-02.
2. Sidebar hint says `Cmd 1-4` while Cmd+5 exists (desktop_shell.dart:648).
3. Cmd+F is registered but empty (line 362); the user sees no response (known, BACKLOG.md).
4. Switching tab by Cmd+2 does not run the Portfolio refresh that a click runs (lines 124-132 vs the shortcut map): two paths, different behavior.
5. `_DesktopContentWrapper` does not constrain width: at 1280 px wide the ledger cards stretch about 1050 px, forms stretch (CONVENTIONS.md says forms are max 700 px).
6. Title bar gradient, 16 sp title, 13 sp rig text white on gradient (#618DCE end stop is under 3.4:1 for the rig name at 80 percent alpha).
7. Rig icon in the title bar is `Icons.directions_car` while mobile uses `precision_manufacturing` / `construction`; label strings differ ("Switch vehicle" tooltip vs "Switch Vehicle" sheet).
8. The sidebar is 200 px fixed; at the 900 px minimum window it takes 22 percent of the width and the page content gets 700 px. No collapse.
9. Sidebar items (`_SidebarItem`, lines 660-730) use a `MouseRegion` hover only: no `InkWell`, no `Focus`, no semantics, so they cannot be reached or activated with the keyboard (Tab) and a screen reader does not see a button.
10. The sidebar "New Entry" button is always visible but `_handleAdd` (lines 249-272) does nothing on Portfolio (index 1), Agents (2, comment says the screen has its own add button) and Settings (4): a visible button that silently does nothing. Cmd+N has the same dead cases. See BUGS_FOUND.md B-06.
11. The title bar has no search or global actions; the macOS native menu has File, View, Window entries but window controls are the system ones (fine).
12. Material ancestor: the two-pane Account Ledger needed a Material wrapper fix already (MEMORY.md); keep a `Material(color: background)` at the content root.
13. Dialog and sheet usage: add-entry options use `showDialog` with hand-built `_buildAddOption` rows (lines 281-340): another copy of the main_navigation chooser.

## 4. Redesign

### 4.1 Window frame

- Title bar: 52 px stays (traffic lights), flat `headerSurface` (or the optional `headerGradient`, question Q-Brand), title "RigLedger" `titleMedium` `onPrimary`, `RigSyncChip` (text label "Synced 2 min ago" / "Syncing" / "Sync failed", not color alone), spacer, `RigSwitcher` (popup, `MenuAnchor`), 16 px right padding. Drag area is the whole bar except controls.
- Sidebar: 200 px at window width 1000 or more; 72 px icon-only (tooltip labels) between 900 and 1000 px; `RigSidebar` items 44 px high, radius md, selected = `primaryContainer` background with `primary` icon and text, hover `surfaceContainerHigh`, 2 px `primary` focus ring, labels `labelLarge`. Items: Ledger, Portfolio, Agents, Accounts, Settings (same words as mobile). Shortcut hints become tooltips plus a collapsed "Keyboard shortcuts" row (shows `Cmd 1-5`, `Cmd N`, `Cmd S`, `Cmd F`).
- "New Entry" button: keep the label, tooltip describes the target ("Add bill", "Add purchase", "Add entry" for Accounts). It is rendered DISABLED (greyed, tooltip "Nothing to add here") on Portfolio, Agents and Settings instead of silently doing nothing, which preserves the current behavior (no action) but removes the false affordance. Filled button on Ledger and Accounts, tonal elsewhere.
- Content: `_DesktopContentWrapper` becomes `RigScaffold`'s `maxContentWidth` (1100 for dashboards and lists, 640 for forms) centered, with `background` fill; the header bands may extend full width.

### 4.3 Keyboard and menu (existing set only)

Cmd+1..5 switch areas through one function (so the Portfolio refresh runs for both click and shortcut, same refresh calls); Cmd+N, Cmd+S unchanged; Cmd+F focuses the inline search field on the Ledger tab (needs approval, B-05). Esc closes dialogs. Tab order: title bar controls, sidebar, content.

### 4.4 State table (sidebar item)

| State | Look |
|---|---|
| Default | `onSurfaceVariant` icon and text |
| Hover | `surfaceContainerHigh` fill |
| Focus | 2 px `primary` ring |
| Selected | `primaryContainer` fill, `primary` text, bold |
| Disabled | none |

### 4.5 Motion

Sidebar collapse width animates 200 ms; selection fill 150 ms; no page transition between areas.

## 5. Logic touchpoints that must stay untouched

`desktopNavIndexProvider`, `homeTabIndexProvider`, `currentVehicleProvider.setCurrentVehicle`, `vehiclesProvider`, the eight provider `refresh()` calls, `syncProvider` (`startPeriodicSync`, `syncNow`), `WindowListener.onWindowClose` (`windowManager.destroy`), `windowManager` drag, the `PlatformMenuBar` menu items and their callbacks, keyboard shortcut set and their effects, `_handleAdd` branching, form screen constructors.

## 6. Acceptance criteria

1. Window 1280 x 820: title bar 52 px, sidebar 200 px, content centered at max 1100 px; at 900 x 600 the sidebar is 72 px and content never needs horizontal scroll.
2. Each of Cmd+1..5 shows the right area and runs the same refresh as a click.
3. Rig switcher lists all rigs when there are two or more; picking one shows that rig's data in every area (parity with mobile).
4. Sync chip shows text, not color only; clicking it triggers a sync (as today).
5. Tab key reaches title bar controls, then sidebar items (focus ring visible), then content.
6. The hint text lists Cmd 1-5.
7. Forms are centered at a maximum of 640 px.
8. Contrast of all title bar text is at least 4.5:1.

## 7. Performance notes

- `build` watches `desktopNavIndexProvider`, `homeTabIndexProvider`, `currentVehicleProvider`, `vehiclesProvider` at the top: split the title bar, sidebar and add-button into leaf `Consumer`s so changing the home tab does not rebuild the whole shell.
- `IndexedStack` keeps five screens alive (decision D-1).
- `_buildMacOSMenus` and `_buildKeyboardShortcuts` are rebuilt on every build; cache them (const where possible) or build once in `initState`.
- Window drag uses `onPanStart`; keep it on a thin `GestureDetector` rather than the whole bar subtree to avoid hit-test cost.


## Reconciliation 2026-10-13 (Apple look, Android only)

STATUS: `lib/features/navigation/desktop_shell.dart` is FROZEN. It is not edited and not deleted by the revamp, and the WHOLE redesign proposed in sections 4 to 7 above (title bar, 72 px and 200 px sidebar, `RigSidebar`, `RigSyncChip`, max content width 1100 and 640, disabled New Entry states, Cmd+1 to 5 unification, the `Cmd+F` handler, `MenuAnchor` rig popup, focus rings, hover states, window size budgets) is DROPPED. The old text above is kept only as the record of what was audited; no task in MIGRATION_PLAN.md may implement it. The macOS app keeps building from the unchanged shell; its fate (keep, archive, delete) is the separate later decision D-08 (Q-O9). Sections 1 to 3 above stay valid as a description of the current code.

### R1. Mockup screens and Flutter mapping

No mockup screen corresponds to this file: the mockup has no sidebar, title bar, window or desktop layout (it is Android only, portrait, 360 to 412 dp wide).

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| none | none | `lib/features/navigation/desktop_shell.dart` | none (frozen) | the Android counterpart is `main_navigation.dart` (see main_navigation.md) |

### R2. What changes in the redesign (supersedes section 4)

Nothing changes in this file. Behaviours of the shell that the Android RigTabBar (see main_navigation.md R2) replaces on Android, shown so the audit is not lost:

| Desktop shell behaviour | Android replacement |
|---|---|
| Sidebar with 5 items (Ledger, Portfolio, Agents, Account Ledger, Settings) | floating RigTabBar capsule, 5 items, labels Ledger, Portfolio, Agents, Accounts, Settings |
| `desktopNavIndexProvider` and Cmd+1 to 5 | local `_currentIndex` in `MainNavigation`; no shortcuts |
| Sidebar "New Entry" button and `_handleAdd` | Add button in the Ledger large title row, same routing |
| Add dialog `_buildAddOption` rows | RigSheet add chooser with gradient CategoryTiles (main_navigation.md) |
| Title bar rig switcher (`PopupMenuButton<Vehicle>`) | RigRigSheet opened from the rig pill in the Ledger and Portfolio headers, running `switchRig` |
| Title bar sync indicator and periodic sync start | not part of the Android shell; sync is started where it is today on Android (unchanged) |
| Content wrapper max width, two-pane Account Ledger | none (portrait phone only) |
| `PlatformMenuBar`, `windowManager`, window listener | none on Android |

Shared bits that MOVE (they leave the frozen file's neighbourhood and live in new Android files without editing `desktop_shell.dart`):
1. Add chooser sheet: a new RigSheet widget is written for `main_navigation.dart`. The desktop `_buildAddOption` copy stays where it is.
2. Rig switch: the new shared function `switchRig(ref, vehicle)` (LR-01) is called by the Ledger and Portfolio rig sheets. `desktop_shell.dart` is NOT changed to call it, so its own handler (without `await`, B-01, B-02) stays as is on macOS; that known difference is accepted while the shell is frozen.
3. `homeTabIndexProvider` stays declared in `main_navigation.dart` (the frozen shell imports it at line 24 and reads it at lines 83, 186, 366). Moving or renaming it is forbidden.

The shared screens (`CombinedHomeScreen`, `StatsScreen`, `AgentsScreen`, `CashbookRootScreen`, `SettingsScreen`, the form screens) are hosted by this shell. When they get the Apple look they will also render on macOS inside the old shell without a floating tab bar, inside a window wider than 900 dp. That is accepted and out of scope: macOS only has to keep compiling (`flutter analyze`), there is no macOS visual acceptance.

### R3. Logic touchpoints and LR items

Untouched: everything in section 5 above, because the file is not edited. LR-14 (Cmd+F handler) and LR-15 (desktop shortcuts) are DROPPED. LR-01 `switchRig` is approved but applies only to the Android call sites. Proposed, new: none.

### R4. Acceptance criteria delta

1. `git diff` of a revamp task never lists `lib/features/navigation/desktop_shell.dart`, `macos/`, `desktop_auth_service.dart` or any `PlatformHelper.isDesktop` branch.
2. `flutter analyze` stays clean after each task (the frozen shell must still compile against the changed shared screens and providers: constructors of `CombinedHomeScreen`, `StatsScreen`, `AgentsScreen`, `CashbookRootScreen`, `SettingsScreen`, `LedgerFormScreen`, `SideBoreFormScreen`, the four side forms and `homeTabIndexProvider` keep their current signatures).
3. Sections 6 items 1 to 8 above are DROPPED.

### R5. Parity delta

All P-DSK lines are DROPPED from the revamp parity run (macOS is not run). Android parity lines are unaffected.

### R6. Performance and Android notes

Section 7 above is DROPPED (macOS budgets removed, answer 21). No Android impact: the file is not compiled into the Android UI path (`main.dart` picks the shell by platform; do not change that).
