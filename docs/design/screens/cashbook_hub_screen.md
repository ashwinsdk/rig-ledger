> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_hub_screen.dart (CashbookRootScreen, _HubPanel, _HubItem, openCashbookNewEntry)

Group g2. Source: lib/features/cashbook/cashbook_hub_screen.dart (178 lines). This doc also covers the hub panel (`_HubPanel`, same file). Shared Account Ledger rules (header, money, dates, period navigation) are specified once in cashbook_home_screen.md and cashbook_common.md.

## 1. Purpose and primary user task

Root of the fifth tab (Accounts). On mobile it shows the ledger home with a drawer that lists the 12 destinations of the Account Ledger. On wide desktop (width >= 900, macOS) it shows two panes: destination list at left (260 wide) and the ledger home at right. Primary task: jump from the ledger to a secondary tool (Summary, Account Summary, Transaction-All, Accounts, Report-All, Transfer, Notebook, Calendar, Import, Settings, Help, Deleted Transactions). Parity: PARITY-077, PARITY-083.

## 2. Current structure

- `CashbookRootScreen` (ConsumerStatefulWidget, hub_screen.dart:60) with `_scaffoldKey` (line 68).
- Wide branch (lines 80-98): `Scaffold(backgroundColor: AppColors.background)` > `Row[SizedBox(260, _HubPanel), VerticalDivider(1), Expanded(CashbookHomeScreen())]`. The Scaffold exists only to give InkWells a Material ancestor (comment lines 84-85).
- Narrow branch (101-112): `Scaffold(drawer: Drawer(_HubPanel), body: CashbookHomeScreen(onMenu))`.
- `_HubPanel` (116-169): ConsumerWidget; `ref.watch(currentCashBookProvider)` only to print the book name; gradient header Container (`AppColors.appBarGradient`, 32 px white icon, "Account Ledger" 18 w600, book name at white 80 percent), then `ListView` of 12 `ListTile`s (icon `AppColors.primary`).
- `_hubItems` (33-55): top-level list of `_HubItem` (icon, label, builder or action). `Report-All Accounts` is an action (`showCashReportAllDialog`), the others push `MaterialPageRoute` (`_open`, lines 70-76).
- `openCashbookNewEntry` (172-178): reads `currentCashBookProvider`, pushes `CashbookEntryFormScreen(bookId, initialCashIn: true)`; called by Cmd+N in desktop_shell.dart:273.
- State sources: `currentCashBookProvider` (read/watch). No writes.

## 3. Problems found

