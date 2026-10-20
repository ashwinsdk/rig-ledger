> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# vehicle_management_screen (lib/features/settings/vehicle_management_screen.dart, 531 lines)

Contains `VehicleManagementScreen` (list, switch, delete) and `_VehicleFormDialog` (add/edit with vehicle type picker). Both share this doc.

## 1. Purpose and primary user task

Manage rigs (vehicles): see all rigs, mark one active (switch), add a rig, rename it or change its type (Main Bore or Side Bore), and delete a rig. A rig scopes ledger entries and side-ledger data, so switching and deleting change what the whole app shows.

## 2. Current structure

- `VehicleManagementScreen` (ConsumerStatefulWidget, 12): `Scaffold` + `AppBar(title: 'Vehicle Management', flexibleSpace: gradient)`; body `ListView.builder` of `Card`s (shape radius 12, 2 dp primary border for active), FAB `Icons.add`. Empty state (179-205) with 64 dp car icon.
- Row: 48 dp tinted icon (blue main, green side), name 16 w600 + optional "Active" badge (10 sp bold white on primary), type text (13 sp, blue or green), `PopupMenuButton` (Edit, Delete).
- Tap on a non-active card calls `_switchVehicle` which switches, resets search and filter providers, refreshes six providers, shows a snackbar and pops the screen (141-162).
- Providers read/written: `vehiclesProvider` (+ `.refresh()`, `.deleteVehicle`, `.addVehicle`, `.updateVehicle`), `currentVehicleProvider` (+ `.setCurrentVehicle`), `searchQueryProvider`, `ledgerFilterProvider`, `ledgerEntriesProvider`, `dieselEntriesProvider`, `pvcEntriesProvider`, `bitEntriesProvider`, `hammerEntriesProvider`, `agentsProvider`, `cashEntriesProvider`.
- `_VehicleFormDialog` (351): owns `_nameController` (disposed, good), `_formKey`, `_selectedTypeIndex`; type options built by `_buildTypeOption` (480) as two `GestureDetector` tiles.

## 3. Problems found

