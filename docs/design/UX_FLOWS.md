# UX Flows: before and after

> RECONCILED 2026-10-13: Android only, Apple-inspired look (DESIGN_DIRECTION_APPLE.md). Step counts stay valid unless the Reconciliation section at the end says otherwise. macOS shortcuts and sidebar rows are DROPPED.

Step counts are taps or clicks (T) and typed fields counted separately. "Before" is read from the code and the emulator walk-through of 2026-10-12; "after" is the proposal. No flow gains or loses a capability; only the number of steps, the visibility of state and the shortcuts change. Anything that would need new behavior is in LOGIC_REQUESTS.md.

## F-1 Check balances for the month (most frequent)

| | Before | After |
|---|---|---|
| Open app (Ledger tab) | Summary and feet totals visible (0 T) but they push the list to the lower 36 percent of the screen | Highlights visible when expanded (0 T); on first scroll they hide and the strip keeps "October 2026, Balance" visible |
| See the full bill list | scroll inside about 326 dp; header never moves | list uses about 678 dp when collapsed (2.1x), 0 extra T |
| Change month | chevron (1 T per month) | same; also the strip shows the month when collapsed |
| Read a long amount | clipped or tiny text, no way to see the exact value | tap or long press shows the full value |
| Reveal controls again | n/a | scroll up, or tap the strip (1 T) |
Shortcuts (macOS): Cmd+1 (Ledger) as today.

## F-2 Add a bill (main bore rig)

| | Before | After |
|---|---|---|
| Start | FAB (1 T) or Cmd+N | same, FAB has a tooltip and sits clear of the last card |
| Fill the form | 12 to 15 fields, Save only at the end of a long scroll; autovalidate only on submit | same fields and order (parity); Save pinned at the bottom; fields move with `Next`; errors appear after the first submit and then live |
| Add a payment | open payment dialog from the payment editor, choose mode, date, receiver, payer, note | same fields; dialog presents mode as segmented chips; payer autocomplete as today |
| Commission | rates prefilled from the agent; override and Auto reset | same, grouped in one card with a one-line result |
| Save | 1 T | 1 T, success snackbar "Bill saved", list scrolls to the new bill is NOT done (would change behavior); the new bill is visible at its date |
Steps saved: no tap change, but zero scroll to reach Save.

## F-3 Add a side ledger purchase (diesel, PVC, bit, hammer)

| | Before | After |
|---|---|---|
| Start | switch to Side Ledger tab (1 T), FAB (1 T), choose category in the sheet (1 T) | same 3 T, or open the category tile then its own add control (unchanged); icons match the tiles |
| Form | 4 separate form screens with different header styles | one layout (`RigAppBar`, `RigScaffold`, pinned Save) |
| Save | 1 T | 1 T |

## F-4 Switch rig

| | Before | After |
|---|---|---|
| Mobile, from Ledger | tap the title (1 T), tap a rig (1 T) | same; the control now shows an arrow and has a tooltip |
| Mobile, from Portfolio | go back to Ledger (1 T), tap title (1 T), pick (1 T), return to Portfolio (1 T) = 4 T | tap the rig pill in the Portfolio header (1 T), pick (1 T) = 2 T (B1) |
| macOS | title bar popup (2 T) | same, plus an identical control inside the Portfolio page |
| Feedback | none | snackbar "Switched to <rig>" |

## F-5 Open Account Ledger and see one day (B2)

| | Before | After |
|---|---|---|
| Open | Accounts tab (1 T) | same |
| Daily view | Daily chip (1 T) | same |
| Jump to a date six months ago | arrow x about 180 T, or overflow menu "Date" (3 T) that switches the tab to All and hides arrows | tap the date (1 T), pick the day (1 to 3 T), Daily chip and arrows stay |
| Day with no entries | muted "No transactions" | empty state with the carried balance still shown |

## F-6 Export a report

| | Before | After |
|---|---|---|
| Start | Settings (1 T), export item (1 T) | same |
| Configure and generate | long screen of options, one big button at the end | same options, grouped sections, sticky Generate button, progress indicator, success state with Share and Save actions |
| Account Ledger report | Report icon in the Accounts header (1 T) | same |
Export content is unchanged (frozen).

## F-7 Sync and backup

