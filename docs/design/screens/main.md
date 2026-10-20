> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# main (lib/main.dart, 165 lines)

App entry: `main()`, `_requestPermissions()`, `RigLedgerApp`, `_RigLedgerAppState`. Theme itself is in `lib/core/theme/app_theme.dart` and is specified in screens/core_theme_and_widgets.md. This doc covers startup, window, system chrome, MaterialApp configuration and the lifecycle sync hook.

## 1. Purpose and primary user task

Start the app fast and reliably on Android and macOS, load the local database, choose the right shell (mobile `MainNavigation` or desktop `DesktopShell`), and keep Google Drive sync running (on launch, every 5 minutes, and on app resume). The user task is "open the app and see my ledger" with no waiting on anything that needs the network.

## 2. Current structure

`main()` (22), all awaited in this order before the first frame:
1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Mobile: portrait-only orientations, `SystemUiMode.immersiveSticky` (system bars hidden, swipe to reveal).
3. Desktop: `windowManager.ensureInitialized()`, `WindowOptions(size 1280 x 820, minimumSize 900 x 600, center, backgroundColor: transparent, skipTaskbar: false, titleBarStyle: hidden, title 'RigLedger')`, `waitUntilReadyToShow` then `show()` and `focus()`.
4. `Hive.initFlutter()`, `registerAppLicenses()`, `DatabaseService.initialize()`, `PaymentLinkService.reconcileAll()`.
5. Android: `_requestPermissions()` (SDK 33+ nothing; 30-32 `MANAGE_EXTERNAL_STORAGE`; below 30 storage) which can show a system permission screen BEFORE the first frame.
6. `SyncService.initialize()` then `GoogleDriveService.initialize()` (silent Google sign-in, a network call).
7. `runApp(ProviderScope(child: RigLedgerApp()))`.

`RigLedgerApp` (ConsumerStatefulWidget, 114): `WidgetsBindingObserver`; `initState` triggers `_triggerSync` (only when `GoogleDriveService.isSignedIn`) and `syncProvider.notifier.startPeriodicSync(interval: 5 minutes)`; `didChangeAppLifecycleState(resumed)` triggers sync; `dispose` removes the observer and `stopPeriodicSync`. `build` returns `MaterialApp(title: 'RigLedger', debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme, home: DesktopShell | MainNavigation)`.

## 3. Problems found

