> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# agents_screen (lib/features/agents/agents_screen.dart, 626 lines)

Tab 3 of both shells (mobile bottom nav, macOS sidebar). Contains the agent list, the add/edit dialogs (with default commission rates), the delete dialog (with reassign option) and the private widgets `_CommissionRateFields` and `_AgentCard`. All of these share this one doc.

## 1. Purpose and primary user task

Keep the list of agents (people who bring drilling jobs), see how many bills and how much commission each has, and edit their default commission rates (Rs per foot for depth, PVC, MS pipe). Frequent tasks: add an agent while entering a bill (rare here), check one agent's commission, correct a name or phone, delete an agent that was created by mistake.

## 2. Current structure

- `AgentsScreen` (ConsumerWidget, line 11): `Scaffold(backgroundColor: AppColors.background)` > `Column` > [`AdaptiveHeader('Agent Management', actions: [IconButton(Icons.add)])`, `Expanded(empty Center | ListView.builder(padding 16))`]; extra `FloatingActionButton` when the list is not empty (lines 97-103). So "add" exists three ways: header +, FAB, empty-state button.
- Providers read: `agentsProvider` (list), `agentBillCountsProvider` (Map id to count), `agentCommissionTotalsProvider` (Map id to double). Written: `agentsProvider.notifier.addAgent(name, phone, notes, depthCommissionRate, pvcCommissionRate, msPipeCommissionRate)`, `.updateAgent(Agent)`, `.deleteAgent(id, reassignToAgentId)`, `.getAgentByName`, `ledgerEntriesProvider.notifier.refresh()` after update and delete.
- `_showAddAgentDialog` (107), `_showEditAgentDialog` (211), `_showDeleteAgentDialog` (304): functions that create 6 `TextEditingController`s and call `showDialog` with an `AlertDialog` in the builder. Controllers are never disposed.
- `_AgentCard` (483): `Container` with `BoxShadow` > `InkWell(onTap: onEdit)` > Row [48x48 gradient avatar with initial, Column(name 16/w600; Row(phone icon+text, receipt icon+bill count); optional Row(handshake icon + "Commission Rs total")), edit IconButton, delete IconButton].

## 3. Problems found

Hierarchy and density
1. Three "add" affordances for one action (lines 28-36, 70-74, 97-103). On mobile the FAB plus header plus bottom nav compete; on macOS a FAB is out of idiom.
2. Card shows the commission line only when a rate or total exists (584-587), so card height varies and the list jitters; the default rates (the thing the user edits) are never displayed on the card, only the total.
3. Edit and Delete are two always-visible icon buttons, and the whole card is also tappable for edit (516, 609-618). Delete sits 48 dp from Edit with no spacing: easy mis-tap for a destructive action.
4. Avatar uses `AppColors.cardGradient` (527) with white text 20 bold on a gradient from #315D9A to #0490B6; white on #0490B6 is 3.70:1 (passes only as large text, 3:1). The gradient is decorative.
5. Section text sizes 12 for phone, bill count and commission (565-600): small, and commission is the key number of this screen.

Contrast (real hex)
6. Commission text and handshake icon use `AppColors.accent` #0490B6 on white = 3.70:1 at 12 sp (595-599): fails AA. Empty-state hint uses `textHint` #94A3B8 = 2.56:1 (64, 50).
7. Delete dialog warning text `AppColors.warning` #F59E0B on a 10 percent amber tint = about 2.0:1 (333-346): unreadable. White label on `AppColors.error` button (428-431) is 3.76:1.

Tap targets and scale
8. Row with phone + bill count (556-583) has no `Expanded`/`Flexible`: at 200 percent text scale a 10-digit phone plus "12 bills" overflows (RenderFlex overflow). UNVERIFIED on device, certain from the layout.
9. Dialog content is a `Column` of 6 fields, `maxLines: 2` notes: at 200 percent the dialog scrolls (it has SingleChildScrollView) but the Add/Save button is below the fold with no sticky action row.

