> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_trash_screen.dart (Deleted Transactions)

Group g2. Source: lib/features/cashbook/cashbook_trash_screen.dart (147 lines).

## 1. Purpose and primary user task

Review entries deleted from any book, restore one (into its book, or into a chosen book when its book is gone), delete one permanently, or empty the trash. Entries are removed automatically after 30 days. Parity: PARITY-053..056.

## 2. Current structure

`CashbookTrashScreen` (ConsumerWidget, stateless). Providers: `cashTrashProvider` (watch, newest deleted first), `cashSettingsProvider` (watch), `cashBooksProvider` (watch; read again in `_bookName`), notifier `cashEntriesProvider.notifier` (`purge(id)`, `restore(id, toBookId:)`, `emptyTrash()`). `DatabaseService.cashTrashRetention` (30 days) for `_daysLeft`.
Tree: `Scaffold(cashAppBar('Deleted Transactions', [PopupMenuButton 'Delete All']))` > `CashPageBody(900)` > `Column[Padding Text '... removed automatically after 30 days.' (12 sp), Expanded(empty text or ListView.separated of ListTile (notes, 3-line subtitle: formatDayHeader + time, book name | N days left; trailing amount colored))]`.
Row tap -> `_rowMenu` bottom sheet (Restore, Delete). Delete -> `confirmCashDialog('Delete Transaction', 'This transaction will be deleted permanently.')` then `purge`. Restore: if the book is gone, `SimpleDialog` 'Restore into account' picks a book; then `restore`; snackbar 'Transaction restored'. Delete All: `confirmCashDialog('Delete All', ...)` then `emptyTrash`.

## 3. Problems found

1. Plural bug "1 days left" (trash:132) (G2-B16); `_daysLeft` recomputed per row per build using `DateTime.now()`.
2. Permanent delete and Delete All give no feedback; Delete All shows even with an empty trash (trash:53-57, 92-96, 99-101) (G2-B17).
3. Two taps to restore (row, then Restore) and the choice is hidden: a plain-looking `ListTile` gives no hint it is interactive; no trailing icon.
4. The retention note is a 12 sp line at the top that scrolls away? It is outside the list so stays; but it is `textSecondary` 4.76:1 OK.
5. `Icons.restore` and `Icons.delete_forever` filled; delete icon red (`AppColors.error`, trash:42-43) (3.76:1 as icon, passes the 3:1 UI minimum).
6. Subtitle packs date, time, book and days left into 2 lines at 12 sp with a `\n` and `isThreeLine: true` (trash:130-134): at 200 percent text the three-line tile overflows its fixed height. UNVERIFIED.
7. Amount trailing text colored green or red only (no icon) (trash:135-137).
8. Empty state bare text `textHint` (trash:116-118).
9. No undo after permanent delete (irreversible by design; confirm dialog exists).
10. Book name for a missing book falls back to `bookNameSnapshot` or "Deleted account" with no visual cue that restore needs a target.

## 4. Redesign

- `RigScaffold(appBar: RigAppBar(title: 'Deleted Transactions', actions: [RigMenuButton with 'Delete All' (negative, disabled when the trash is empty)]), maxContentWidth 640 / 1100)`.
- Info banner (not an error): `RigCard` tone `container` with `Icons.info_rounded` 20 `info` and `bodySmall` "Deleted transactions are removed automatically after 30 days." (same text), padding `s3`, margin `s4`.
- Row: `RigCard` (radius `lg`, padding `s4`, min height 72): `[TypeBadge] [Column: notes bodyLarge maxLines 1 (placeholder "-"), bodySmall onSurfaceVariant line 1: day header string + time (strings from `formatDayHeader` and `formatTime`), line 2: book name (pill) and "N day(s) left" with correct plural, `outstanding` role text when <= 3 days left] [AmountText medium moneyIn/negative] [trailing RigMenuButton Icons.more_vert_rounded tooltip "Options"]`. Row tap opens the same Restore / Delete choice (`RigChoiceDialog`: sheet on compact, menu on expanded); the trailing button opens the same menu. Restore action with `Icons.restore_rounded`, Delete with `Icons.delete_forever_rounded` in `negative`.
- Wide screens: two-column list is not used (long rows); max width 720.
- Restore into another book when the original is gone: `RigChoiceDialog` titled 'Restore into account' (same title), list of books; the row shows a caption "Original account deleted" `bodySmall` `outstanding` when applicable (text derived from the same `books.any(...)` check).
- Feedback: `showRigSnack(success, 'Transaction restored')` (unchanged), `showRigSnack(info, 'Deleted permanently')` after purge, 'Trash emptied' after Delete All (new text).
- Empty: `EmptyState(icon: Icons.delete_sweep_rounded, title: 'No deleted transactions', hint: 'Deleted entries stay here for 30 days')`.
- Desktop: hover `surfaceContainerHigh`, Enter opens the menu, Delete key on a focused row opens the permanent-delete confirm (not immediate), right-click opens the same menu.