1. Blank first launch: nothing is drawn until every await above finishes. On Android the OS shows the native launch window while Dart waits on `Hive.initFlutter`, `DatabaseService.initialize` (opens about 12 boxes plus schema migration plus 30 day trash purge), `reconcileAll()` (scans bills and cash entries) and the permission screen. No splash, no progress, no error state: if `DatabaseService.initialize()` throws (corrupt box) the app dies on a blank screen with no explanation.
2. Network on the critical path: `GoogleDriveService.initialize()` (59-71, google_drive_service.dart:60) awaits `signInSilently()` before `runApp`. Offline or slow network can delay the first frame (the app is advertised as 100 percent offline-first). There is no timeout visible in the service. UNVERIFIED how long `signInSilently` blocks offline; it normally returns quickly but is a network-dependent await in startup.
3. Permission request before UI (63-65): on Android 11 and 12 the `MANAGE_EXTERNAL_STORAGE` system settings screen opens before the user has seen the app, with no rationale text. (Also a store-policy risk noted in MEMORY.md.) UI-wise: needs a one-time explanation screen or request at first export, but that moves logic; recorded in logic_g3.md.
4. Window `backgroundColor: Colors.transparent` (43): on macOS the window can flash the desktop or a white/black rectangle before the first Flutter frame. The color literal is also a token violation (`Colors.*`).
5. `theme: AppTheme.lightTheme` is a getter (`app_theme.dart:7`) that builds a new `ThemeData` on every access; `MaterialApp` rebuilds (ProviderScope changes, `setState` none) are rare so cost is low, but the theme should be `static final`.
6. No `darkTheme`, no `themeMode` (light only by decision, CLAUDE.md), no `builder` to guard text scale. At OS text scale 2.0 and above many screens overflow (see each screen doc). No global clamp, so Android "largest font" plus display size can reach 3.0 on some devices.
7. No `scrollBehavior` for desktop: default `MaterialScrollBehavior` does not enable mouse drag scrolling and scrollbars are not always visible on macOS lists (DESIGN_SYSTEM section 15 requires visible scrollbars).
8. No `Shortcuts`/`Actions` at app level (desktop shell registers its own Cmd+1..5, Cmd+N, Cmd+S in desktop_shell.dart); Esc to close dialogs works by default.
9. `immersiveSticky` hides the Android navigation bar: bottom navigation sits at the screen edge; when the user swipes to reveal the system bars they overlay the bottom nav and FAB for a moment. No `SafeArea` strategy is specified globally: each screen handles insets itself (gradient headers use `SafeArea(bottom: false)`).
10. `dispose` (134-139) calls `ref.read(syncProvider.notifier)` after `removeObserver`; reading `ref` in `dispose` of a `ConsumerState` is fragile (UNVERIFIED with the Riverpod version in pubspec). Not a visual issue.
11. Sync visibility: sync runs silently on launch, every 5 minutes and on resume with no UI beyond the status chip in the desktop title bar (`syncProvider`); Android has no visible indicator in the shell (outside this file). Relevant here because the app root owns the trigger.
12. Accessibility defaults: no `MaterialApp.title`-based semantics issue; `debugShowCheckedModeBanner` false fine.
13. `RigLedgerApp` is a `ConsumerStatefulWidget` without watching anything: ok. `home:` picks the shell with `PlatformHelper.isDesktop`; on a very narrow macOS window (below the 900 minimum) not applicable.

## 4. Redesign

No logic or order change. All redesign items are UI scaffolding around the same calls.

### 4.1 Theme and app root
- `MaterialApp(theme: RigTheme.light /* static final */, themeMode: ThemeMode.light, ...)`; no dark theme until approved (DESIGN_SYSTEM section 2).
- `builder: (context, child)` wraps `child` in `MediaQuery(data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 2.0)), child: ...)`. Rule: the redesign guarantees correct layout up to 2.0; above that the clamp keeps layouts intact. (If the developer rejects the clamp, screens must still not overflow at 2.0; the clamp is an accessibility trade-off to confirm.)
- `scrollBehavior: const RigScrollBehavior()` (new class in the theme layer): enables `PointerDeviceKind.mouse` and `trackpad` drag, and `Scrollbar` always visible on desktop (`thumbVisibility: true` for desktop only).
- `title: 'RigLedger'` unchanged.

### 4.2 Startup experience (needs developer approval because it relocates initialization into a widget; the order and calls stay identical)
- Two-stage start: `main()` keeps window/orientation setup, then `runApp(ProviderScope(child: StartupGate()))` immediately; `StartupGate` runs the SAME awaited steps in the SAME order (Hive init, licenses, `DatabaseService.initialize`, `PaymentLinkService.reconcileAll`, Android permissions, `SyncService.initialize`, `GoogleDriveService.initialize`) and then swaps to `RigLedgerApp`. Drive init is allowed to complete AFTER the shell is shown only if the developer approves (it is a logic-order change); otherwise it stays in the gate.
- `StartupSplash` (new, components_g3.md): centered logo (72 dp, `assets/images/logo.png`), "RigLedger" `headlineSmall`, a 2 px indeterminate `LinearProgressIndicator` 160 dp wide, background `background` token; text under the bar changes by phase: "Opening your data" (database), "Checking sync" (Drive). Shown only if startup takes longer than 250 ms (avoid flicker); fade out 200 ms (`base`).
- `StartupErrorScreen` (new): `EmptyState(icon: Icons.error_outline_rounded, title: 'RigLedger could not open your data', hint: 'Your records have not been changed. Close and reopen the app. If this continues, restore a backup.')` with a `FilledButton` "Try again" (re-runs the gate) and a `TextButton` "Copy details" (exception text). No data-modifying action is offered.
- Permission explanation (Android 11 and 12 only, before the system screen): a `RigDialogShell` "Allow storage access?" with the sentence "RigLedger saves backups and reports to your device storage." and buttons "Not now" / "Continue". "Not now" simply skips the request (same as the catch path today); this is UI around the existing `_requestPermissions()` and is flagged for developer approval (changes when the system screen appears).