Forms
10. Name is validated only on press via a snackbar (166-169, 268-272). The snackbar is shown on the Scaffold underneath the dialog barrier, so it appears behind the scrim and is barely visible. Same for "An agent with this name already exists" (177-181). Needs inline field error.
11. Edit does not check duplicate names (268-287) while Add does (173-182): rename to an existing name is silently allowed. Validation parity needs the same check; this is a validator change, so it is in `temp/design_wip/logic_g3.md`, not in the redesign.
12. Commission rate fields use `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))` (453) but `_rateVal` silently turns bad text to 0 (481). No unit suffix on the field (label says Depth, PVC, MS pipe; the unit is only in the group caption at 463).
13. Phone field accepts any text (141, 245): keyboard is phone but no length rule. (Not a logic change to add `maxLength` UI hint; validation stays absent.)
14. No `textInputAction`: Enter does not move to the next field or submit.

Destructive safety
15. Delete dialog default radio is "Delete all entries" (356-366: `groupValue: reassignToAgentId` starts null, so the destructive option is pre-selected) and the red Delete button is enabled immediately. One tap on Delete removes the agent and all its bills (`deleteAgent` without reassign). The only feedback is a red snackbar "Agent and entries deleted" (424) with no undo.
16. The dialog says "ledger entries" count but not their total value, nor that payment links to receiver books are affected (v2.0.0 payment log). The user cannot judge the blast radius.
17. Reassign radio uses hacked values (`'reassign'`, 371) and picks `otherAgents.first` silently (374), the dropdown then appears. When the user taps the "Delete all entries" radio again, `value: null` (358) works, but the selected state of the second radio is derived by comparing to null: fragile.

Feedback
18. Snackbars: success uses `AppColors.success` #10B981 with white text = 2.54:1 (200, 293); error red 3.76:1.
19. No loading state: `addAgent`/`updateAgent` are not awaited (184, 287); dialog closes before the write is known to finish. Provider is synchronous Hive writes so harmless, but errors would be swallowed.

States
20. Empty state exists (43-77): icon 64, 18 sp title, hint "Tap + to add your first agent" even though a button is shown right under it; no error state (providers synchronous).
21. Dark-mode branch in the header icon color (31-33) is dead code (app is light only).
22. Currency: `NumberFormat('#,##0.00')` with literal rupee sign (595): western grouping, differs from Rs. used in Account Ledger and PDFs.

Performance
23. `build` watches three providers; any bill edit rebuilds the whole list (all cards non-const, new closures). List is small (tens), so acceptable, but `agentCommissionTotalsProvider` recomputes over all bills on each bill change (provider cost, not UI).
24. Six `TextEditingController` per dialog open, never disposed (108-113, 212-220): small leak each time; MEMORY.md says dialogs must own and dispose their controllers.

## 4. Redesign

Page = `RigScaffold(appBar: RigAppBar(title: 'Agents' ... ))`. Title text: keep the current copy "Agent Management" as the app bar title to preserve strings (copy change to "Agents" is optional; if changed, bottom nav label stays "Agents"). Only ONE add control: on compact an extended FAB? No: a single `FilledButton.tonalIcon` "Add Agent" in the app bar actions (icon `Icons.person_add_alt_1_rounded`, tooltip "Add agent") for all widths; the empty state keeps its own primary button. The FAB is removed.