1. Drawer header uses a white-text-on-gradient block (hub:129-150). The white 80 percent book name over the light gradient stop (#618DCE) is about 2.7:1, fails AA (design system section 3.1). Fixed 32 px icon and 18 sp title are off the type scale.
2. Icons are mixed styles: filled (`Icons.bar_chart`, `Icons.list_alt`, `Icons.swap_horiz`, `Icons.help_outline`) and `_outlined` (hub:34-54). System rule: rounded variants only.
3. `ListTile` rows have no selected or hover state, so on desktop the left pane never shows which destination is open (hub:155-160). On wide desktop each destination is pushed on the root navigator (`Navigator.of(context).push`, hub:74) so it covers the whole window including the shell sidebar. UNVERIFIED: depends on whether desktop_shell.dart wraps tabs in its own Navigator (grep found none, so the push is on the app root navigator).
4. No grouping: 12 flat items with unrelated jobs (reports, tools, settings, help, trash). Destructive-adjacent "Deleted Transactions" sits last with the same weight as Help.
5. Wide breakpoint check uses `MediaQuery.of(context).size.width` (hub:81) which rebuilds the whole root on any MediaQuery change (keyboard). Use `MediaQuery.sizeOf`.
6. Gradient and `Colors.white` literals (hub:137-148), `AppColors.surface` and `AppColors.background` direct reads (hub:87,124).
7. The wide-pane `Scaffold` has no AppBar so the left pane has no title row aligned with the right pane header (right pane header is 48-56 dp, left pane starts with a 100 dp tall gradient block): the two header bands do not line up (hub:129-150 vs cashbook_header.dart).
8. 12 items at 200 percent text scale: the drawer list scrolls (ListView) so no overflow, but the fixed header `padding fromLTRB(20,24,20,16)` plus 32 px icon is not scalable.

## 4. Redesign

Layout by width:

- Compact (<600): the ledger home is the page. Drawer = `Drawer` width 304 (Material default 304, max 85 percent of screen) containing `HubPanel`. Drawer opened by the menu icon in `RigAppBar` (leading, 48x48, `Icons.menu_rounded`, tooltip "Menu").
- Medium (600-900): same as compact, drawer width 320. Home content max width 640 centered (RigScaffold maxContentWidth 640 for lists on medium).
- Expanded (>900, desktop): two panes. Left `HubPanel` width 240 (collapses to 72 icon-only rail below window width 1000, labels in tooltips), divider `RigDivider` vertical 1 px `outlineVariant`, right pane the ledger home with content max width 1100.

`HubPanel` anatomy (all tokens):

- Top block (no gradient): `surface`, padding `RigSpace.s4` (16) horizontal, `s4` top (SafeArea inset on mobile), `s3` bottom. Row: 40x40 `primaryContainer` rounded square (radius `md`) with `Icons.account_balance_wallet_rounded` 24 in `primary`; then Column: "Account Ledger" `titleMedium` `onSurface`, current book name `bodySmall` `onSurfaceVariant` (maxLines 1, ellipsis). Bottom border 1 px `outlineVariant`.
- Items: `RigListRow` dense (min height 48 on touch, 40 with pointer), leading icon 20 `onSurfaceVariant`, title `bodyMedium`. Selected item (desktop only, the destination currently open in the right pane, or "Ledger" when none): background `primaryContainer`, text `primary`, radius `md`, horizontal margin `s2`.
- Groups with `RigSection` captions (`labelMedium`, `onSurfaceVariant`, padding `s4`,`s3`,`s4`,`s1`). Same order inside groups as today, so no destination is lost:
  1. "Overview": Summary, Account Summary, Transaction-All Accounts, Calendar
  2. "Manage": Accounts, Transfer, Notebook
  3. "Reports and data": Report-All Accounts, Import from cashbook app, Deleted Transactions
  4. "App": Settings, Help
- Icons (Material rounded): Summary `bar_chart_rounded`, Account Summary `pie_chart_rounded`, Transaction-All `list_alt_rounded`, Accounts `account_balance_wallet_rounded`, Report-All `picture_as_pdf_rounded`, Transfer `swap_horiz_rounded`, Notebook `sticky_note_2_rounded`, Calendar `calendar_month_rounded`, Import `file_download_rounded`, Settings `settings_rounded`, Help `help_rounded`, Deleted Transactions `delete_sweep_rounded`. Where a rounded glyph does not compile use the nearest rounded glyph.
- Deleted Transactions label keeps the text, icon tinted `onSurfaceVariant` (not red: it is a viewer, not a delete action).

Desktop specifics: hover `surfaceContainerHigh`, pointer cursor, focus ring 2 px `primary`; Up/Down arrows move focus in the list, Enter opens; Cmd+N still calls `openCashbookNewEntry` (unchanged). Optional (needs approval, see logic_g2.md L-01): keep destinations in the right pane using an inner Navigator so the left pane stays visible; default stays the current root push.

Motion: drawer uses the framework transition (slow, 300 ms); selected highlight changes in `fast` (150 ms); zero duration when `MediaQuery.disableAnimationsOf`.

State table:

| State | Rule |
|---|---|
| Default | list as above |
| Loading | not applicable (all data is local); book name shows "" until `currentCashBookProvider` resolves, then ellipsis text, no layout shift because the line height is reserved |
| Empty | not applicable (static list). If `currentCashBookProvider` is null the second line shows "No book selected" in `textMuted` |
| Error | not applicable |
| Disabled | no item is disabled |
| Selected (desktop) | `primaryContainer` fill |

Components: `RigScaffold`, `RigAppBar` (home), `RigListRow`, `RigSection`, `RigDivider`, `RigSidebar`-style selected state (reuse the `RigSidebar` item look; if `RigSidebar` is not reusable, add `HubPanel` to temp/design_wip/components_g2.md).

## 5. Logic touchpoints that must stay untouched

- `_hubItems` order of destinations, their builders and the `action` for Report-All (`showCashReportAllDialog(context, ref)`).
- `_open` (push versus action), the drawer close before navigation (`Navigator.pop(context)` then `_open`, hub:105-106).
- `PlatformHelper.isDesktop` and `PlatformHelper.wideBreakpoint` (900) decide the two-pane layout.
- `openCashbookNewEntry(context, ref)` signature and behavior (used by desktop_shell.dart:273, Cmd+N).
- `currentCashBookProvider` read for the header name.
- `CashbookHomeScreen(onMenu: ...)` callback contract (null hides the menu button).
- `main_navigation.dart:37` and `desktop_shell.dart:784` instantiate `CashbookRootScreen()` with no arguments.

## 6. Acceptance criteria

1. All 12 destinations are reachable from the drawer on compact and from the left pane on expanded; each opens the same screen as before; Report-All opens its dialog, not a page.
2. Order inside groups is the old order; no destination was dropped or renamed (labels unchanged).
3. Every row is at least 48 dp tall on touch and 40 dp with pointer; the whole row is the tap target.
4. No gradient, no `Colors.x`, no hex in the panel; header text contrast >= 4.5:1.
5. At 200 percent text scale the panel scrolls and no text is clipped; the header block grows with text.
6. On desktop the open destination is not highlighted unless it is shown in the right pane; the home entry ("Ledger" row is not added) is not duplicated.
7. Cmd+N opens the Income form for the current book; with no book nothing happens.
8. Opening and closing the drawer does not rebuild `CashbookHomeScreen` more than once.
9. Icons are all `_rounded`.

## 7. Performance notes

- `_HubPanel` watches the whole `currentCashBookProvider`; use `ref.watch(currentCashBookProvider.select((b) => b?.name))` so it rebuilds only on rename.
- Replace `MediaQuery.of(context).size.width` with `MediaQuery.sizeOf(context).width` (rebuild only on size change, not on keyboard insets).
- Make `_hubItems` entries and the group captions `const` where possible; the panel list is 12 rows, no need for a builder.
- `CashbookHomeScreen` is created once per branch; keep the same Key on both branches only if the state (search text) should survive a window resize across 900 (today it is lost because the branches build different trees; note for QA, not a requirement).


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Drawer hub | `cbDrawer` + `HUB`, `HUBC` | lib/features/cashbook/cashbook_hub_screen.dart (`_HubPanel`, `_hubItems`) | Flutter `Drawer` kept as the container (see conflicts_r3.md C-01); content: RigCard header, RigGroup of 12 RigRow with `chev: true` and a coloured 29 dp icon tile; LargeTitleScaffold menu button in `CashbookHomeScreen` | The mockup shows a full-height RigSheet titled "Account Ledger" with a close button; the code has a left drawer. The content and order are the same in both. |
| Home (All) | `cbHome` (menu button `lead`) | cashbook_hub_screen.dart (`CashbookRootScreen`) | LargeTitleScaffold (root, title "Accounts") owns the menu button that opens the drawer | Only the entry point is described here; the home layout is in cashbook_home_screen.md. |

### R2. What changes in the redesign (supersedes section 4)

The macOS two-pane layout is DROPPED. The hub is the Android drawer only.

Layout of the drawer panel (top to bottom), light and dark by the same tokens:
- Container: `Drawer` width 304 dp (maximum 85 percent of the screen width), background `sheet` token (`--sheet`), trailing top and bottom corner radius 28, no gradient, no border; the status bar area is covered by the drawer background (edge to edge, top padding = `viewPaddingOf.top`).
- Header card: RigCard (radius 20, margin 20 left and right, gap 12 below), one row: 40 dp `avatar` circle in `accentTint` with `Icons.account_balance_wallet_rounded` 24 in `accent`; column with "Account Ledger" at 17 sp weight 600 (`label`) and the current book name at 13 sp `label2` (one line, ellipsis).
- Destinations: ONE RigGroup (inset grouped list, radius 20, margin 20) of 12 RigRows in the existing order: Summary, Account Summary, Transaction-All Accounts, Accounts, Report-All Accounts, Transfer, Notebook, Calendar, Import from cashbook app, Settings, Help, Deleted Transactions. Each RigRow: min height 48 dp, leading 29 dp rounded icon tile (white 19 dp icon on the role colour), title 17 sp, trailing chevron in `label3`, hairline separators inset 16 dp, press feedback by ink.
- Icon tile colours (mockup `HUBC`, in order): `accent`, `commission`, `catPvc`, `moneyInButton`, `moneyOutButton`, `catDiesel`, `catHammer`, `accent`, `label2`, `label2`, `accent`, `moneyOutButton`. The colours are decoration only; the label carries the meaning.
- Bottom padding of the scroll area: `viewPaddingOf.bottom` + 24. The floating RigTabBar is not shown behind the drawer (the drawer sits above it).
- Tapping a row closes the drawer first (`Navigator.pop`) then runs the same action as today (push the screen, or `showCashReportAllDialog` for Report-All Accounts).


Old section 4 items:

- Old 4 layout by width (compact, medium, expanded): CHANGED to one layout (compact only, 360 dp floor); medium and expanded are DROPPED (macOS, desktop).
- Old HubPanel top block (no gradient, primaryContainer square, bottom border): CHANGED to the RigCard header above; the intent (no gradient, current book name) is KEPT.
- Old items as dense `RigListRow` with 40 dp pointer height and desktop selected state: CHANGED to RigRow 48 dp; selected state and hover are DROPPED.
- Old four caption groups (Overview, Manage, Reports and data, App) with a reordered list: DROPPED. The mockup shows one flat group in the original order, so no destination moves; the old reorder would have changed the order from PARITY-077.
- Old icon list (rounded glyphs): KEPT, now inside the coloured tile; names as in the mockup glyphs (outlined names in the mockup map to the `_rounded` Flutter icons).
- Old Deleted Transactions tint (not red): CHANGED. The mockup tints its tile `moneyOutButton`; it stays a viewer, so the label is not red.
- Old desktop specifics (hover, focus ring, arrow keys, Cmd+N, inner Navigator option L-01): DROPPED. `openCashbookNewEntry` stays in the file (frozen desktop shell still calls it) and is not edited.
- Old motion (drawer 300 ms, selected highlight 150 ms): CHANGED to the framework drawer transition and ink press only; reduced motion removes the transition duration.


States:

| State | Rule in the new look |
|---|---|
| Default | header card plus 12 rows |
| Loading | not applicable (static list); book name line reserves its height |
| Empty | not applicable; when `currentCashBookProvider` is null the second line reads "No book selected" in `label2` |
| Error | not applicable |
| Disabled | no row is disabled |


Motion: drawer slide uses the framework transition (200 to 350 ms ease-out); press feedback is the ink overlay (`pressOverlay`), no scale; zero duration under `MediaQuery.disableAnimationsOf`.


### R3. Logic touchpoints and LR items

Untouched: `_hubItems` order and builders, the `action` for Report-All, `_open` push-versus-action rule, the drawer close before navigation, `openCashbookNewEntry` signature, `currentCashBookProvider` read, `CashbookHomeScreen(onMenu:)` contract, the no-argument construction in `main_navigation.dart`.


- LR-24 (approved): not used on this screen, listed because the hub opens the settings that carry it.
- LR-25, LR-27 (approved): not on this screen; they live on destinations opened from it.
- No new logic item. The drawer-versus-sheet choice is a presentation question (conflicts_r3.md C-01), not a logic change.


### R4. Acceptance criteria delta

1. All 12 destinations are reachable from the drawer on a 360 dp and a 412 dp phone, light and dark, in the original order; Report-All Accounts opens its sheet or dialog, not a page.
2. The drawer shows no gradient and no `Colors.x`; header and row text meet 4.5:1 on the `sheet` surface in both themes.
3. Every row is at least 48 dp tall and the whole row is the tap target; at text scale 200 percent the drawer scrolls and nothing is clipped.
4. Android back with the drawer open closes the drawer (no navigation); with it closed on the Accounts tab nothing happens (shell rule).
5. With the keyboard open (search active on the home screen) opening the drawer is possible and the keyboard closes.
6. No two-pane layout exists at any width; `PlatformHelper.wideBreakpoint` is not read by this file in the redesign (the frozen desktop path is untouched).
7. Opening and closing the drawer does not rebuild `CashbookHomeScreen` more than once.


### R5. Parity delta

Change on purpose:

- PARITY-077 wording "or left pane (macOS wide)" in parity_g2.md line 20 is dropped: the 12 destinations are checked from the drawer only.
- Drawer header colours and icon styles change (visual only); labels are identical.


Must stay identical:

- PARITY-077 destination list and order (12 items; Transaction names and Cash Calculator stay dropped, D1 and D3).
- PARITY-083 fifth tab (label "Accounts", index 3).


### R6. Performance and Android notes

- Edge to edge: status bar transparent, bottom inset from `MediaQuery.viewPaddingOf(context).bottom` (never a hard-coded 24). Root tab content ends at 62 + inset + 8 + 24 dp (tab bar height 62, its float 8, list gap 24).
- Keyboard: `resizeToAvoidBottomInset: true`; the floating RigTabBar is hidden while the keyboard is open; the focused field is scrolled to the centre with `Scrollable.ensureVisible`.
- Back: root tab back is swallowed by the shell `PopScope(canPop: false)` (unchanged); pushed screens pop normally.
- List strategy: 12 static rows in a `ListView`; `const` rows; watch `currentCashBookProvider.select((b) => b?.name)` so the panel rebuilds only on a rename.
- Use `MediaQuery.sizeOf` instead of `MediaQuery.of(context).size` anywhere width is read; do not read the width at all for layout (one layout).
- No `BackdropFilter` in the drawer; solid `sheet` surface. Nothing to dispose here (no controllers). Budgets: p90 under 8 ms, p99 under 16 ms.