Destructive safety
1. Delete Vehicle (48-139) is a plain confirm. The warning copy (87) says "all ledger entries, side-ledger data, and agent information for this vehicle" but gives no count of how many bills, diesel/PVC/bit/hammer entries will go, and the red text 12 sp on a red tint (`Colors.red` #F44336 over 10 percent tint) is about 3.6:1. The user cannot judge the loss. Nothing offers a backup first or an undo. The confirm is a 14 sp text button `Colors.red` (106).
2. Deleting the current rig silently switches to the first other rig (115-120) with no mention in the dialog ("You will be switched to <name>").
3. `Cannot delete the last vehicle` (52-60) is a snackbar with `Colors.orange` (#FF9800) and white default text = 2.16:1. Better: disable the Delete menu item with an explanation.
4. Editing the type of a rig that already has entries (dialog 441-463) is allowed with no warning although side bore rigs hide PVC everywhere (v2.0.0). Flip is a UI change here; consequence is logic (see logic_g3.md).

Interaction and feedback
5. Tapping a card switches rig AND closes the screen (160). Nothing in the card signals "tap to switch"; a user who taps while looking for the menu leaves the screen. The active card is non-tappable (223) but not styled as selected beyond the border and badge.
6. Switch and delete have no progress/feedback beyond a snackbar; `_switchVehicle` refreshes six providers and then pops: the snackbar "Switched to X" shows after the pop on the previous screen (good) but if `mounted` is false nothing shows. OK.
7. After add/edit dialog closes, `vehiclesProvider.refresh()` is called in `.then` (35, 44) even when the dialog is cancelled (needless).
8. `deleteVehicle` path refreshes `cashEntriesProvider` but not the cash books or notes; MEMORY.md says deleting a vehicle orphaned linked entries (fixed in T-CB18). No UI impact now.
9. Form: no duplicate-name check, no `textCapitalization`, no `textInputAction.done`, Enter does not submit; `_saveVehicle` is async but the button can be tapped twice before `Navigator.pop` (no `_saving` flag): double add creates two rigs (419-431, 380-406). Real bug (data duplication), risk small since writes are fast.
10. Type tiles are `GestureDetector`s (489): no semantics (`Semantics(selected: ..., button: true)`), no keyboard focus or Enter/Space activation on macOS, and the selected state is communicated by color and a 2 dp border only. Subtitle text is 9 sp (523) and grey 600 (#757575 4.61:1), below the 11 sp floor; titles 12 sp. At 200 percent the two side-by-side tiles each get about 130 dp: the subtitle 'Full ledger + side-ledger' wraps to 4 lines and overflows nothing but is cramped.
11. Colors: `Colors.blue` (#2196F3 3.12:1 as text on white) for Main Bore text (292), `Colors.green` (#4CAF50 2.78:1) for Side Bore text (292). Both fail AA for 13 sp text. Type is identified by color and icon only in the list; the text label is present, so it is not color-only, but the contrast is poor.
12. "Active" badge: 10 sp, `Container` radius 10 with fixed paddings (265-283): below 11 sp floor; at large text it grows but is not in a `Flexible` row: the name `Text` (256) is not `Expanded`, so a long vehicle name plus badge overflows the Row. Real overflow bug for names longer than about 18 characters on 360 dp wide screens. 
13. Popup menu icons (`Icons.edit`, `Icons.delete`) use mixed styles; the menu is the only way to edit/delete (no long-press, no hover or context menu on desktop).
14. The `Card` uses default elevation 2 plus theme shape overridden to radius 12 (216) while other lists use 16 and shadow containers.
15. FAB at bottom right overlays the last list item (list padding 16 only; no bottom inset for the FAB), hiding the menu button of the last row on small screens. 
16. Empty state: unreachable in practice (a default vehicle always exists, `_ensureDefaultVehicle`), grey 400 icon 64 dp (`Colors.grey.shade400` 2.5:1).

Performance
17. `ref.watch(vehiclesProvider)` and `currentVehicleProvider` rebuild the full list on any change; list is tiny. `initState` posts a refresh on every open (22-28).

## 4. Redesign

Page: `RigScaffold(appBar: RigAppBar(title: 'Vehicle Management', actions: [add]), maxContentWidth: 640)`. The primary add control is a `FilledButton.tonalIcon` "Add Vehicle" in the app bar actions on expanded widths and the same as an extended FAB on compact (single control; the list gets bottom padding `RigSpace.s12` + safe area so nothing is hidden).

List: `ListView.builder`, horizontal padding 16 / 24 / 32, gap s2. Each rig is a `RigCard` (padding s4) with:
- Leading 40 dp rounded square (`RigRadius.md`) containing the type icon: `Icons.precision_manufacturing_rounded` (Main Bore) on `primaryContainer` with `primary` glyph, `Icons.construction_rounded` (Side Bore) on `surfaceContainer` with `onSurfaceVariant` glyph. Type is also written in text (`bodySmall` "Main Bore" / "Side Bore"), never color only.
- Title `titleMedium` (name, `Expanded`, 2 lines max), `Active` shown as a `labelSmall` (11 sp) pill: fill `primaryContainer`, text `primary`, icon `Icons.check_circle_rounded` 14, placed on its own line under the name via `Wrap` so long names never overflow.
- Trailing: for a non-active rig a text button "Switch" (`labelLarge`, 48 dp tall) that performs the same `_switchVehicle`; whole-card tap still switches (unchanged behavior) but the explicit label makes it discoverable; for the active rig a non-interactive check. Overflow menu `Icons.more_vert_rounded` (Edit, Delete; Delete `negative`).
- Active card border: 2 px `primary`; non-active 1 px `outlineVariant`; selected state also adds the check icon so it is not color-only.
- Compact: single column. Medium: same, max width 640 centered. Expanded: max 640 centered, hover `surfaceContainerHigh`, right-click opens the same menu, keyboard: arrow keys move focus between cards, Enter switches, Delete key opens the Delete dialog (only when the Delete action is enabled).

Delete dialog (`RigDialogShell`, max 440):
- Title "Delete Vehicle?", message `"Delete \"<name>\"?"`.
- `ErrorBanner` (`negativeContainer`, `negative` icon, `onSurface` text 4.5+:1): "This permanently deletes the ledger entries, side-ledger data and agent information of this vehicle." Followed by a count row if the existing providers expose it without new logic: bills, diesel, PVC, bit, hammer counts read from the already-loaded `ledgerEntriesProvider` etc. filtered by vehicle id in the widget (display only); if not trivially available, omit the counts (do not add provider code).
- If it is the active rig: info line "You will be switched to <next rig name>" (the same `vehicles.firstWhere(...)` already computed).
- Actions: Cancel (left, focused) and "Delete" (`negative` filled). If the rig is the last one, the menu item is disabled with the tooltip "At least one vehicle is required" and the existing snackbar remains as a fallback.

Add/Edit dialog: `RigDialogShell` with `RigTextField` "Vehicle Name *" (hint "e.g., Main Rig, Side Rig 1", `TextCapitalization.words`, `textInputAction.done`, submit on Enter, autofocus on Add, validator unchanged, inline error), `RigSegmented` for Vehicle Type (two segments, each with icon, title `labelLarge`, subtitle `bodySmall` 12 sp, `Semantics(selected)`, focusable, Space/Enter select), a `_saving` flag disabling the primary button while the write is pending. When editing a rig that has entries and the type is changed, show an inline `info` helper "Changing the type changes which fields are shown. Existing entries are not modified." (copy only).

States
| State | Behavior |
|---|---|
| Default | list |
| Loading | none (synchronous) |
| Empty | `EmptyState(icon: Icons.directions_car_rounded, title: 'No vehicles yet', action: Add Vehicle)` |
| Error | dialog inline validation; write failure `RigSnack` error |
| Disabled | Delete for the last rig; Save while saving; Switch on the active rig |

Motion: dialogs 300 ms (`slow`), active border change 150 ms (`fast`).

Tokens: spacing s2 s4 s6 s12; radius lg (card), md (icon tile, inputs); type titleMedium, bodySmall, labelLarge, labelSmall; colors primary, primaryContainer, surfaceContainer, onSurface, onSurfaceVariant, outlineVariant, negative, negativeContainer, info.

Components: `RigScaffold`, `RigAppBar`, `RigCard`, `RigListRow` (not used, card is custom), `RigSegmented`, `RigTextField`, `RigDialogShell`, `ConfirmDialog`, `ErrorBanner`, `EmptyState`, `RigSnack`, new `StatusPill` (components_g3.md).

## 5. Logic touchpoints that must stay untouched

- `_deleteVehicle` order: guard `vehicles.length <= 1`, switch current rig to `vehicles.firstWhere((v) => v.id != vehicle.id)` via `currentVehicleProvider.notifier.setCurrentVehicle` BEFORE `vehiclesProvider.notifier.deleteVehicle(vehicle.id)`, then refresh `cashEntriesProvider`, `ledgerEntriesProvider`, `dieselEntriesProvider`, `pvcEntriesProvider`, `bitEntriesProvider`, `hammerEntriesProvider`, `agentsProvider`.
- `_switchVehicle`: `setCurrentVehicle`, reset `searchQueryProvider.state = ''`, `ledgerFilterProvider.state = const LedgerFilter()`, the six refreshes, snackbar text `Switched to <name>`, `Navigator.pop`.
- Vehicle construction in `_saveVehicle` (Uuid v4 id for new, preserved `createdAt`, new `updatedAt`, `vehicleTypeIndex` 0 main / 1 side), `addVehicle`/`updateVehicle`.
- Validator `Please enter a vehicle name` and trimming; type index meaning; `vehicle.vehicleTypeIndex == 0` is main bore.
- Texts: "Cannot delete the last vehicle", "Vehicle deleted", "Vehicle added", "Vehicle updated".

## 6. Acceptance criteria

1. Tapping a non-active rig card or its "Switch" button switches the rig, clears search and filters, shows `Switched to <name>` and returns to Settings (unchanged).
2. The active rig shows the check icon, the "Active" pill and a 2 px primary border; it has no Switch button.
3. A rig named with 40 characters shows on at most two lines and never overflows at text scale 200 percent.
4. Deleting the last remaining rig is impossible: the Delete menu item is disabled with a tooltip.
5. The delete dialog mentions what is deleted and, when deleting the active rig, names the rig that becomes active; confirming deletes and switches in that order.
6. Add Vehicle with an empty name shows the inline error "Please enter a vehicle name"; double-tapping Add creates only one rig.
7. The type tiles are reachable by Tab, selectable with Space/Enter, and announce their selected state (`Semantics.selected`).
8. FAB or add button never covers the last card's menu button (bottom padding 96 dp plus inset).
9. No `Colors.*` literal remains; all text has at least 4.5:1 contrast; no text below 11 sp.
10. Right-click on a card on macOS opens Edit and Delete.

## 7. Performance notes

- Remove the redundant `refresh()` in `.then` after dialogs (the notifier already updates state on add/update); keep only if the notifier does not call `loadVehicles` (verify in vehicle_provider.dart before removing; if unsure leave it).
- Make `VehicleCard` a stateless widget taking `Vehicle`, `isActive` and callbacks (const-capable); the list rebuild is then cheap.
- `_VehicleFormDialog` already disposes its controller; keep it. Add `_saving` bool in its State and guard `_saveVehicle`.
- Delay-free: no per-frame setState; `ListView.builder` is adequate (tens of rigs at most).

## Reconciliation 2026-10-13 (Apple look, Android only)

Wording: all UI copy says "Rig" (title "Rigs", "Add Rig", "Edit Rig", "Delete Rig", "Rig type", snackbars "Rig added", "Rig updated", "Rig deleted", "Switched to <name>", "Cannot delete the last rig"). The file `vehicle_management_screen.dart`, the classes `VehicleManagementScreen`, `_VehicleFormDialog`, the model `Vehicle` and `vehicleId` keep their names. Dropped from the redesign: macOS and desktop items (Expanded layout, hover, right-click, arrow-key focus, Delete key, 640 dp cap), medium widths. Old text stays above.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Mockup function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Vehicle Management | `SC.vehicles` | `lib/features/settings/vehicle_management_screen.dart` (`VehicleManagementScreen`) | LargeTitleScaffold ("Rigs", trailing add button), RigGroup of RigRows (leading 30 dp type tile, name, type subtitle, "Active" badge), RowActions (swipe Edit and Delete, long press sheet "Rig"), footer text | pushed from the Settings row |
| Add Vehicle dialog | `vehDlg` | same (`_VehicleFormDialog` becomes a sheet widget) | RigSheet, RigFormRow "Name", section label "RIG TYPE", RigGroup of two RigRows Main Bore and Side Bore with check, RigButton filled "Add" or "Update" pinned | edit mode title "Edit Rig" (same function with `ed`) |
| (drawn by the mockup, not in the J list) | `vehDel` | same (`_deleteVehicle`) | RigAlertDialog "Delete Rig", Cancel and Delete | text names what is deleted |
| (drawn, not in the J list) | `vehMenu` | same | RigSheet "Rig" with Edit and Delete RigRows | the non-gesture path for the swipe actions |

### R2. What changes in the redesign (supersedes section 4)

Layout:
1. LargeTitleScaffold "Rigs", trailing add icon (48 dp, tooltip "Add rig"). The FAB is removed; the list bottom padding is inset + 24 (no tab bar on a pushed screen).
2. One RigGroup (radius 20). Each rig is a RigRow: leading tile 30 dp radius 8, fill `accent` when active and `labelSecondary` when not, glyph white 19 dp (`precision_manufacturing` for Main Bore, `construction` for Side Bore); title name 17 sp (up to 2 lines, ellipsis); subtitle "Main Bore" or "Side Bore" 13 sp `labelSecondary` (type is always written, never colour only); trailing "Active" badge (12 sp w600, `accentTint` fill, `accentText`, radius 10, padding 2 x 8) on the active rig only. The row is `Expanded` so a long name wraps before the badge (fixes old problem 12).
3. Tap on a non-active row switches the rig (unchanged `_switchVehicle`: switch, clear search and filter, refresh providers, snack `Switched to <name>`, pop). The active row is not tappable. Swipe left shows Edit (`accentButton`) and Delete (`moneyOutButton`) 76 dp actions; long press opens the "Rig" sheet. Footer text: "Tap a rig to make it the active rig. Swipe for Edit and Delete."
4. Add and Edit sheet: RigGroup with Name (hint "Main Rig, Side Rig 1"), caption "RIG TYPE", RigGroup with two rows (Main Bore, subtitle "Full ledger and side ledger"; Side Bore, subtitle "Mini ledger and side ledger") each with a check in `accent` when selected and `Semantics(selected: true)`; pinned RigButton "Add" or "Update" with a `_saving` flag (LR-32). Inline error "Please enter a rig name" under Name (copy changed from "vehicle"; the validator logic is unchanged).
5. Delete Rig alert (RigAlertDialog): title "Delete Rig", message `Are you sure you want to delete "<name>"? This deletes all ledger entries, side-ledger data and agent information for this rig.`; when the rig is the active one add "You will be switched to <next rig name>"; buttons Cancel (default) and "Delete" (`moneyOutText`). Entry counts in the message are shown only if they can be read from the already loaded providers by the widget (display only); otherwise omitted.
6. Last rig: the Delete swipe action and sheet row are disabled (greyed, with the sheet row subtitle "At least one rig is required"); the old snackbar "Cannot delete the last rig" remains as the fallback.
7. Type change on a rig with entries: inline helper text under the type group "Changing the type changes which fields are shown. Existing entries are not modified." (copy only, the mockup has no such text; optional).

States:

| State | Behaviour |
|---|---|
| Default | RigGroup list |
| Loading | none (synchronous) |
| Empty | unreachable (a default rig always exists); EmptyState kept only as a guard: icon directions_car, "No rigs yet", RigButton "Add Rig" |
| Error | inline name error; write failure RigSnack |
| Disabled | Delete for the last rig; the pinned pill while saving; the active row tap |

Motion: sheet rise and alert fade 200 to 350 ms ease-out; ink press; zero under reduced motion.

Old section 4 items:

| Old item | Verdict |
|---|---|
| Title "Vehicle Management", "Add Vehicle", "Delete Vehicle?" | CHANGED (Rigs, Add Rig, Delete Rig) |
| FilledButton.tonalIcon add or extended FAB | CHANGED (header trailing icon only) |
| RigCard per rig, 40 dp icon square, Switch text button, overflow menu, 2 px primary border | CHANGED (RigRow in a RigGroup, "Active" badge, swipe and long press) |
| Type written in text, check for active | KEPT (badge text "Active" plus the type subtitle) |
| Expanded layout, hover, right-click, arrow keys, Delete key | DROPPED |
| Delete dialog with banner, counts if available, "You will be switched to" line | KEPT as an alert (counts optional) |
| Disabled delete for the last rig with tooltip | CHANGED (disabled row or action plus subtitle text; tooltips are not a touch pattern) |
| Add/Edit RigDialogShell, RigSegmented for type, `_saving` flag | CHANGED (sheet, two check rows; `_saving` flag KEPT) |
| Inline info on type change | KEPT, optional |
| Empty state | KEPT as a guard |

### R3. Logic touchpoints and LR items

Untouched: `_deleteVehicle` order (guard `vehicles.length <= 1`, `setCurrentVehicle` to the first other rig BEFORE `deleteVehicle`, then the refreshes incl. `cashEntriesProvider`, `ledgerEntriesProvider`, side providers, `agentsProvider`); `_switchVehicle` body until LR-01 replaces it; vehicle construction in `_saveVehicle` (Uuid v4, preserved `createdAt`, new `updatedAt`, `vehicleTypeIndex` 0 main, 1 side); `addVehicle`, `updateVehicle`; trimming; `vehicle.vehicleTypeIndex == 0` is Main Bore.

| Id | Dependency | Status |
|---|---|---|
| LR-01 | `_switchVehicle` is a FOURTH copy of the rig switch (`vehicle_management_screen.dart:141-162`): it clears only `searchQueryProvider` and `ledgerFilterProvider`, refreshes ledger, diesel, pvc, bit, hammer and agents, and pops. LR-01 names three copies (ledger sheet, desktop title bar, Portfolio header) and omits this one | approved for the three; extending to this copy is proposed, new: L2-r4-1 |
| LR-32 | `_saving` guard on Add and Update (double tap created two rigs) | approved |
| answer 4 | copy sweep Vehicle to Rig including snackbar and validator strings | approved (UI copy) |
| L3 L-11 | type change on a rig with entries | not scheduled; only the helper text is UI |
| L2-r4-2 | discard prompt on the small Rig sheet | proposed, new |

### R4. Acceptance criteria delta

1. The screen title is "Rigs"; no UI string contains "Vehicle" (title, add, edit, delete, snackbars, validator, subtitles); identifiers are unchanged.
2. Tapping a non-active row switches the rig, clears search and filters, shows `Switched to <name>` and returns to Settings (navigation outcome unchanged, unlike the mockup which stays on the screen, see conflicts_r4.md).
3. The active rig shows the "Active" badge and has no tap action; a 40 character name wraps to at most two lines and never pushes the badge out at 360 dp and at text scale 200 percent.
4. Swipe or long press gives Edit and Delete; Delete is disabled when only one rig exists.
5. Delete Rig alert names what is deleted and, for the active rig, the rig that becomes active; confirming deletes and switches in the existing order.
6. Add Rig with an empty name shows "Please enter a rig name" inline; double tapping Add creates one rig.
7. Both type rows are 48 dp or taller, expose `Semantics.selected`, and the selected one has a check (not colour only).
8. With the keyboard open the Name field and the pinned pill are visible; Android back closes the keyboard, then the sheet.
9. Light and dark: all text at least 4.5:1; no text below 11 sp.

### R5. Parity delta

Changes on purpose: line 13 (row "Vehicle" becomes "Rigs"); line 27 (the list shows "Active" badge, type written in the subtitle); line 29 ("Add Vehicle" and "Please enter a vehicle name" become "Add Rig" and "Please enter a rig name"; the validation rule is the same); line 30 ("Vehicle updated" becomes "Rig updated"); line 31 ("Cannot delete the last vehicle" becomes "Cannot delete the last rig"); line 32 ("Vehicle deleted" becomes "Rig deleted"). Must stay identical: line 28 behaviour (switch, reset search and filter, message `Switched to <name>`, return to Settings, new rig data visible), line 29 PVC hidden for a Side Bore rig, line 32 data of the deleted rig gone and another rig active.

### R6. Performance and Android notes

- Insets: edge to edge; sheet bottom padding adds `viewInsetsOf`; the pinned pill sits at inset + 12.
- Back: system back closes keyboard, then sheet or alert, then pops the screen; PopScope only if L2-r4-2 is approved.
- List: a handful of rows, plain `ListView` with one RigGroup; `VehicleCard` equivalent is a stateless RigRow taking `Vehicle`, `isActive` and callbacks.
- Controllers: `_VehicleFormDialog` already owns and disposes `_nameController`; keep that when it becomes a sheet; add the `_saving` bool in the same State.
- Remove the redundant `refresh()` after the dialogs only after checking `vehicle_provider.dart` (leave it if unsure).
- Budgets: p90 build and raster under 8 ms, p99 under 16 ms; no BackdropFilter.