Layout
- Compact (<600): `ListView.separated`, horizontal padding `RigSpace.s4` (16), top s2, bottom s6, gap `RigSpace.s2` (8). Each agent is an `AgentCard` (private widget kept in this file, built on `RigCard`, padding s4):
  - Row 1: `AgentAvatar` (40 dp circle, fill `primaryContainer`, initial in `titleMedium` color `primary`; no gradient), name (`titleMedium`, `onSurface`, maxLines 1 ellipsis), trailing overflow `PopupMenuButton` (`Icons.more_vert_rounded`, 48 x 48, items Edit, Delete; Delete label color `negative`). The whole card remains tappable for Edit (same callback `onEdit`). The two inline icon buttons are removed, so Delete is two taps away (menu then dialog).
  - Row 2 (`Wrap`, spacing s3, runSpacing s1; never a fixed Row): phone chip (icon `Icons.phone_rounded` 16, `bodySmall`, `onSurfaceVariant`), bills chip (`Icons.receipt_long_rounded`, "12 bills"), always shown even at 0.
  - Row 3 (always shown, reserves height): "Commission" label `labelMedium` `onSurfaceVariant` left, `AmountText(commissionTotal, style: amountSmall, tone: commission)` right-aligned (shows `Rs. 0.00` muted when 0). Below it a caption `bodySmall` `onSurfaceVariant`: "Default rates per ft: Depth 50, PVC 20, MS 30" only when any rate is above 0 (values formatted `RigFormat.plain`, same numbers as `_rateText`).
- Medium (600-900): same card, max content width 720 centered, horizontal padding s6.
- Expanded (>900, macOS): content max width 1100; list becomes a two-column grid (`SliverGrid` with `maxCrossAxisExtent: 520`, mainAxisSpacing s3). Hover: card fill `surfaceContainerHigh`, cursor click. Right-click on a card opens the same menu (Edit, Delete) via `GestureDetector(onSecondaryTapUp)` showing `showMenu`. Keyboard: Cmd+N already handled by shell for ledger; do not rebind. Tab focus ring 2 px `primary`.

Dialogs (use `RigDialogShell`, max width 440 compact, 480 expanded; actions row pinned, content scrolls)
- Add/Edit agent: `RigTextField` Name (label "Name *", `TextCapitalization.words`, `textInputAction.next`, autofocus on Add), Phone (`TextInputType.phone`, next), Notes (`maxLines: 2`, `TextCapitalization.sentences`, action newline). Section `RigSection` "Default commission (Rs per foot)" caption "Copied to new bills of this agent. Not added to bill totals." then three `AmountField`s with suffix text "Rs/ft": Depth, PVC, MS pipe (keep the existing formatter regex). On compact the three rate fields are stacked; at >= 600 they sit in one row of three.
- Validation: errors render inline under Name ("Name is required", "An agent with this name already exists") after the first Add/Save press, then `AutovalidateMode.onUserInteraction`. The checks and messages are the same strings as today; the snackbar is dropped for validation. Success: `RigSnack` success "Agent added" / "Agent updated".
- Delete agent: `ConfirmDialog`-style dialog built on `RigDialogShell`:
  - Title "Delete Agent", message `"Delete \"<name>\"?"`.
  - If bills exist: `ErrorBanner`-tone banner (`negativeContainer`, icon `Icons.warning_amber_rounded` `negative`, text "This agent has N ledger entries." in `onSurface`, so contrast is 5.5+).
  - Choice is a `RigSegmented`-like radio pair with NO default selected: "Reassign to another agent" (disabled with helper "No other agents" when none) and "Delete these entries too". The primary button "Delete" stays disabled until a choice is made (UI state only; provider call and arguments unchanged: reassign picks `reassignToAgentId`, delete-all passes null). When reassign is chosen a `RigDropdownField` "Select agent" appears, defaulting to the first other agent exactly as today (`otherAgents.first.id`).
  - Delete-all adds a second guard: text button turns `negative` and label "Delete agent and N entries".
  - Result snackbar: `RigSnack` info for reassign, `error` kind for delete (message strings unchanged).
- Empty state: `EmptyState(icon: Icons.people_alt_rounded 48, title: 'No agents yet', hint: 'Add your first agent to track bills and commission', action: FilledButton 'Add Agent')`.

State table
| State | Behavior |
|---|---|
| Default | list of `AgentCard`s |
| Loading | none needed (synchronous Hive providers); show nothing special |
| Empty | `EmptyState` as above |
| Error | dialog inline field errors; write failures show `RigSnack(error)` (provider calls currently cannot throw to UI; keep try/catch optional) |
| Disabled | Delete confirm until a choice is made; Add/Save while saving |

