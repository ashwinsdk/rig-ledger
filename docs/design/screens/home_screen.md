> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# home_screen.dart (dead code)

File: `lib/features/home/home_screen.dart`, 378 lines. `HomeScreen` is not instantiated anywhere in `lib/` (grep for `HomeScreen(` finds only its own declaration; both shells use `CombinedHomeScreen`).

## 1. Purpose

Older single-tab ledger home (before the Side Ledger tab was merged into `CombinedHomeScreen`).

## 2. Current structure

Duplicates the live screen's header (search, title, filter), the month and year navigators, Daily/Calendar toggle, `SummaryRow`, `LedgerList`, `CalendarViewWidget`, `_showSearchSheet`, `_showFilterSheet`.

## 3. Problems found

1. Dead duplicate: any style change must be made twice or the copy rots (and a developer may edit the wrong one).
2. It lacks the vehicle switcher, Side Ledger tab and the custom range controls, so it already behaves differently from the live screen.
3. Same inconsistencies as `combined_home_screen.md` (hard-coded colors, 12 distinct paddings).

## 4. Redesign

None. Do not redesign. Recommendation: delete the file in the cleanup task after the live screen is migrated (MIGRATION_PLAN.md T-U-CLEAN-1). Verification before deletion: `grep -rn "HomeScreen" lib test` shows only the declaration; `flutter analyze` clean after removal; parity lines for the Ledger tab unchanged.

`lib/features/side_ledger/side_ledger_screen.dart` (200 lines) is in the same state: `SideLedgerScreen` is never instantiated; the live Side Ledger tab is `_buildSideLedgerContent` in `combined_home_screen.dart`. Same recommendation.

## 5. Logic touchpoints

None live. Providers it reads are all used by the live screen.

## 6. Acceptance criteria

1. After deletion, `flutter analyze` reports no new issues and the app builds on Android and macOS.
2. No import of `home_screen.dart` or `side_ledger_screen.dart` remains.
3. The Ledger and Side Ledger tabs behave identically (parity lines).

## 7. Performance notes

Removing 578 lines of dead code shortens analysis and review; no runtime effect (tree shaking already drops it).


## Reconciliation 2026-10-13 (Apple look, Android only)

`lib/features/home/home_screen.dart` (378 lines) and `lib/features/side_ledger/side_ledger_screen.dart` (200 lines) are dead code. They stay UNCHANGED by every redesign task: no restyle, no migration, no edits to keep them compiling beyond what `flutter analyze` forces. Deleting both is the LAST task of the plan, T-Z99 (answer 7), done in its own commit after the evidence below.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| none | none | `lib/features/home/home_screen.dart`, `lib/features/side_ledger/side_ledger_screen.dart` | none | the live screens are in combined_home_screen.md |

### R2. What changes in the redesign (supersedes section 4)

Nothing changes in these files (KEPT: "None. Do not redesign"). The recommendation of section 4 becomes the schedule: delete in T-Z99 after the live Ledger and Side Ledger tabs are migrated. macOS and desktop wording DROPPED: the old text says "app builds on Android and macOS"; the evidence now uses `flutter analyze` only (macOS is frozen and not built here).

Evidence found on 2026-10-13 (read only, must be re-run inside T-Z99):
- `grep -rn "home/home_screen.dart\|side_ledger/side_ledger_screen.dart" lib test` finds no import.
- `grep -rn "\bHomeScreen\b" lib test` outside `home_screen.dart` finds nothing; `grep -rn "SideLedgerScreen\b" lib test` outside its own file finds nothing.
T-Z99 procedure: re-run the three greps (also over `docs/` and `macos/` for stray references), delete both files, run `flutter analyze` (zero new issues), put the grep output and the analyze result in the commit body, one commit, no other change in it.

### R3. Logic touchpoints and LR items

None live. The providers these files read are all used by the live screens. No LR item. Proposed, new: none.

### R4. Acceptance criteria delta

1. Until T-Z99 no revamp commit touches either file (`git diff --stat` check in each task).
2. T-Z99: the three greps are empty after deletion, `flutter analyze` reports no new issue, the Ledger and Side Ledger tabs behave identically (parity P-LED and P-SLD lines).
3. The T-Z99 commit contains only the two deletions plus, if needed, `docs/` references.

### R5. Parity delta

None. P-LED and P-SLD lines must stay identical before and after T-Z99.

### R6. Performance and Android notes

No runtime effect (tree shaking drops both). Deleting them removes 578 lines of duplicate UI code that would otherwise need the new tokens and widgets. The deletion is the last task so no earlier task has to keep the dead copies compiling against changed shared widgets (`SummaryRow`, `LedgerList`, `CalendarViewWidget`): if a shared widget constructor changes earlier and `flutter analyze` flags the dead file, fix the call minimally in that task and note it in the commit, rather than deleting early.