Tokens: `s4` page, `s2` gap; `lg` radius; `bodyLarge`, `bodySmall`, `amountMedium`; colors `moneyIn`, `negative`, `outstanding`, `info`, `surfaceContainer`.

State table: Default (rows); Loading none; Empty `EmptyState`; Error none (provider calls return no error); Disabled ('Delete All' when empty).

Motion: row removal fade/collapse `base` 200 ms after restore or purge (`AnimatedSize` + fade), disabled in reduced motion.

## 5. Logic touchpoints that must stay untouched

- `cashTrashProvider` order; `cashEntriesProvider.notifier.restore(e.id, toBookId: target)` (target null when the book still exists), `purge(e.id)`, `emptyTrash()`.
- `_daysLeft`: `deletedAt + cashTrashRetention - now`, inDays, clamped at 0, plus 1 when positive.
- `_bookName`: current book name, else `bookNameSnapshot`, else 'Deleted account'.
- Confirm dialogs and their texts: 'Delete Transaction' / 'This transaction will be deleted permanently.'; 'Delete All' / 'All deleted transactions will be removed permanently.'
- Restore into a chosen account only when the original book is missing; cancel aborts.
- `ref.watch(cashBooksProvider)` so names refresh.

## 6. Acceptance criteria

1. Each deleted entry shows notes, date and time, book and days left (with correct singular/plural), amount with type indicator.
2. Restore puts the entry back in its book and balances recompute; when the book is gone a book picker appears first and cancel aborts.
3. Permanent delete asks for confirmation and then removes the entry for good; Delete All asks and empties the trash.
4. Delete All is disabled when the trash is empty.
5. A snackbar confirms restore, permanent delete and Delete All.
6. At 200 percent text the rows grow with no overflow.
7. Rows are >= 72 dp and fully tappable; the trailing button >= 48 dp.
8. Entries older than 30 days are not listed (purged at startup; unchanged).

## 7. Performance notes

- Convert to `ListView.builder` (already builder); extract `_TrashRow` with `ValueKey(entry.id)`.
- Compute `_daysLeft` and `_bookName` once per build via a precomputed map; `ref.read(cashBooksProvider)` per row (trash:15) is a list scan per row: build `names` map once from `ref.watch(cashBooksProvider)`.
- Screen is a ConsumerWidget: keep it stateless; the menu callbacks use `ref.read`.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Deleted Transactions | `SC.cbTrash`, `trashSheet`, `trashDel` | lib/features/cashbook/cashbook_trash_screen.dart | LargeTitleScaffold (pushed, trailing More), footer text, RigGroup of entry rows with RowActions (Restore, Delete), RigSheet (Restore, Delete), RigAlertDialog, EmptyState | Mockup row meta: day, time, book name and "N days left". |
| Deleted Transactions empty | `SC.cbTrash` with `UI.state=empty` | cashbook_trash_screen.dart | EmptyState (icon `delete_sweep`, "No deleted transactions", "Deleted transactions appear here for 30 days.") |  |

### R2. What changes in the redesign (supersedes section 4)