Motion: dialog uses the theme default (`slow` 300 ms entrance); card hover/press color change `fast` 150 ms; list items do not animate in.

Text scale 200 percent: card wraps (Row 2 is a `Wrap`), name allows 2 lines at scale >= 1.5 (`maxLines: textScale > 1.5 ? 2 : 1`), amounts use `AmountText` with `FittedBox(scaleDown)` only down to 70 percent, then wrap label below value. Dialog actions stack vertically below 360 dp available width.

Tokens: spacing s1 s2 s3 s4 s6; radius lg (card), md (inputs), full (avatar); type titleMedium, bodySmall, labelMedium, amountSmall; colors primary, primaryContainer, onSurface, onSurfaceVariant, commission, negative, negativeContainer, outlineVariant.

Components: `RigAppBar`, `RigScaffold`, `RigCard`, `AmountText`, `RigTextField`, `AmountField`, `RigSection`, `RigDropdownField`, `RigDialogShell`, `ConfirmDialog`, `EmptyState`, `RigSnack`, `RigListRow` (not used: card is custom), new `AgentAvatar` (see components_g3.md).

## 5. Logic touchpoints that must stay untouched

- `agentsProvider`, `agentBillCountsProvider`, `agentCommissionTotalsProvider` reads; `addAgent(name, phone:, notes:, depthCommissionRate:, pvcCommissionRate:, msPipeCommissionRate:)` argument names; `updateAgent(agent.copyWith(...))`; `deleteAgent(agent.id, reassignToAgentId:)`; `getAgentByName(trimmed)` duplicate check on Add only; `ledgerEntriesProvider.notifier.refresh()` after update and delete.
- Trimming, empty-to-null conversion for phone and notes (186-191, 277-282), `_rateVal` (double.tryParse else 0), `_rateText` (0 shows as empty), `FilteringTextInputFormatter` regex.
- Delete semantics: null reassign means delete entries; the reassign default is `otherAgents.first.id`.
- Header "Agent Management" string and snackbar texts ("Agent added", "Agent updated", "Agent deleted and entries reassigned", "Agent and entries deleted", "Name is required", "An agent with this name already exists").

## 6. Acceptance criteria

1. Exactly one "Add Agent" control is visible on the list screen when agents exist; the empty state shows its own button.
2. Adding an agent with a blank name shows an inline error under the Name field and creates nothing; the message text equals "Name is required".
3. Adding a name that matches an existing agent (case-insensitive per `getAgentByName`) shows an inline error and creates nothing.
4. Saving rates 50, 20, 30 on an agent and then creating a new bill for that agent prefills the bill commission rates with 50, 20, 30 (unchanged behavior).
5. The delete dialog opens with no option selected and the Delete button disabled when the agent has bills; with zero bills it opens enabled with no choice section.
6. Choosing "Reassign" and confirming moves all bills of the agent to the chosen agent and bill count of the target increases by the moved count; choosing delete-all removes them. Counts on the cards update without leaving the screen.
7. At text scale 200 percent no card or dialog shows an overflow stripe, and the dialog Save/Add button is reachable without scrolling the page behind it.
8. Every interactive element is at least 48 x 48 dp on mobile (menu button, card) and 40 dp tall on macOS with pointer.
9. Commission total shows `Rs. 0.00` (muted) for an agent with no commission and the line is present on every card.
10. Right-clicking a card on macOS opens Edit/Delete; Tab reaches the menu button and Enter opens it.
11. No `Colors.*` or hex literal remains in the file; no controller is created outside a State that disposes it.

## 7. Performance notes

