> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# side_ledger_screen (DEAD CODE: SideLedgerScreen is never instantiated)

File: `lib/features/side_ledger/side_ledger_screen.dart` (200 lines). Recommendation: DELETE the file after the live Side Ledger tab (`_buildSideLedgerContent` in `lib/features/home/combined_home_screen.dart`, line about 494, covered by the lead) has been migrated. No redesign is proposed for this screen.

## 1. Purpose and primary user task

Intended purpose: a landing page with four category cards (Diesel, PVC, Bit, Hammer) that push the four list screens. It has no user today: grep for `SideLedgerScreen(` across `lib/` finds only its own constructor (`side_ledger_screen.dart:11`); the shells (`main_navigation.dart`, `desktop_shell.dart`) use `CombinedHomeScreen`, whose Side Ledger tab provides the same four entry points (`combined_home_screen.dart:775, 792, 808, 824` push `DieselListScreen`, `PvcListScreen`, `BitListScreen`, `HammerListScreen`). The only importers of the four list screens besides the live tab are this file and the add-entry sheets (forms).

## 2. Current structure

`ConsumerWidget`: `Scaffold` > `Column`: gradient header (title "Side Ledger", current rig name from `currentVehicleProvider`, subtitle "Manage Diesel, PVC, Bit & Hammer entries"), then a padded 2 x 2 grid built from `Row`s of `_buildCategoryCard` (160 dp tall tile: 64 dp icon tile, 18 sp title, shadow blur 10). PVC is hidden when `isSideBoreProvider` is true. Category colors: Diesel `AppColors.warning`, PVC `AppColors.primary`, Bit `AppColors.success`, Hammer `AppColors.accent`. Reads `currentVehicleProvider` and `isSideBoreProvider` (`vehicle_provider.dart`). Writes nothing.

## 3. Problems found

1. Dead code (lines 10-200): no instantiation anywhere; it drifts from the live tab. Examples of drift: it has no period filter, no summary totals, and a different category color set than the live tab and the design system (Hammer teal here vs brown in the system, Bit green here vs purple in the Bit list).
2. If it were reachable, it would have a layout bug: when PVC is hidden the first `Row` holds a single `Expanded` tile, so the Diesel tile stretches to full width on a side bore rig (lines 70-103) while the second row keeps two half-width tiles (inconsistent grid).
3. `GestureDetector` tiles (line 155) have no ripple, no focus, no keyboard activation, no semantics label: not accessible; tiles are 160 dp so size is fine.
4. Raw `AppColors.appBarGradient`, `Colors.white.withOpacity` (deprecated pattern per CONVENTIONS.md), blur-10 shadow on each tile.

## 4. Redesign

None. Do not migrate it. Delete recommendation: remove `side_ledger_screen.dart` and its imports in the same cleanup task as `lib/features/home/home_screen.dart` (also dead, 378 lines), after the live Side Ledger tab uses `CategoryTile` (COMPONENTS.md) and the new list screens. Pre-delete check (a tester can do it): search the project for `SideLedgerScreen` and for the import path `side_ledger/side_ledger_screen.dart`; both must return only this file.

What the live tab must take over (if anything is read from this file for reference): category order Diesel, PVC (hidden when `isSideBoreProvider`), Bit, Hammer; each tile pushes the matching list screen with `Navigator.push(MaterialPageRoute)`.

Layout reference for the replacement `CategoryTile` grid (if the lead wants it): compact 2 columns, medium 4 columns, expanded 4 columns max width 720, tile min height 96, icon 24 in a 40 dp category container tile, title `titleMedium`, count and amount `amountSmall` (that is the lead's tab, not this file).

## 5. Logic touchpoints that must stay untouched

None apply to deletion except: the four list screens and their providers must remain reachable from the live tab; `isSideBoreProvider` must keep hiding PVC. Nothing in this file is imported by tests (verify with a search for `side_ledger_screen` in `test/`).

## 6. Acceptance criteria

1. Before deletion: a project search for `SideLedgerScreen` returns only the definition.
2. After deletion: `flutter analyze` is clean and the app builds for Android and macOS.
3. The Side Ledger tab still opens Diesel, PVC (not on side bore), Bit and Hammer lists.
4. No remaining reference to this file in docs or imports.

## 7. Performance notes

Not applicable (never built). Deleting removes about 200 lines and one `ref.watch(isSideBoreProvider)` site that never runs.


## Reconciliation 2026-10-13 (Apple look, Android only)

Unchanged by the new look: the screen is dead code and gets no redesign. The only task is the deletion (answer 7), which is the LAST task of the plan (T-Z99), in its own commit.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| none | none | `lib/features/side_ledger/side_ledger_screen.dart` | none | no mockup screen corresponds to this file. The live Side Ledger tab (J "Side Ledger" and "Side Ledger (Side rig)", function `sideLedger`, gradient CategoryTile grid) belongs to `combined_home_screen.md` (group r1); its category tiles use `catDiesel`, `catPvc`, `catBit`, `catHammer` |

### R2. What changes in the redesign (supersedes section 4)

Nothing is built. Section 4 stays: no redesign, delete after proof. DROPPED from section 4: the layout reference for a replacement `CategoryTile` grid with medium and expanded columns (macOS and width classes are out of scope; the live tab owns its own grid).

Evidence recorded on 2026-10-13 (read only searches, nothing deleted):
- `grep -rn "SideLedgerScreen\|side_ledger_screen" lib test macos android pubspec.yaml`, excluding the file itself: no matches.
- The file is 200 lines; its last commit is 8dd365c (the PVC removal for side bore rigs touched it although it is unreachable).
- Mentions remain only in documentation and `.claude/tasks/CURRENT.md` (historical task notes); they are not imports.

T-Z99 procedure (to be run by the implementer, in order): (1) repeat the grep above and paste the empty result in the commit body; (2) delete `side_ledger_screen.dart` together with `lib/features/home/home_screen.dart` only if its own grep is also empty (separate evidence block); (3) run `flutter analyze` and require zero errors, paste the summary line in the commit body; (4) confirm the Side Ledger tab still opens the Diesel, PVC (not on side bore), Bit and Hammer lists on an Android device or emulator; (5) one commit, nothing else in it.

### R3. Logic touchpoints and LR items

Untouched: the four list screens, their providers and `isSideBoreProvider` PVC hiding stay reachable from the live tab. No LR item. Nothing new.

### R4. Acceptance criteria delta

1. Before deletion the grep above returns nothing outside the file (verified 2026-10-13).
2. After deletion `flutter analyze` reports zero errors and the Android release build still compiles; the macOS target is frozen and only `flutter analyze` is required for it.
3. The live Side Ledger tab still opens all four lists (PVC hidden on side bore rigs).

### R5. Parity delta

P-DEAD-01 stays identical.

### R6. Performance and Android notes

Not applicable (never built). Deleting removes one unused `ref.watch(isSideBoreProvider)` site and about 200 lines.