### 4.3 Window (macOS)
- `WindowOptions.backgroundColor`: opaque `RigColors.background` constant value `#F8FAFC` (static const in the theme layer, not `Colors.transparent`) so no desktop flash. `titleBarStyle: hidden`, size 1280 x 820, minimum 900 x 600, center, title 'RigLedger': unchanged.
- Window drag area, traffic lights and title bar are in desktop_shell.dart (another group).

### 4.4 System chrome (Android)
- Keep portrait lock and `immersiveSticky` (existing product decision). Add `SystemUiOverlayStyle` tied to the header: light status icons over the dark header (`SystemUiOverlayStyle.light.copyWith(statusBarColor: transparent)`) applied once in `builder`, so revealed system bars are legible.
- Global bottom inset rule: every scrollable page adds `MediaQuery.paddingOf(context).bottom + 80` bottom padding when a bottom `NavigationBar` is present (shell concern, specified in main_navigation doc).

### 4.5 Sync hook
- No visual change here. Contract for the shells: the sync status (idle, syncing, error, last time) is read from `syncProvider` and rendered by the shell chrome; this file only triggers it.

State table (startup)
| State | UI |
|---|---|
| Default | splash is skipped when startup under 250 ms |
| Loading | `StartupSplash` with phase text |
| Empty | n/a |
| Error | `StartupErrorScreen` |
| Disabled | n/a |

Motion: splash fade 200 ms; shell appears with a 150 ms fade; none when reduced motion is on.

Tokens: spacing s2 s4 s6; type headlineSmall, bodyMedium; colors background, primary, onSurface, onSurfaceVariant.

Components: `StartupSplash`, `StartupErrorScreen`, `EmptyState`, `RigDialogShell`, `RigScrollBehavior`.

## 5. Logic touchpoints that must stay untouched

- Order and content of the initialization sequence in `main()` (steps 1 to 7 above), including `PaymentLinkService.reconcileAll()` after `DatabaseService.initialize()` and `SyncService.initialize()` before `GoogleDriveService.initialize()`.
- `_requestPermissions()` branches by SDK (>= 33 none, 30 to 32 manage external storage, else storage) and the debugPrint fallbacks.
- `syncProvider.notifier.startPeriodicSync(interval: Duration(minutes: 5))`, `stopPeriodicSync()`, `syncNow()` guarded by `GoogleDriveService.isSignedIn`; resume trigger.
- Shell selection: `PlatformHelper.isDesktop ? DesktopShell : MainNavigation`.
- Window options values (sizes, hidden title bar, `skipTaskbar: false`) and `PlatformHelper.isMobile` orientation lock.
- `ProviderScope` at the root (provider overrides none today).

## 6. Acceptance criteria

1. Cold start on a device with a large database shows the splash within 300 ms of launch and the shell afterwards; with a small database no splash flicker appears (shell appears directly).
2. With Airplane mode on, the app reaches the shell without waiting on the network longer than it does today (record both timings; the gate must not be slower).
3. Forcing `DatabaseService.initialize` to throw shows `StartupErrorScreen`; "Try again" re-runs and reaches the shell once fixed; no data is modified.
4. The same initialization steps run in the same order (verify with a log of the calls); schema version and trash purge behave as before.
5. On macOS the window never shows a transparent or black rectangle at launch; first paint is `#F8FAFC`.
6. Mouse drag scrolls lists on macOS and a scrollbar is visible on long lists.
7. At OS text scale 3.0 the app text scale is capped at 2.0 and screens do not overflow.
8. Android 11 and 12: the storage explanation dialog appears before the system screen; "Not now" continues to the shell without error.
9. Sync still triggers on launch (if signed in), every 5 minutes, and on resume; leaving the app and returning triggers exactly one sync.
10. No `Colors.*` literal in `main.dart`.