- Convert `_showAddAgentDialog`/`_showEditAgentDialog` bodies to a `StatefulWidget` `_AgentFormDialog` that owns and disposes its six controllers (same pattern as `_VehicleFormDialog` in vehicle_management_screen.dart:351). This fixes the leak and removes ref.read-in-closure captured controllers.
- `AgentCard` receives plain values (agent, count, total) and callbacks; make it `const`-constructible with `Key(agent.id)`; list via `ListView.builder` with `itemExtent` not set (heights vary).
- Use `ref.watch(agentsProvider.select(...))` is not useful (list identity changes); instead keep three watches but isolate the list in a child `Consumer` so the header does not rebuild.
- No per-frame setState; the delete dialog's `StatefulBuilder` rebuilds only the dialog.

## Reconciliation 2026-10-13 (Apple look, Android only)

Dropped from the redesign: every macOS, desktop, expanded (over 900 dp), medium (600 to 900 dp), hover, right-click, Cmd shortcut and two-column grid item in section 4. The old text stays above; none of it is to be built. macOS code is frozen and never edited.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Mockup function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Agents list | `agentsTab` | `lib/features/agents/agents_screen.dart` (`AgentsScreen`, `_AgentCard`) | LargeTitleScaffold (title "Agents", trailing add button 48 dp), RigGroup of RigRow (leading avatar 44 dp, title, subtitle "phone | N bills", trailing Commission label and MoneyText, chevron), RowActions (swipe Edit and Delete, long press menu), footer text | one add control in the header; the FAB is removed. Tab 3 of 5, built lazily |
| Add Agent dialog | `agentDlg()` | same file (`_AgentFormDialog` becomes a full height sheet widget) | RigSheet (full height), RigGroup of RigFormRow (Name, Phone, Notes), RigGroup of RigFormRow with rupee prefix (Depth, PVC, MS pipe), RigButton filled "Add" pinned | the widget owns 6 TextEditingControllers and disposes them |
| Edit Agent dialog | `agentDlg('a1')` | same | same, title "Edit Agent", pinned button "Save" | prefilled; rate shows empty when 0 (unchanged) |
| Delete Agent dialog | `agentDel('a1')` with zero bills | same (`_showDeleteAgentDialog`) | RigAlertDialog "Delete Agent", destructive RigButton text | zero bills: plain confirm, no choice section |
| Agent delete with entries | `agentDel` with bills | same | RigSheet (not full height) with ErrorBanner (warning icon), RigGroup of two RigRow choices with check, RigFormRow "Reassign to" picker, RigButton destructive "Delete Agent" pinned | see conflict G3-B15 below: no default selection |
| Agents empty | `emptyUI` inside `agentsTab` | same | EmptyState (icon people_outline, "No agents yet", "Tap + to add your first agent.", RigButton "Add Agent") | the Dev states Loading and Error exist in the mockup for this tab but have no code path (see R2 states) |

### R2. What changes in the redesign (supersedes section 4)

Layout, top to bottom (360 dp and 412 dp, portrait):
1. LargeTitleScaffold: status bar edge to edge, 56 dp bar row, large title 34 "Agents" collapsing to a 17 inline title (solid 94 percent bar with a hairline, no blur by default). Trailing add icon button, 48 dp touch target, tooltip "Add agent". Old title text "Agent Management" is replaced by the tab label "Agents" (tab labels are fixed by decision; copy change approved with the redesign).
2. List area: one RigGroup (radius 20, screen margin 20, `surfaceContainerLow` card colour `--s1`, no border in dark, soft shadow in light only), rows separated by a 0.5 dp hairline inset 16. Each RigRow min height 48 dp, padding 11 x 16:
   - Leading avatar 44 dp circle, fill `accentTint`, initial in `accentText`, 17 sp w600 (no gradient).
   - Title agent name 17 sp w600 (single line, ellipsis; at text scale 130 percent and above up to 2 lines), subtitle 13 sp `labelSecondary`: phone then " | " then "N bills" (always shown; at 0 shows "0 bills"). The subtitle is a Wrap-safe Text (no fixed Row), so a 10 digit phone never overflows.
   - Trailing block: caption "Commission" 12 sp `labelSecondary` over MoneyText 15 sp w600 in `commissionText`, full value (never compact in a list row; scale to 75 percent, then shrink to the 11 sp guard, then move the value to its own line). Zero commission shows the rupee sign with 0 in `labelSecondary` (line always present so card height does not jitter, same as old R-criterion 9).
   - Chevron 20 dp `labelTertiary` (decoration only).