| | Before | After |
|---|---|---|
| macOS | title bar indicator (tap) or Cmd+S | same, text label next to the icon (Synced, Syncing, Failed) |
| Android | Settings (1 T) then Drive sync controls (1 T); periodic sync runs silently | same entry points; status chip at the top of Settings shows last sync time and result; errors in an `ErrorBanner` with Retry |
| Restore or clear data | confirmation dialogs | `ConfirmDialog(destructive)`, labels spell out the consequence; no logic change |

## F-8 Search and filter bills

| | Before | After |
|---|---|---|
| Search | search icon (1 T), type; sheet | same on mobile; macOS inline field, Cmd+F focuses it (needs approval B-05) |
| Filter | filter icon (1 T), choose values, Apply | same; active state shown by a dot and a "Filters on" chip in the strip |
| Clear | open sheet, Clear All (2 T) | strip chip "Clear" (1 T) calling the same reset |
| Empty result | "No entries yet" (misleading) | "No entries match" with Clear |

## F-9 Review agents and commission

| | Before | After |
|---|---|---|
| Open | Agents tab (1 T) | v2.0.1: no Agents tab; Portfolio, Agents section (Portfolio tab, 1 T), tap an agent for the detail sheet (Edit, Delete, prices per type) |
| Edit default commission rates | agent dialog | same fields; dialog uses `RigDialogShell` and `AmountField` |
| See commission totals | line on the agent card | `AmountTile` row with tap for full value |

## Shortcut summary (macOS), unchanged unless marked

Cmd+1 to Cmd+5 areas; Cmd+N new entry; Cmd+S sync; Cmd+F search (becomes functional, needs approval); Esc closes dialogs and sheets; Tab and Shift+Tab move focus; Enter activates the focused control and submits single-field dialogs.

## Reconciliation 2026-10-13 (Apple look, Android only)

| Flow | Change from the table above |
|---|---|
| F-1 Check balances | the expanded header is the large title area: ring card (received of billed), 2 x 2 metric cards (Total, Received, Balance, Commission) and depth tiles (7" Depth, 8" Depth, 7" PVC, 8" PVC, MS Pipe, 3 + 2). On scroll the large title collapses to a 17 dp inline title with the status strip (period and Balance). Reveal: scroll up, or tap the strip. Tap a metric card shows the full value (compact L and Cr are allowed only in these tiles). No steps added |
| F-2 Add a bill | the form is a full-height sheet with inset grouped rows, a live total card at the top and a pinned 50 dp pill (Save) above the keyboard. Back (system or the close control) with unsaved edits asks "Discard changes?" (LR-25). The double-tap guard (LR-32) makes Save one record. Same fields and order (parity) |
| F-3 Side ledger purchase | Side Ledger home has gradient category tiles (Diesel orange, PVC teal, Bit purple, Hammer pink); same 3 taps; forms use the same sheet layout; Pending (total minus paid) keeps its name |
| F-4 Switch rig | the rig pill in the Ledger and Portfolio large title opens the Rig sheet (B1); copy says "Rig". One shared `switchRig` (LR-01). Portfolio: 2 taps (was 4 on the earlier build). No desktop popup |
| F-5 Account Ledger day | Daily chip, tap the date, `DatePickerSheet` (B2), Daily and arrows stay (LR-02). Day without entries: empty state, carried balance still shown. Rupee sign everywhere (LR-24) |
| F-6 Export | unchanged content; screens in the new look; sticky Generate pill; progress and a success state |
| F-7 Sync and backup | Settings starts with the Drive hero card (connected, not connected, error with Retry). Clear All Data alert says Account Ledger books and notes are erased too; Restore: choose the file first, then confirm (LR-28) |
| F-8 Search and filter | search field under the large title (pinned when collapsed); filter sheet; "Filters on" chip in the status strip; "No entries match" with Clear. Cmd+F is DROPPED (macOS) |
| F-9 Agents and commission | inset list with a long-press menu and a trailing more button (Edit, Delete; no swipe, Q-O7); Delete Agent alert does NOT preselect "Delete all entries" (G3-B15) |

New flows: F-10 Appearance (Settings, Appearance row, sheet System/Light/Dark, applies immediately, 2 taps). F-11 Lazy tabs (first visit to Portfolio, Agents or Settings builds the screen; later visits are instant and keep state). F-12 Android back (keyboard, then sheet or dialog, then screen; on a root tab nothing happens unless Q-O6 changes it).

Dropped: all macOS shortcut rows (Cmd+1..5, Cmd+N, Cmd+S, Cmd+F), the sidebar, the title bar sync chip.