## 7. Performance notes

- `static final ThemeData` once; avoid `AppTheme.lightTheme` getter rebuilds.
- `StartupGate` is a small `StatefulWidget`; the shell is constructed only after the gate finishes so `IndexedStack` children (5 screens) are not built during startup.
- Measure startup with the existing logs: Hive open, `reconcileAll` and Drive init durations should be logged in debug to find the dominant cost (instrumentation only).
- `RigScrollBehavior` and the `builder` wrapper are `const`/cheap; the `builder` must not allocate per frame beyond `MediaQuery.copyWith` (only when scale actually clamps).
- Keep `WidgetsBindingObserver` registered once; no per-frame work.

## Reconciliation 2026-10-13 (Apple look, Android only)

Dropped from the redesign: every window_manager and macOS item (section 4.3 window options, `RigScrollBehavior` for mouse drag and always-visible scrollbars, acceptance criteria 5 and 6, parity lines 60, the macOS half of line 62). The code stays exactly as it is and frozen: `windowManager.ensureInitialized()`, `WindowOptions`, `PlatformHelper.isDesktop ? DesktopShell : MainNavigation` and `DesktopShell` are read but never edited, deleted or restyled by the revamp. On Android the shell is always `MainNavigation`. Old text stays above.

### R1. Mockup screens and Flutter mapping

The mockup has no J screen for the app root. These Dev panel controls and mockup rules map to this file:

| Mockup item | Mockup source | Flutter file | Widgets and settings | Notes |
|---|---|---|---|---|
| Theme System, Light, Dark | Dev panel `dev('theme')`, `prefers-color-scheme` | `lib/main.dart` (`RigLedgerApp.build`) | `MaterialApp(theme: RigTheme.light, darkTheme: RigTheme.dark, themeMode: <themeModeProvider>)` | default System; LR-23 and LR-35 |
| Status bar 28 dp edge to edge, bottom inset 24 dp gesture or 0 dp 3-button | TOKENS.md 4b | `main()` and `builder` | `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`, `SystemUiOverlayStyle` per brightness | replaces `immersiveSticky` |
| Text scale 100, 130, 200 | Dev panel `ts` | `builder` | `MediaQuery` text scaler clamp 0.9 to 2.0 | kept from section 4.1 |
| Reduced motion | `prefers-reduced-motion` | `builder` or per widget | `MediaQuery.disableAnimationsOf(context)` | all motion 200 to 350 ms |
| System back, predictive back | Dev "System back", MOCKUP_NOTES "System back mapping" | `AndroidManifest.xml` flag, `pageTransitionsTheme` in RigTheme | `PopScope`; root `PopScope(canPop: false)` is the shell's job (Q-O6) | not this file's code, listed because the root theme sets the transitions |
| Splash and first frame | none in the mockup | `main()` startup gate | StartupSplash on `canvas`, StartupErrorScreen with EmptyState and RigButton | section 4.2 kept, needs developer approval |

### R2. What changes in the redesign (supersedes section 4)