3. Footer note under the group: "Commission is shown per agent and is never added to bill totals." 13 sp `labelSecondary`, inset 36.
4. List bottom padding: floating RigTabBar 62 dp + inset + 8 + 24, read from `MediaQuery.viewPaddingOf(context).bottom`.
5. Row interaction: tap opens Edit (unchanged callback `onEdit`). Swipe left reveals two 76 dp actions: Edit (`accentButton` fill) and Delete (`moneyOutButton` fill), white 13 sp w600 labels. Long press opens the RowActions menu sheet (Edit, Delete) as the non-gesture path for Delete. Pressed feedback is ink (`pressOverlay`), no scale.
6. Add and Edit are a full height RigSheet (top radius 28, grabber, keyboard insets handled): title row "Add Agent" or "Edit Agent"; RigGroup 1: Name (hint "Required"), Phone (hint "Optional", phone keyboard), Notes (hint "Optional", 2 lines); section label "DEFAULT COMMISSION PER FOOT" 13 sp uppercase `labelSecondary`; RigGroup 2: Depth, PVC, MS pipe, each RigFormRow with a rupee prefix and a decimal keyboard (existing regex formatter kept), group caption "Copied to new bills of this agent. Not added to bill totals."; pinned RigButton (filled 50 dp pill) "Add" or "Save" above the bottom inset (inset + 12). Inline error under Name replaces the hidden snackbar ("Name is required", "An agent with this name already exists", same strings).
7. Delete with zero bills: RigAlertDialog (radius 14, width 270 dp, stacked 48 dp buttons) titled "Delete Agent", message `Are you sure you want to delete "<name>"?`, buttons Cancel and "Delete" (destructive `moneyOutText`).
8. Delete with entries: RigSheet titled `Delete "<name>"`: ErrorBanner row (warning icon `outstanding`, text "This agent has N ledger entries. What would you like to do with these entries?"), RigGroup of two choice rows "Delete all entries" and "Reassign to another agent" with a check (accent) on the selected one; when Reassign is selected a RigFormRow "Reassign to" appears, defaulting to the first other agent (unchanged). Pinned RigButton destructive (`moneyOutButton`) "Delete Agent".
9. Snackbar: RigSnack floating capsule: "Agent added", "Agent updated", "Agent deleted and entries reassigned", "Agent and entries deleted" (strings unchanged).

Colour roles: `accentTint`, `accentText`, `commissionText`, `labelSecondary`, `moneyOutButton`, `moneyOutText`, `outstanding`, `surfaceContainerLow`. Spacing 20 margin, 12 gap, radii 20 group, 28 sheet, 14 alert, full pills and avatars. Money: rupee sign, en-IN grouping, Inter tabular figures. Old `NumberFormat('#,##0.00')` is replaced by `RigFormat.money`.

States:

| State | Behaviour |
|---|---|
| Default | RigGroup list as above |
| Loading | none. Hive providers are synchronous (C-3 in DESIGN_DIRECTION_APPLE.md 8.4). The mockup Dev state "Loading" shows a 3 row Skeleton; it is used only for the first frame after a rig switch or restore, if at all; no new provider state |
| Empty | EmptyState: icon 44 dp `labelTertiary`, "No agents yet" 22 sp, "Tap + to add your first agent." 15 sp, RigButton "Add Agent" |
| Error | the mockup draws ErrorBanner "Could not load agents"; the code has no failure path, so this is NOT built (C-3, LR-34 proposed). Form errors are inline field errors |
| Disabled | pinned Add or Save pill disabled while Name is empty after the first press is NOT used (Name error is inline); the pill disables only while the write is pending. Delete pill disabled until a choice is made (G3-B15) |

