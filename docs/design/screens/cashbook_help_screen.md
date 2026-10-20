> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_help_screen.dart (Help)

Group g2. Source: lib/features/cashbook/cashbook_help_screen.dart (83 lines).

## 1. Purpose and primary user task

Read a short how-to for the Account Ledger: what it is, receivers and bill payments, Previous Balance, deleted transactions, Transfer, reports, backup and import. Static content. Parity: PARITY-077 (Help item in the hub).

## 2. Current structure

`CashbookHelpScreen` (StatelessWidget). `_items` is a const list of 8 (title, body) records. Tree: `Scaffold(cashAppBar('Help'))` > `CashPageBody(700)` > `ListView(16)` of `Padding(bottom 16) > Column[title 15 sp w700, body `textSecondary` line height 1.35]`. No providers, no state.

## 3. Problems found

1. Plain wall of text: 8 sections in one scroll with no visual separation except 16 dp gaps; titles are 15 sp bold, not on the type scale (help:68-71).
2. Body text color `AppColors.textSecondary` (#64748B) 4.76:1 passes but is the same gray used for captions; long body copy should use `onSurface` for reading comfort.
3. No icons or anchors; no way to jump to a topic; no search; the hub label is "Help" but the screen has no heading explaining it is Account Ledger help (the app bar says "Help").
4. Text is selectable? No: `Text` is not `SelectableText`, so desktop users cannot copy (help:72-75).
5. One topic ("Backup") mentions "Settings > Backup & Restore" as plain text with no link; the greater-than sign is ASCII.
6. No max line length control beyond `CashPageBody(700)` on desktop; on tablets text spans the full width.
7. Content is hard-coded here, so the copy duplicates statements about behavior (PARITY and settings); changes in behavior require editing text by hand (maintenance note, no code change needed).

## 4. Redesign

- `RigScaffold(appBar: RigAppBar('Help'), maxContentWidth 640)`.
- Intro: `bodyMedium` `onSurfaceVariant` one-liner above the list: "How the Account Ledger works" (new copy, 1 line).
- Topics as `ExpansionTile`-style `RigCard`s (radius `lg`, padding `s4`, 8 dp gap) with a leading 40 dp `primaryContainer` icon tile and the title `titleMedium`; only the first topic is expanded by default; tap toggles (`fast` 150 ms size animation, none in reduced motion). Same 8 titles and the same body strings, unchanged text. Icons (rounded): What is Account Ledger? `Icons.account_balance_wallet_rounded`; Receivers and bill payments `Icons.person_pin_rounded`; Previous Balance `Icons.history_rounded`; Deleted transactions `Icons.delete_sweep_rounded`; Transfer `Icons.swap_horiz_rounded`; Reports `Icons.picture_as_pdf_rounded`; Backup `Icons.cloud_upload_rounded`; Import `Icons.file_download_rounded`.
- Body: `bodyMedium` `onSurface`, the `bodyMedium` line height (14/20), `SelectableText` on desktop (`PlatformHelper.isDesktop`), plain `Text` on mobile.
- Expanded (>=900): two columns of cards (each max 480) or a single centered column; default single column 640 to keep reading width under 75 characters.
- Empty and error states: not applicable (static).
- Semantics: each card is a button with `expanded` state; title announced with the body.

Tokens: `s4` padding, `s2` gap; radius `lg`; type `titleMedium`, `bodyMedium`; colors `onSurface`, `onSurfaceVariant`, `primary`, `primaryContainer`.

State table: Default (first topic open); Loading n/a; Empty n/a; Error n/a; Disabled n/a; Expanded/collapsed per topic.

Motion: expand/collapse `fast`; chevron rotates 180 degrees in `fast`.

## 5. Logic touchpoints that must stay untouched

- The `_items` strings (titles and bodies) are copy that describes behavior; do not reword statements about receivers, previous balance, 30 day trash, transfer, reports, backup and import.
- The screen has no providers; hub entry `Help` -> `CashbookHelpScreen()` (cashbook_hub_screen.dart:52).

## 6. Acceptance criteria

1. All 8 topics are present with unchanged titles and body text.
2. Tapping a title expands or collapses its body; the first is open on entry.
3. Body text contrast >= 4.5:1; at 200 percent text no overflow; cards grow.
4. On macOS body text is selectable and can be copied.
5. Content width is capped at 640 on every platform.
6. Each card is >= 56 dp tall collapsed and keyboard operable (Enter toggles).

## 7. Performance notes

- Static, const list; at most 8 cards, no builder needed. Make each topic card a const-constructible widget with its own expanded `StatefulWidget` state so toggling one does not rebuild the others.
- No controllers, no providers, no per-frame setState.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Help | `SC.cbHelp` | lib/features/cashbook/cashbook_help_screen.dart | LargeTitleScaffold (pushed, title "Help"), one RigCard per topic (title 17 sp weight 600, body 15 sp `label2`) | The mockup shows every topic expanded as a card; the old design proposed collapsible cards. |

### R2. What changes in the redesign (supersedes section 4)

Help (pushed from the drawer): LargeTitleScaffold, title "Help", back chevron. Eight RigCards (margin 20, gap 12, radius 20) in the existing order, each with the title (17 sp weight 600) and the body (15 sp `label2`, line height 1.4). All topics are shown expanded; the text is not collapsible. Body text is plain `Text` (no selection on Android). Bottom padding inset + 24 dp. Topics, titles and bodies are unchanged: What is Account Ledger?, Receivers and bill payments, Previous Balance, Deleted transactions, Transfer, Reports, Backup, Import.


Old section 4 items:

- Old 4 intro line "How the Account Ledger works": DROPPED (not in the mockup).
- Old collapsible ExpansionTile cards with a leading icon tile and first topic expanded: CHANGED to always-expanded cards without icon tiles; collapse behaviour and chevron rotation DROPPED.
- Old `SelectableText` on desktop and two-column expanded layout: DROPPED.
- Old semantics (button with expanded state): CHANGED to plain headings (title as a header, body text).
- Old motion: DROPPED.


States:

| State | Rule in the new look |
|---|---|
| Default | eight cards |
| Loading | not applicable |
| Empty | not applicable |
| Error | not applicable |
| Disabled | not applicable |


Motion: none (static); ink press is not needed because the cards are not tappable.


### R3. Logic touchpoints and LR items

Untouched: the `_items` titles and bodies (copy that describes behaviour), the hub entry `Help` to `CashbookHelpScreen()`, no providers.


- None. Wording in the Help body mentions "Deleted transactions" for 30 days; unchanged.


### R4. Acceptance criteria delta

1. All 8 topics are present with unchanged titles and bodies and are fully visible without a tap.
2. Body text contrast is at least 4.5:1 in light and dark; at text scale 200 percent the cards grow and nothing is clipped; 360 dp and 412 dp.
3. Content ends 24 dp above the bottom inset; Android back pops to the ledger.


### R5. Parity delta

Change on purpose:

- No PARITY line covers Help text layout; PARITY-077 lists Help as a hub destination (unchanged).


Must stay identical:

- All eight topic texts and the hub entry.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- Static `const` cards in a `ListView`; no providers, no controllers.