1. App root: `MaterialApp(title: 'RigLedger', debugShowCheckedModeBanner: false, theme: RigTheme.light /* static final */, darkTheme: RigTheme.dark /* static final */, themeMode: ref.watch(themeModeProvider), builder: ..., home: MainNavigation)`. The themeMode provider reads the stored Hive settings value synchronously after `DatabaseService.initialize()` so the first frame already has the right theme (no flash from light to dark). Default System (Android 10 and up); no dynamic colour (A20).
2. Portrait lock stays: `setPreferredOrientations([portraitUp, portraitDown])`. 360 dp is the minimum width; no other orientation or width class.
3. Edge to edge: `SystemUiMode.edgeToEdge` replaces `SystemUiMode.immersiveSticky`. System bars are visible and transparent over the app; icon colours follow the effective brightness (dark icons in light, light icons in dark) through one `AnnotatedRegion<SystemUiOverlayStyle>` in `builder` with `statusBarColor` and `systemNavigationBarColor` transparent and `systemNavigationBarContrastEnforced` left at its default so the 3-button bar keeps a system scrim. Insets are read where needed with `MediaQuery.viewPaddingOf(context)` (status bar 28 dp in the mockup, bottom 24 dp with gesture navigation, 0 dp with 3 buttons plus the 48 dp bar); nothing hard codes 24.
4. Text scale: `builder` wraps the child in `MediaQuery` with `textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 2.0)`, so the tested 200 percent case is the ceiling (kept).
5. Scroll: the default Android `ScrollBehavior` (stretch overscroll); no `RigScrollBehavior`.
6. Window: none (section 4.3 dropped).
7. Startup experience (section 4.2) is KEPT with these look changes: StartupSplash uses the flat `canvas` colour (light `#F2F2F7`, dark `#000000`) matching the native launch background (`values` and `values-night` launch theme, so there is no white flash in dark), the logo 84 dp rounded tile, "RigLedger" 22 sp, a thin indeterminate progress line and phase text; shown only after 250 ms. StartupErrorScreen = EmptyState ("RigLedger could not open your data", the same hint) with RigButton filled "Try again" and a text button "Copy details". The storage explanation (Android 11 and 12) is a RigAlertDialog "Allow storage access?" with "Not now" and "Continue". All of it is UI around the same awaited calls in the same order, and needs the developer's approval because it moves initialisation into a widget.
8. Predictive back: `android:enableOnBackInvokedCallback="true"` in the manifest and `PredictiveBackPageTransitionsBuilder` in `RigTheme.pageTransitionsTheme`; routes use `PopScope` rather than `WillPopScope`. A native config and theme change, no logic.
9. Sync hook: unchanged. A visible sync status is read from `syncProvider` by the Settings Drive card (settings_screen.md) and no new chrome is added.

State table (startup): Default = splash skipped under 250 ms; Loading = StartupSplash with phase text; Empty = not applicable; Error = StartupErrorScreen; Disabled = not applicable.

Motion: splash fade 200 ms, shell fade 150 ms, route transitions per Android default (200 to 350 ms ease-out); all zero under reduced motion.

Old section 4 items:

| Old item | Verdict |
|---|---|
| 4.1 theme `light` only, `themeMode: ThemeMode.light` | CHANGED (light, dark, `ThemeMode.system` by default, LR-23) |
| 4.1 text scale clamp 0.9 to 2.0 | KEPT |
| 4.1 `RigScrollBehavior` (mouse, scrollbars) | DROPPED (desktop) |
| 4.2 StartupGate, StartupSplash, StartupErrorScreen, storage explanation | KEPT (look reconciled above; approval still needed) |
| 4.2 Drive init may finish after the shell | KEPT as an open decision (logic order change, L3 L-16) |
| 4.3 window `backgroundColor` opaque `#F8FAFC`, window options | DROPPED (macOS frozen) |
| 4.4 keep `immersiveSticky` as a product decision | CHANGED (edge to edge with visible transparent bars, per the approved mockup) |
| 4.4 `SystemUiOverlayStyle.light` over a dark header | CHANGED (there is no dark header; icon brightness follows the theme) |
| 4.4 bottom padding rule `padding.bottom + 80` | CHANGED (list padding = tab bar 62 dp + `viewPaddingOf.bottom` + 8 + 24, shell concern) |
| 4.5 sync hook | KEPT |
| Hard fonts: Noto Sans for UI | CHANGED (Inter, see core_theme_and_widgets.md) |

### R3. Logic touchpoints and LR items

Untouched (still valid): the order and content of the initialisation sequence (`WidgetsFlutterBinding.ensureInitialized`, orientation, `Hive.initFlutter`, `registerAppLicenses`, `DatabaseService.initialize`, `PaymentLinkService.reconcileAll`, `_requestPermissions`, `SyncService.initialize`, `GoogleDriveService.initialize`, `runApp(ProviderScope(...))`); `_requestPermissions()` SDK branches; `startPeriodicSync(interval: 5 minutes)`, `stopPeriodicSync`, `syncNow` guarded by `isSignedIn`, resume trigger; the frozen window options and the shell selection; `ProviderScope` at the root.