Motion: sheet rise and alert fade 200 to 350 ms ease-out; swipe snaps without spring; ink press feedback; all zero under reduced motion (`MediaQuery.disableAnimationsOf`).

Old section 4 items:

| Old item | Verdict |
|---|---|
| Single add control (header button, FAB removed) | KEPT (header trailing icon in LargeTitleScaffold) |
| Page = RigScaffold + RigAppBar, title "Agent Management" | CHANGED (LargeTitleScaffold, title "Agents") |
| AgentCard on RigCard with overflow PopupMenuButton | CHANGED (RigRow in RigGroup, swipe + long press via RowActions; no overflow menu) |
| Row 2 Wrap with phone and bills chips | CHANGED (one subtitle line "phone | N bills") |
| Row 3 always-present Commission line | KEPT |
| Caption "Default rates per ft: Depth 50, PVC 20, MS 30" on each card | DROPPED (not in the mockup; the rates are visible in the Edit sheet; reinstate only if the owner asks) |
| Medium and Expanded layouts, SliverGrid, hover, right-click, Cmd keys, Tab focus ring | DROPPED (Android only) |
| Add and Edit as RigDialogShell dialogs, rate fields in a row at 600 dp and over | CHANGED (full height RigSheet, rates stacked in RigGroup) |
| Inline validation errors, same strings | KEPT |
| Delete dialog with no default choice and disabled Delete | KEPT (and the mockup default is rejected, see R3) |
| Delete-all second guard (label "Delete agent and N entries") | DROPPED (the pinned pill text is "Delete Agent"; the banner already states N entries) |
| Result snackbars (info for reassign, error kind for delete) | CHANGED (RigSnack, one capsule style, strings unchanged) |
| Empty state | KEPT (copy: hint is the mockup text "Tap + to add your first agent.") |
| Text scale rules (name 2 lines at 1.5 and over) | KEPT (applies at 130 and 200 percent) |
| Tokens s1 to s6, lg, md, amountSmall | CHANGED (20/12 spacing, 20/28/14 radii, RigColors roles above) |

### R3. Logic touchpoints and LR items

Untouched (still valid from section 5): `agentsProvider`, `agentBillCountsProvider`, `agentCommissionTotalsProvider`; `addAgent(name, phone:, notes:, depthCommissionRate:, pvcCommissionRate:, msPipeCommissionRate:)`; `updateAgent(agent.copyWith(...))`; `deleteAgent(id, reassignToAgentId:)`; `getAgentByName` duplicate check on Add; `ledgerEntriesProvider.notifier.refresh()` after update and delete; trimming and empty-to-null; `_rateVal` and `_rateText`; null reassign means delete the entries; reassign default `otherAgents.first.id`; snackbar and validation strings.

| Id | Dependency | Status |
|---|---|---|
| LR-01 | `switchRig` also refreshes `agentsProvider` (agents are per rig); the Agents tab built lazily after a rig switch reads fresh data | approved |
| LR-32 | double tap Save in the Add or Edit sheet and in the delete pill must act once (`_saving` flag, UI guard) | approved (Phase 1 lists agent as the same pattern) |
| LR-34 | mockup Agents loading and error states | proposed, default: not built |
| Q-O7 | swipe actions need `flutter_slidable` or `Dismissible` (one action only) | open; fallback is the long press RowActions menu plus tap to Edit |
| G3-B15 | delete choice has no default | UI only, bug fix scheduled by severity (BUGS_FOUND.md); the mockup disagrees (see conflicts_r4.md) |
| L2-r4-2 | discard prompt on small sheets (agent, rig) like LR-25 | proposed, new (see temp/design_wip/logic2_r4.md) |
| L3 L-07 | duplicate name on Edit (rename to an existing name saves) | not scheduled; unchanged behaviour, parity line 7 stays |