Deleted Transactions (pushed from the drawer):
1. LargeTitleScaffold, title "Deleted Transactions", back chevron, trailing More button (menu with "Delete All", `moneyOutText`, disabled when the trash is empty).
2. Footer text under the title: "Deleted transactions are removed automatically after 30 days." (13 sp `label2`, no card).
3. One RigGroup of rows (min 64 dp): line 1 notes (17 sp weight 600, one line, ellipsis) and the signed amount (`moneyInText` or `moneyOutText`, never compact); line 2 13 sp `label2`: `dGroup` and time, book name, "N days left" (singular and plural as today). RowActions: swipe left reveals Restore (`accentButton`) and Delete (`moneyOutButton`); tap opens the RigSheet (title = notes) with Restore and Delete.
4. Delete asks RigAlertDialog "Delete Transaction": "This transaction will be deleted permanently." Delete All asks "Delete All": "All deleted transactions will be removed permanently." Destructive actions in `moneyOutText`.
5. Restore when the original book is gone: RigSheet "Restore into account" listing the books; cancel aborts. The caption "Original account deleted" shows on the row in `outstandingText` when applicable (unchanged rule).
6. Feedback: RigSnack "Transaction restored", "Deleted permanently", "Trash emptied" (the last two are new copy).
7. Empty: EmptyState as above; "Delete All" disabled.
8. Bottom padding inset + 24 dp.


Old section 4 items:

- Old 4 info banner RigCard: CHANGED to the footer text (mockup `foot`).
- Old row RigCard with TypeBadge: CHANGED to a RigRow with the signed amount; TypeBadge DROPPED.
- Old trailing menu button per row: CHANGED to RowActions and the tap sheet (non-gesture path = tap).
- Old two-column and max width 720 note, desktop keys: DROPPED.
- Old restore dialog `RigChoiceDialog`: CHANGED to a RigSheet.
- Old snackbars: KEPT.
- Old empty state hint "Deleted entries stay here for 30 days": CHANGED to the mockup text "Deleted transactions appear here for 30 days."
- Old motion (row removal fade and collapse): KEPT as a 200 ms collapse, none under reduced motion.


States:

| State | Rule in the new look |
|---|---|
| Default | footer and rows |
| Loading | not applicable |
| Empty | EmptyState |
| Error | not applicable (provider calls return no error) |
| Disabled | "Delete All" disabled when the trash is empty |


Motion: ink press; row collapse 200 ms; sheet rise 250 ms; alerts fade 200 ms; reduced motion removes durations.


### R3. Logic touchpoints and LR items

Untouched: `cashTrashProvider` order, `restore(e.id, toBookId: target)`, `purge(e.id)`, `emptyTrash()`, `_daysLeft` arithmetic, `_bookName` fallbacks, confirm texts, restore-into-account only when the book is missing, `ref.watch(cashBooksProvider)` for names.


- LR-24 (approved): `dGroup` and the rupee sign.
- No new logic item. Swipe Restore and Delete reuse `restore` and `purge` with the existing confirm for Delete.


### R4. Acceptance criteria delta

1. Each row shows notes, date, time, book and days left with correct singular and plural, and the signed amount.
2. Restore returns the entry to its book; when the book is gone the account sheet appears first and cancel aborts.
3. Delete asks and then removes for good; Delete All asks and empties the trash; the menu item is disabled when empty.
4. Swipe and tap paths give the same results; swipe Delete still shows the confirm.
5. At text scale 200 percent rows grow, nothing clips; targets 48 dp; 360 dp and 412 dp, light and dark.
6. Entries older than 30 days are not listed (purge at startup, unchanged).


### R5. Parity delta

Change on purpose:

- PARITY-052 to 055 presentation only: row actions by swipe, tap sheet and footer text; behaviour identical.
- Amounts and dates use the rupee sign and `dGroup`.


Must stay identical:

- PARITY-052 trash, PARITY-053 restore, PARITY-054 permanent delete, PARITY-055 30-day purge, PARITY-056 restore into another book when the book is gone.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- List strategy: builder; `ValueKey(entry.id)`; collapse animation with `AnimatedSize` only on the removed row.
- No controllers; the restore sheet returns a book id through `Navigator.pop`.