| Id | Dependency | Status |
|---|---|---|
| LR-23, LR-35 | `themeModeProvider` and the Hive settings key read at startup; no `schemaVersion` bump, not synced | approved |
| LR-01 | none directly; `switchRig` runs after start | approved |
| L3 L-15 | storage permission request timing | not scheduled; the explanation dialog is only text around the existing request |
| L3 L-16 | Drive initialisation off the critical path | not scheduled (order change) |
| Q-O6 | root tab back does nothing versus leaving the app | open |
| Q-O3 | lazy tabs: Ledger and Accounts stay built at launch; Portfolio, Agents and Settings lazy | open for Accounts |

Lazy tab note (the tabs live in `main_navigation.dart`, another group): the five screens are a `const` list inside an `IndexedStack` today (`main_navigation.dart:33-52`), so all five are built before the first frame is shown. Making Portfolio, Agents and Settings lazy shortens the first frame after startup; this file only has to keep not building the shell before the startup gate finishes.

### R4. Acceptance criteria delta

1. With System chosen the app follows the device light or dark setting at launch and when the device setting changes; with Light or Dark chosen it ignores it; the choice persists across a cold start and the first frame has no colour flash.
2. Edge to edge: content draws under the transparent status bar and gesture bar; status icons are dark in light mode and light in dark mode; with 3-button navigation the bar is legible and the tab bar sits above it; every sticky control clears the bottom inset.
3. At 360 dp and 412 dp, portrait only, the app never rotates.
4. OS text scale 3.0 is clamped to 2.0 and screens do not overflow at 130 and 200 percent.
5. Cold start with a large database shows the splash within 300 ms (flat canvas in the current theme) and then the shell; with a small database no splash flicker. Cold start target under 2 s, goal 1.5 s.
6. Airplane mode: the app reaches the shell no later than before the change.
7. Forcing `DatabaseService.initialize` to throw shows StartupErrorScreen; Try again re-runs the same steps; no data changes.
8. The same initialisation steps run in the same order (log check).
9. Sync still triggers at launch (when signed in), every 5 minutes and on resume, exactly once per resume.
10. On Android 11 and 12 the storage explanation appears before the system screen and "Not now" continues without error.
11. Predictive back animates on Android 13 and above; no `WillPopScope` remains.
12. No `Colors.*` literal remains in `main.dart`.

### R5. Parity delta

Changes on purpose: line 61 (Android: portrait only, edge to edge instead of immersive mode); line 62 (primary colour of buttons, selected chips equals the accent: system blue by default, light and dark); line 63 (the unstyled license page bar is legible in both themes). Dropped: line 60 (macOS window). Must stay identical: lines 58 and 59 (offline cold start reaches the ledger with data intact; sync at launch, every 5 minutes, on resume). New line: Appearance System, Light, Dark applies at launch.

### R6. Performance and Android notes

- `RigTheme.light` and `RigTheme.dark` are `static final` (built once); `RigColors` is a const-constructible `ThemeExtension` with `lerp`. The `MaterialApp` rebuilds only when `themeMode` changes (watch the provider, nothing else).
- `builder` allocates only when the text scale actually clamps; use `MediaQuery.viewPaddingOf` and `textScalerOf` (not `MediaQuery.of`) to avoid rebuilds on keyboard changes.
- The shell is constructed after the startup gate; with lazy tabs only the first tab (and Accounts if Q-O3 keeps it) builds at start. Measure Hive open, `reconcileAll` and Drive init durations in debug.
- Keep one `WidgetsBindingObserver`. No BackdropFilter at the root; the glass blur toggle stays off by default until profiled on the reference device (still not named, Q-O4).
- Budgets: p90 build and raster under 8 ms, p99 under 16 ms, janky under 2 percent, tab switch under 100 ms, cold start under 2 s.