Lazy tab check (answer 12): today `main_navigation.dart:33` builds all five screens in a `const` list inside an `IndexedStack`, so Agents is built at launch. After the change it is built on first visit and kept. `AgentsScreen` is a `ConsumerWidget` with no local state, so what must survive is (a) the scroll position of the list (kept by the retained `ScrollPosition`; LargeTitleScaffold must keep its collapse state in the same retained State, not in a route-level object), (b) an open sheet or alert (these are routes on the root navigator, unaffected by tab changes), (c) the Delete flow state `reassignToAgentId` lives inside the sheet State and dies with it. Nothing else is stateful here.

### R4. Acceptance criteria delta

1. At 360 dp and 412 dp, light and dark, the list shows a RigGroup with 44 dp avatars; every row is at least 48 dp tall and the whole row is the tap target (Edit).
2. At text scale 130 and 200 percent no row overflows: the subtitle wraps, the trailing Commission value moves to its own line only after shrinking to 75 percent and then to the 11 sp guard; no compact L or Cr text ever appears in the list.
3. Exactly one add control exists when agents exist (header icon); the empty state has its own "Add Agent" button; no FAB.
4. Swipe left on a row shows Edit and Delete; long press opens a sheet with the same two actions; Delete in either path opens the existing delete flow.
5. The delete sheet opens with NO option selected and the "Delete Agent" pill disabled when the agent has bills; with zero bills the alert opens with Cancel and Delete only.
6. Choosing Reassign defaults the target to the first other agent; confirming moves the bills and the target count increases by the moved count; Delete all removes them. Counts update without leaving the screen.
7. Blank Name shows an inline error "Name is required" under the field and creates nothing; a duplicate name shows "An agent with this name already exists".
8. With the keyboard open the focused field and the pinned pill are both visible above the keyboard; Android back first closes the keyboard, then the sheet; the Add and Edit sheet closes without a discard prompt (LR-25 does not cover it, see L2-r4-2; if approved, a dirty sheet asks to discard through UnsavedChangesGuard).
9. Switching away to another tab and back keeps the scroll position and the large title collapse state; a first visit builds the screen in under 100 ms (tab switch budget).
10. Dark mode: row text, `commissionText` and `moneyOutText` meet 4.5:1 on `surfaceContainerLow` (TOKENS.md section 5).

### R5. Parity delta

Changes on purpose: parity 1 (empty state text now "Tap + to add your first agent."); parity 2 and 3 (the card is a row; default rates are no longer printed on it, they are in the Edit sheet); parity 10 to 12 (the delete UI is an alert or a sheet; message strings are identical); parity 9 (commission shown with the rupee sign and en-IN grouping instead of the old western `#,##0.00`).
Must stay identical: parity 4 and 5 messages, parity 6 (rate field empty when 0), parity 7 (rename to a duplicate still saves), parity 8 (new bill prefilled with the agent rates), parity 11 and 12 results and counts. New line: after a first visit the tab keeps its scroll position when revisited (lazy tab line).

### R6. Performance and Android notes

- Insets: edge to edge; bottom padding of the list and the pinned pill read `MediaQuery.viewPaddingOf(context).bottom`; sheets add `MediaQuery.viewInsetsOf(context).bottom` and use `isScrollControlled: true`; the floating tab bar hides while the keyboard is open.
- Back: system back closes the keyboard, then the sheet; PopScope with a dirty check only if L2-r4-2 is approved; root tab back follows the shell (Q-O6).
- List: `ListView.builder` inside the RigGroup is not possible with one clipped group, so build one RigGroup per page with `SliverList` rows (tens of agents) and clip once; cache the three provider reads in one child Consumer so the title bar does not rebuild. No BackdropFilter inside the list; blur toggle stays off by default.
- Controllers: the six TextEditingControllers belong to the sheet State and are disposed in `dispose` (never after `await showDialog`, per MEMORY.md); the delete sheet owns nothing disposable.
- Budgets: p90 build and raster under 8 ms, p99 under 16 ms, janky frames under 2 percent, tab switch under 100 ms.
