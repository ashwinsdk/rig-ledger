# Design direction: Apple Health and Fitness look, Android platform

Update 2026-10-13: the app is Android only. The look stays Apple-inspired; the platform behaviour is Android (Inter font, edge-to-edge insets, system back, 48 dp targets, ripple, keyboard handling). macOS was dropped from the plan (Step 4 removed; the removed code is in `mockup/archive/`).

Status: proposal, pending approval. The visual source of truth is `mockup/rigledger_apple_mockup.html` (light, dark, Android phone). No flow, label or calculation was changed; logic-affecting items are in LOGIC_REQUESTS.md (LR-21 to LR-24, plus the existing LR-01, LR-02, LR-03). This document overrides only the visual decisions in DESIGN_SYSTEM.md.

Evidence: ten reference screenshots measured at 3x with PIL (side margin 20 pt, card gap about 10.7 pt, card radius about 18 to 20 pt, tab capsule about 61 pt with 22 pt side inset and 21 pt bottom inset). No Apple artwork, names, icons or illustrations are used; only layout, proportion and behaviour.

## 1. Decisions

| # | Decision | Why |
|---|---|---|
| A1 | Large 34 pt title, collapsing to a centred 17 pt inline title in a blurred header with a hairline | the pattern users already know; gives the list the screen back |
| A2 | Floating tab capsule with a darker selected capsule (5 tabs, order unchanged), sitting above the bottom system inset; solid 94 percent surface by default | matches the reference; content scrolls under it (list padding = bar + inset + 24) |
| A3 | Surfaces: canvas, inset grouped lists and cards (radius 20, margin 20, gap 12 by decision), no borders in dark, soft shadow only in light | quieter than today's bordered cards; fewer shadows in long lists |
| A4 | Light and dark, System by default, a Settings row Appearance (System, Light, Dark) | the brief; today the app is light only |
| A5 | System blue as the accent until the logo and brand colour exist; accent is five tokens, so the brand drops in later | brand pending |
| A6 | Colour carries meaning with a darker text variant per hue: income green, expense red, pending orange, commission purple, categories Diesel orange, PVC teal, Bit purple, Hammer pink | AA contrast; graphics keep Apple's brighter colours |
| A7 | Ledger tab follows the Fitness Summary: ring card (received of billed), 2 x 2 metric cards, depth tiles in a 3 column grid (5 tiles wrap 3 + 2), day groups as inset lists with sticky headers (ship, no flag), swipe and long press actions | B5 never-break highlights, B4 collapse |
| A8 | Side Ledger home follows Health Browse: two column gradient category tiles, then inset lists | |
| A9 | Forms are full height sheets with inset grouped rows, a live total card at the top and a pinned pill at the bottom | removes the long scroll to Save (UX_FLOWS.md F-2) |
| A10 | Portfolio follows Health Summary and Highlights: rig pill (B1), Pinned metric cards, insight cards with sentence, legend and scrub chart | |
| A11 | Alerts are iOS style centred cards; forms and pickers are sheets | confirmations stay short, inputs get room |
| A12 | One money formatter (rupee sign, en-IN grouping, paise only when present, compact L and Cr only inside tiles with full value on tap) and three date formats | TOKENS.md section 7 |
| A13 | Rounded icon set only; touch targets 48 dp minimum | Android rule |
| A14 | Android platform: Inter first in the font stack (vendored, OFL); device frame 412 x 892 dp (and 360 x 800); edge-to-edge status bar 28 dp; bottom inset 24 dp (gesture) or 3-button bar; every sticky bottom control above the inset | the real device metrics |
| A16 | System back as in the Dev panel (keyboard, popover, top dialog or sheet, top screen, then leave the app on a root tab); predictive back enabled in the first Android build; no edge swipe in the app; Escape is wired to it | Android back and predictive back |
| A17 | Pressed feedback on every tappable (inset overlay in the mockup, ripple in Flutter), no scale feedback | Android press feedback |
| A18 | Keyboard: a 300 dp simulated keyboard shrinks the screen; the focused field and the primary button stay visible (checked by `qa/shoot.mjs`) | form usability |
| A19 | ONE Glass blur toggle, default OFF: solid surface at about 94 percent with a hairline. Blur is profiled on the reference Android device before it is ever switched on | raster cost on mid-range Android |
| A20 | Theme follows the system (Android 10 and up), no dynamic colour | |
| A21 | macOS is dropped | the app is Android only |
| A15 | Motion 200 to 350 ms ease-out, press scale .98, ring and bars reveal; off under reduced motion | |

## 2. What must change in DESIGN_SYSTEM.md

| Section | Change |
|---|---|
| 1 Design direction | add rule 4: "Apple-inspired look on Android: large titles, inset groups, floating bars, Android behaviour." Keep rules 1 to 3. |
| 2 Token architecture | replace `ColorScheme.fromSeed` with two hand-built schemes plus `RigColors` (TOKENS.md section 6); add `RigGlass` tokens |
| 3.2 Roles | replace by the TOKENS.md resolved table; keep seed #315D9A as the provisional brand accent only (Dev panel option); default accent is system blue |
| 3.3 Dark | "not scheduled" becomes scheduled and replaced by TOKENS.md dark column (true black canvas, #1C1C1E surfaces) |
| 5 Spacing | screen padding 20 (compact), card gap 12, add `s5 = 20` as the standard margin |
| 6 Radii | `lg 16` cards become `card 20`; sheet top 24 becomes 28; add `tile 28` and `alert 14`; chips and buttons `full` |
| 7 Elevation | levels 1 and 2 lose the 1 px outline (dark) and use a shadow in light only; level 3 adds the glass bars (blur 20 to 22, one per screen) |
| 8 Motion | unchanged durations; add press scale .98 and ring and bar reveal; keep reduced-motion rule |
| 9 Iconography | already rounded: no change |
| 10 Money, dates | `moneyCompact` drops K (L and Cr only); Account Ledger shows the rupee sign (LR-24); dates become `dRow`, `dGroup`, `dFull` (TOKENS.md) |
| 11 to 14 Components, forms, lists, navigation | add `RigGroup`, `RigFormRow`, `RigMetricCard`, `RigRing`, floating `RigTabBar`, large-title scaffold; forms become sheets; day headers sticky; alert dialog replaces `ConfirmDialog` visuals |
| 15 Desktop | not applicable: macOS is dropped, keep the section out of the implementation scope |
| 16 Accessibility | add the text-variant rule (use `-tx` colours for text), 48 dp targets, the contrast matrix as a golden test input |

## 3. What must change in MIGRATION_PLAN.md

| Task | Change |
|---|---|
| T-U01 Theme tokens and RigTheme | build light and dark `ColorScheme` + `RigColors`; `ThemeMode.system` |
| T-U02 Formatters | implement `money`, `moneyCompact` (L, Cr), `qty`, `dRow`, `dGroup`, `dFull` as in TOKENS.md section 7 |
| T-U03 Bundled UI font | Inter 400, 500, 600, 700 with tabular figures |
| T-U06 Amount widgets | `MoneyText` with the fit pipeline (full, 75 percent, compact, last guard) and tap for full value |
| T-U08 Feedback and overlays | alert, sheet, floating snackbar capsule as in the mockup |
| T-U19 Shell and header recipes | large title scaffold, collapsed blurred header, status strip |
| T-U20 Mobile shell | floating tab capsule instead of the stock `NavigationBar` look; keep 5 tabs |
| T-U21 Desktop shell | dropped (macOS removed) |
| T-U30 to T-U35 | Ledger highlights as ring and metric cards; bill card as inset row with swipe |
| T-U40, T-U41 | Portfolio per A10 (insight cards need LR-21 and LR-22; ship the metric cards first) |
| T-U42 (B2) | calendar sheet date picker (needs LR-02) |
| T-U50 to T-U59 | restyle as full height sheets and inset grouped rows |

## 4. New tasks (all after T-U01)

| ID | Task | Depends | Logic? |
|---|---|---|---|
| T-A01 | Light and dark tokens: `RigColors`, schemes, glass tokens, contrast golden | T-U01 | no |
| T-A02 | Appearance setting row, persisted theme mode | T-A01 | yes, LR-23 |
| T-A03 | `RigTabBar` floating capsule (mobile) | T-A01 | no |
| T-A04 | Large title and collapse scaffold with status strip (B4) | T-A01 | no |
| T-A05 | Alert, sheet and snackbar components | T-A01 | no |
| T-A06 | Money and date formatters, `MoneyText` fit pipeline, stress tests (B5) | T-U02 | no |
| T-A07 | `RigGroup` and `RigFormRow` (inset grouped lists and form rows) | T-A01 | no |
| T-A08 | `RigRing`, metric cards, depth tiles, category tiles | T-A06 | no |
| T-A09 | Swipe and long-press row actions on bill, agent, side ledger and Account Ledger rows | T-A07 | no (reuses the existing edit and delete flows) |
| T-A10 | Portfolio insight cards with chart and scrub | T-A08 | yes, LR-21, LR-22 |
| T-A11 | Account Ledger daily date picker sheet | T-A05 | yes, LR-02 |
| T-A12 | Android system integration: edge-to-edge insets, `PopScope` and predictive back, keyboard insets, 48 dp targets, ripple theme | T-A03 | no |
| T-A13 | Widget tests: 19 stress values x widths x text scales (HIGHLIGHTS_AND_COLLAPSE.md B.6), contrast golden both themes | T-A06 | no |

## 5. Risks

- Blur is the main raster risk on mid-range Android: decided, it ships OFF (solid 94 percent surface). Profile on the reference device before enabling.
- Sticky day headers ship (decision); watch the cost on long lists in profile mode.
- Light mode text colours differ from Apple's system colours on purpose (AA). Designers comparing to a real iPhone will see slightly darker greens, oranges and blues in text.
- The brand accent is not decided: all accent usage must go through `RigColors`.

## 6. Decisions and open questions

Answered 2026-10-13 (earlier): AA text variants kept (A6); rupee sign everywhere (LR-24); Appearance setting approved with System by default (LR-23, A4); Portfolio ships metric cards first and insight cards later (LR-21, LR-22).

Decided 2026-10-13 (Android): card gap 12; sticky day headers ship with no flag; glass blur behind one toggle, default off, profile first; macOS dropped. Also decided: root-tab back leaves the app; predictive back enabled; reference device is a typical mid-range phone (Snapdragon 6 or 7 class) for profiling blur and dp checks.

The 22 numbered answers of 2026-10-13 are recorded in section 7. Remaining open items are in section 9.

## 7. Developer answers (2026-10-13), the binding decisions

These override anything older in the 62 spec documents, DESIGN_SYSTEM.md and the first MIGRATION_PLAN.md. Where a code check was asked for, the result is in section 8.

### Brand

| # | Answer | Consequence for the spec |
|---|---|---|
| 1 | Flat canvas, no gradient header. ONE accent token, default system blue as in the mockup. #315D9A stays as an alternate. Logo and brand colour are pending, so a change must be a ONE-token change | `headerGradient`, `appBarGradient` and the `AppColors` gradient entries are deleted, not migrated. The accent is `RigColors.accent` (five derived roles: `accent`, `accentText`, `accentButton`, `onAccent`, `accentTint`). The release app ships blue only; #315D9A is kept as a documented alternate value, not a user setting |
| 2 | Inter 400, 500, 600, 700 bundled with tabular figures. Noto Sans stays for PDFs only | Replaces the Noto Sans UI proposal in DESIGN_SYSTEM.md section 4. Four static Inter files (or one variable file if weights 400 to 700 are verified) under `assets/fonts/`, OFL notice kept. The Tamil fallback stays Noto Sans Tamil. PDF code keeps its own font loading and is not touched |
| 3 | Rupee sign everywhere, en-IN grouping, two decimals only when the value has paise, compact L and Cr ONLY in highlight tiles with the full value on tap (LR-24 approved) | `money()` per TOKENS.md section 7. Compact is allowed only inside `MoneyTile` and the Portfolio metric cards; list rows, bill cards, group headers and the Account Ledger strip never use compact (they scale down to 75 percent, then shrink to the 11 px guard, then move the value to its own line). The mockup `mf()` compacts in list cells: that differs from this answer, see section 8.4 |
| 4 | "Rig" everywhere in the UI. Tab label "Accounts" | Copy sweep: "Vehicle" becomes "Rig" in the switcher sheet ("Switch Rig"), Vehicle Management (title "Rigs"), Add Vehicle ("Add Rig"), snackbars, About, export labels that are UI only. Code identifiers (`Vehicle`, `vehicleId`) are not renamed. Tab labels on the floating bar: Ledger, Portfolio, Agents, Accounts, Settings |
| 5 | Portfolio range chips use the same order as the Ledger tab | Order: Month, 3 Mo, 6 Mo, Year, Custom, All. Today Portfolio has an extra Day chip: it stays only if the Ledger tab also gets it; otherwise it is removed. Decision needed (section 9, Q-O1) |

### Scope

| # | Answer | Consequence |
|---|---|---|
| 6 | Light, Dark, System, default System (LR-23 approved) | Settings row Appearance. Stored in the existing Hive settings box under one key, no schema bump (`schemaVersion` stays 5). The old "light only" rule in CONVENTIONS.md is replaced in the final docs task |
| 7 | Delete `side_ledger_screen.dart` and `home_screen.dart` only after a search and `flutter analyze` prove zero references, in their own last cleanup task | Cleanup task is the LAST task (T-Z99 in MIGRATION_PLAN.md), with the grep and analyze evidence in the commit body |
| 8 | Bit is purple. Diesel orange, PVC teal, Hammer pink | Category tokens `catDiesel`, `catPvc`, `catBit`, `catHammer` as in TOKENS.md. The four list screens (today Bit uses green, Hammer brown, PVC blue) switch to these |
| 9 | A discard-changes prompt only when a form has unsaved edits, also triggered by Android back (PopScope) | `UnsavedChangesGuard` (COMPONENTS.md): dirty flag computed from the form controllers versus their initial values; `PopScope(canPop: !dirty)` on every form route; the in-screen back/close control uses the same path. Approved as a behaviour change (LR-25) |
| 10 | Rename "Pending" to "Balance" on the Stats Ledger tab only. Side ledger "Pending" (owed to supplier) keeps its name | One label change in `stats_screen.dart` (Ledger tab). Side Ledger tab, side lists, Portfolio ("Pending" metric card label) are NOT renamed by this answer; Portfolio's card label is open (Q-O2) |

### Platform

| # | Answer | Consequence |
|---|---|---|
| 11 | Portrait phone only, keep the portrait lock. 360 dp is the smallest supported width | No tablet, landscape or expanded layouts. Width classes reduce to one (compact); the stress width list becomes 360, 412. The earlier 320 dp case is dropped (360 is the floor) |
| 12 | Build Portfolio, Agents and Settings lazily on first visit and keep them alive afterwards; verify with parity lines | `IndexedStack` children for these three are built on first selection and then retained (`AutomaticKeepAliveClientMixin` or a lazy-stack wrapper). Ledger and Accounts: see Q-O3. Parity lines in PARITY_CHECKLIST.md section Lazy tabs |

### Logic exceptions

| # | Answer | Consequence |
|---|---|---|
| 13 | Approved: one shared `switchRig` that awaits the switch, clears search and filter, and refreshes every provider holding per-rig data. Verify the provider list | LR-01 approved with the verified list in section 8.1 |
| 14 | Approved: `CashViewConfigNotifier.setAnchor(DateTime)` | LR-02 approved |
| 15 | Moot: macOS is out of scope. Do not edit or delete macOS code in this revamp. Mark it frozen and list its fate as a separate later decision | `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`, `window_manager` usage and every `PlatformHelper.isDesktop` branch are FROZEN: the revamp reads them but never edits or deletes them. The macOS fate (keep building, archive, or delete) is a separate later decision, recorded as D-08 in BUGS_FOUND.md and in section 9. Frozen means the revamp tasks must not break the macOS build either: shared code touched by the revamp must still compile there (verified by `flutter analyze` only, since the macOS app is not run) |
| 16 | Feet: up to one decimal with a trailing .0 hidden (350 or 350.5), same in the bill card and the summary. Check how depth values are entered and stored | LR-13 decided with a caveat, see section 8.2 |

### Bugs

| # | Answer | Consequence |
|---|---|---|
| 17 | Order: crash, wrong number, data loss fixed by UI guards, then UI only and cosmetic. The items touching data, sync or models need plan mode and an explicit yes per item, never batched. Approved now: CSV import zeroing depth, rates and extra charges; double-tap Save creating duplicate bills; calendar day totals mixing months | Phase 1 of MIGRATION_PLAN.md has exactly these three, one commit each (LR-31, LR-32, LR-33). The data-touching list is 18 entries, not 21 (the earlier summary said 21): see BUGS_FOUND.md section 4 |
| 18 | Yes to both: Clear All Data warns that Account Ledger books and notes are erased too; restore asks for the file first, then confirms | LR-28. Two UI flow changes in `settings_screen.dart`; no change to what the operations do |
| 19 | Yes: warn on a half-typed items row. An empty account name disables Save | LR-26 (items dialog) and LR-27 (Add Account Save disabled while the name is empty; PARITY-003 "silent close" is superseded) |
| 20 | Working assumption: count = pieces of that type, rate per piece, total = count x rate, Pending = total minus paid, no netting of advances. VERIFY against the code | Verified, with differences: section 8.3. LR-29 proposed for the no-netting summary rule |

### Performance

| # | Answer | Consequence |
|---|---|---|
| 21 | Targets, not gates, until a baseline is measured in profile mode: p90 build and raster under 8 ms each, p99 under 16 ms, janky frames under 2 percent on the longest list scroll, cold start under 2 s (goal 1.5 s), tab switch under 100 ms. Drop macOS budgets | PERFORMANCE.md rewritten accordingly (targets, no gate until Phase 0 baseline exists) |
| 22 | Reference device: `<MODEL, ANDROID VERSION, RAM>` | Placeholder not filled in. Provisional device chosen from `adb` (emulator, Android 16, about 2 GB RAM); see section 9 Q-O4 and T-B01 |

## 8. Verification results (answers 13, 16, 20) and mockup conflicts

### 8.1 Answer 13: providers that hold per-rig data

Checked in `lib/core/providers/*.dart` and `DatabaseService` (every list read filters on `currentVehicleId`):

| Provider | Per rig? | Evidence | In `switchRig` |
|---|---|---|---|
| `ledgerEntriesProvider` | yes | `getAllLedgerEntries()` filters `vehicleId == currentVehicleId` | `refresh()` |
| `agentsProvider` | yes | `getAllAgents()` filters `vehicleId` (agents belong to a rig) | `refresh()` |
| `dieselEntriesProvider`, `pvcEntriesProvider`, `bitEntriesProvider`, `hammerEntriesProvider` | yes | same pattern | `refresh()` each |
| `currentVehicleProvider` | holds the rig | `setCurrentVehicle` | awaited first |
| `vehiclesProvider` | no (all rigs) | list of all vehicles | `refresh()` is harmless and keeps parity with CONVENTIONS.md; not required |
| `cashBooksProvider`, `cashEntriesProvider`, `cashNotesProvider` | no (Account Ledger is global) | ARCHITECTURE.md, `cash_books` not vehicle scoped | none |
| Mini ledger | NO provider exists | `grep -n "mini" lib/core/providers` finds nothing; `MiniLedgerEntry` is only in `DatabaseService` and `SyncService` | none (nothing to refresh); answer 13's "include the mini ledger provider if it holds per-rig data" does not apply |
| Derived (`filteredLedgerEntriesProvider`, `monthlyStatsProvider`, `feetTotalsProvider`, `calendarDayTotalsProvider`, `phonePeNamesProvider`, `uniqueAddressesProvider`, `agentBillCountsProvider`, `agentCommissionTotalsProvider`, `portfolioSourceProvider`) | yes, derived | watch the notifiers above | recompute automatically |
| UI state to clear | yes | `searchQueryProvider`, `ledgerFilterProvider` (answer 13); also `dieselFilterProvider`, `pvcFilterProvider`, `bitFilterProvider`, `hammerFilterProvider` (they filter by values that belong to the previous rig) | clear all six; clearing the four side filters is an addition to the current mobile handler (which only clears the first two): flagged in LR-01 |

`switchRig` order: `await currentVehicleProvider.notifier.setCurrentVehicle(v)`, clear the six UI state providers, then `refresh()` on ledger, agents, diesel, pvc, bit, hammer (and vehicles). Period state (`timePeriodProvider`, month, year, custom dates, side ledger period) is NOT reset (today's behaviour).

### 8.2 Answer 16: feet, one decimal, trailing .0 hidden

Findings:
- Entry: depth, PVC and MS pipe feet are free decimal text fields. The input formatter is `RegExp(r'^\d*\.?\d*')` (any number of digits after the point), `keyboardType: numberWithOptions(decimal: true)`; parsing is `double.tryParse(text) ?? 0` (`ledger_form_screen.dart:706-750, 816-830`, side bore form same).
- Storage: `LedgerEntry.depthInFeet`, `pvcInFeet`, `msPipeInFeet` are `double`, stored unrounded.
- Edit form pre-fill is `entry.depthInFeet.toString()`, so editing shows `500.0` (the ".0" appears in the field today).
- Display today: bill card prints the raw double (`500.0ft`), summary uses `#,##0` (whole feet).

Fit: the rule "up to one decimal, trailing .0 hidden" fits integer and one-decimal values (350, 350.5). It does NOT fit a value typed with two or more decimals (350.25 would display 350.3, 350.249 would display 350.2). Rounding for display is safe for the calculations (they use the stored double), but a user could see a different number from what they typed. Options (decision Q-O5): (a) accept display rounding; (b) show up to 2 decimals with trailing zeros hidden (350, 350.5, 350.25); (c) restrict the input formatter to one decimal (LR-30, a validator change, proposed). Spec default until answered: (a) as instructed, plus the form pre-fill showing `350` instead of `350.0` (UI only, same stored value). Sums (summary tiles) apply the same rule to the total, which can carry floating noise (for example 0.1 + 0.2): the formatter rounds to one decimal before hiding `.0`.

### 8.3 Answer 20: count, rate, total, Pending

Checked in `pvc_entry.dart`, `type_detail.dart`, `pvc_form_screen.dart`, `diesel_form_screen.dart`, the list and summary screens:

| Assumption | Code | Verdict |
|---|---|---|
| count = pieces of that type | PVC, Bit, Hammer entries hold a LIST of types (`typeDetailsJson`); each type has its own `count` (int, whole pieces) and `rate`. The entry-level `count` is the SUM over types and is kept only for backward compatibility | differs: count is per type inside the entry; the entry-level number is a legacy sum |
| rate per piece | per type, inside `TypeDetail`; the entry-level `rate` is the FIRST type's rate (legacy, misleading when types differ) | differs: rate is per type; the entry-level field is not a meaningful rate |
| total = count x rate | `total = sum over types of count x rate` (`TypeDetail.total = count * rate`; form `_recalculate`) | differs only in being a sum over types; per type it matches |
| Diesel | `total = litres x rate` (`diesel_form_screen.dart:89-93`), not count | differs: litres, not pieces |
| Pending = total - paid | `_pending = _total - paid` (all forms); a stored `balance` field equals `paid - total` (the negative of pending, a duplicate field) | matches; note the duplicate `balance` field |
| no netting of advances | per-entry `pending` is signed (negative when overpaid). Every summary adds the signed values (`totalPending += entry.pending`: `combined_home_screen.dart:550-577`, `pvc_list_screen.dart:141`, the other lists, `stats_screen.dart:714-772`). So advances DO reduce the shown total due | differs: the summaries net advances. Matching the assumption needs a calculation change (sum only positive pending, show advances separately): LR-29, proposed |
| `isPaid` | `entry.pending <= 0` (PVC card, line 371) | an overpaid entry counts as paid |

### 8.4 Mockup versus Flutter code, conflicts found

| # | Mockup | Flutter code or decision | Resolution |
|---|---|---|---|
| C-1 | `mf()` list cells compact to L and Cr | answer 3: compact only in highlight tiles | follow answer 3; update the mockup `mf` when convenient (not blocking) |
| C-2 | Screen names "Switch Vehicle sheet", "Vehicle Management", "Add Vehicle dialog" | answer 4: "Rig" everywhere | UI copy changes to Rig; screen registry names stay as labels only |
| C-3 | Ledger error, Ledger loading, Accounts loading, Portfolio loading states | Hive reads are synchronous in providers; there is no failure or loading path in the ledger lists | build the skeleton only for the first frame after a rig switch or restore, and the error state only for sync, import and export; no new provider states. If an error state for list loading is wanted it needs logic (LR-34 proposed) |
| C-4 | Root-tab back does nothing | Android default leaves the app | follow the brief: root `PopScope(canPop: false)`. Flag as Q-O6 because it differs from Android convention |
| C-5 | Day group sticky headers, per group | `SliverPersistentHeader(pinned)` per group costs layout per group | ships per decision; measure in Phase 0/5 against the p99 target; fallback `sliver_tools` `SliverStickyHeader` |
| C-6 | Swipe actions (Edit, Delete) on bill, agent, side and Account Ledger rows | existing flows reuse (edit form, delete confirm) | no logic; needs `flutter_slidable` or `Dismissible`; adding a dependency needs a yes (Q-O7) |
| C-7 | Insight cards, scrub chart (`pfSeries`) | no per-day series in the app | LR-21, LR-22 stay proposed; metric cards ship first |
| C-8 | Calendar day tap lists that day's bills (J "Calendar view with selected day") | no tap behaviour today | LR-03, status now proposed-with-mockup; not in the first pass |
| C-9 | Gradient category tiles on Side Ledger home | none | `LinearGradient` per category; no logic |
| C-10 | Appearance row, Drive hero card | Drive card reads existing sync providers | no logic besides LR-23 |
| C-11 | Light, dark with true black canvas | `ThemeMode.system`; AMOLED black is intended | no logic |
| C-12 | `field-sizing` rupee sign beside amount | Chrome-only CSS | `Row` + `IntrinsicWidth` (MOCKUP_NOTES.md) |
| C-13 | Floating tab bar hides when keyboard opens | Flutter: `bottomNavigationBar` hides with `resizeToAvoidBottomInset` only if built that way | build the floating bar as an overlay that hides on `viewInsets.bottom > 0` |
| C-14 | Account Ledger shows `d MMM yyyy` default | existing Account Ledger Format Date setting stored per user | LR-24: default changes; stored user choice kept unless the owner wants a one-time migration (Q-O8) |
| C-15 | Mockup money shows two decimals only with paise | PDFs and CSV unchanged | export content frozen; screens differ from export text on purpose |

### 8.5 Conflicts found while reconciling the screen documents (mockup versus code or decisions)

Full lists as written by the four passes. Each line says what the mockup shows, what the code or the binding answers say and the suggested resolution. Where the mockup contradicts an approved answer, the answer wins and the mockup should be corrected later (the mockup is not edited in this pass).

#### Ledger, forms, Portfolio, shell (r1)


Format: id, mockup says X, code (or earlier spec) says Y, suggested resolution.

- C1 Mockup: Ledger and Side Ledger are a segmented control and rows have horizontal swipe actions. Code: `TabBarView` also swipes horizontally between the two tabs. Resolution: set `NeverScrollableScrollPhysics` on the `TabBarView`, switch only through the segmented control; otherwise swipe on a row fights the tab swipe.
- C2 Mockup bill row shows depth only (`ftq(d)` plus type). Code card shows Depth and PVC chips (main bore). Resolution: keep PVC feet on line 2 when above zero for main bore; ask the owner if the omission was intentional.
- C3 Mockup bill row has no manual-total marker. Code shows `Icons.edit` when `isTotalManuallyEdited`. Resolution: keep it as a labelled marker "Total edited" (data signal must not disappear).
- C4 Mockup shows "Settled" when balance is 0 or below. Code colours a credit like paid. Resolution: "Settled" at 0, "Overpaid" pill when below 0 (copy only, matches the side bore balance caption).
- C5 Mockup Portfolio chips are Day, Month, 3 Mo, 6 Mo, Year, All, Custom. Answer 5: same order as the Ledger tab (Month, 3 Mo, 6 Mo, Year, Custom, All), Day open (Q-O1). Resolution: follow the answer, Day removed unless the Ledger tab gets it.
- C6 Mockup Daily bar label is "12 Oct 2026 to 12 Oct 2026" (`cbLabel` repeats the date). Earlier spec and common sense: one date. Resolution: build "Today, 12 Oct 2026" style label in the widget; the mockup should be fixed.
- C7 Mockup date picker: `.cd.sel .n` overrides `.cd.td .n`, so today selected loses its today marker and a selected day is only a grey `fill2` circle. Resolution: today keeps the `accentButton` fill; selected adds a 2 dp `fill2` ring when it is also today; otherwise `fill2` fill.
- C8 Mockup live Total and Balance card is the first row of the scroll body (not sticky). Earlier spec required Total and Balance always visible above the keyboard. Resolution: follow the mockup; the pill is the pinned control. Open question for the developer: add a sticky mini strip like the Ledger status strip when the live card scrolls off (UI only).
- C9 Mockup form Date row is static text. Code opens a themed date picker (main 2000 to 2100, side bore 2020 to now + 365). Resolution: keep the picker; clamp `initialDate` in the shared helper; wide range stays.
- C10 Mockup payment rows have only a delete button, no tap to edit, no Undo. Code rows tap to edit; earlier spec adds an Undo snackbar. Resolution: keep tap to edit, keep local Undo.
- C11 Mockup shows the snackbar "Enter an amount" for an invalid payment. Code and parity P-PL-03: inline 'Enter an amount' under Amount. Resolution: inline under the row, no snackbar.
- C12 Mockup forms show a close X and a sheet look but are pushed screens (`fscr`); code uses `MaterialPageRoute` with back arrow. Resolution: keep push navigation and its outcomes, render the sheet look, use a fullscreen-dialog route transition.
- C13 Mockup has no discard prompt drawn anywhere (`grep Discard` finds nothing). LR-25 approved. Resolution: defined in ledger_form_screen.md R2 ("Discard changes?", "Keep Editing", "Discard"); the mockup needs the alert added.
- C14 Mockup Search sheet has Clear and Search buttons. Code writes `searchQueryProvider` on every keystroke and closes on submit. Resolution: keep live write; Search closes the sheet.
- C15 Mockup `mf()` compacts totals in the bill row and the day header (`fitAll` falls back to compact). Answer 3 and C-1: lists never compact. Resolution: row, header and strip scale to 75 percent, then 11 sp, then wrap to their own line.
- C16 Mockup `qty` and `qfit` show up to 2 decimals for feet and compact them (`L`, `Cr`). Answer 16: one decimal, `.0` hidden. Resolution: `ftq` one decimal; compact only inside DepthTile.
- C17 Mockup rig sheet from the Portfolio sets `S.lt=0` (resets the Ledger sub-tab) after switching. `switchRig` does not touch `homeTabIndexProvider`. Resolution: no reset.
- C18 Mockup strip shows only "Filters on"; search is a separate pill row in the body. Earlier spec: search indicator in the strip. Resolution: add a "Search on" badge in the strip (UI only).
- C19 Mockup Portfolio Ledger tab metric card is "Pending". Answer 10: Stats Ledger tab renames Pending to Balance. Resolution: label "Balance" on that tab only; the Overview card stays "Pending" until Q-O2.
- C20 Mockup duplicate bill note is the sentence "This bill number already exists. Please use a unique bill number." Code validator: 'Bill number already exists' (logic string, must stay). Resolution: footer note while typing is UI copy, Save shows the validator text.
- C21 Mockup `rigPill` is always a tappable pill. Earlier rule (desktop title bar, `vehicles.length > 1`): plain text with one rig. Resolution: keep the rule.
- C22 Mockup Rig sheet title "Switch Rig" and footnote "The rig you choose applies to Ledger, Portfolio and Agents." Code sheet: "Switch Vehicle", "Select a vehicle to view its ledger" (combined_home_screen.dart lines 1108 and 1116). Resolution: copy change to the mockup text (answer 4); the footnote is correct because Account Ledger is global.
- C23 Mockup has no FAB; Add is a button in the large title row on both Ledger sub-tabs. Code: FAB on the Ledger tab only (`main_navigation.dart`) and parity P-NAV-3. Resolution: Add button in the title row, same routing; update P-NAV-3.
- C24 Mockup form sheet shows the payment sheet as content-height with a native-style select. Earlier spec: full-height sheet at compact. Resolution: content-height RigSheet with a pill and a list sheet for "Received by".
- C25 Shared screens (CombinedHomeScreen, StatsScreen, forms) are instantiated by the FROZEN `desktop_shell.dart`, which also imports `homeTabIndexProvider` from `main_navigation.dart`. Restyling them restyles macOS inside the old shell; moving the provider breaks the shell. Resolution: keep constructors and `homeTabIndexProvider` where they are, verify with `flutter analyze` only, accept unreviewed macOS visuals.
- C26 Mockup Account Ledger empty day shows only "No transactions / Nothing matches this period or filter." and carries the previous balance in the totals strip. Earlier spec: "No transactions on this day" plus a Previous Balance row. Resolution: mockup text, previous balance in the strip (same number).

#### Side ledger and stats (r2)


One line each: mockup says X, code or decision says Y, suggested resolution.

- C-r2-1 Form live card: the mockup puts the Total and Pending card (`.live`) at the top of the scroll body, so it scrolls away while editing lower rows (up to 5 type groups on Bit); old specs and P-DF-10 want totals visible while typing. Resolution: ship as the mockup; ask the lead whether the live card should be a pinned sliver (one `SliverPersistentHeader`, no blur) before T-U57.
- C-r2-2 Bit ID and Hammer name: the mockup places the row before the type chips; code and P-BF-01 and P-HF-01 place it after the chips. Resolution: follow the mockup (parity delta recorded in R5 of both forms); alternative is to keep the code order.
- C-r2-3 PVC Paid date: the mockup shows "Paid date" on the PVC form; the PVC form has no such field although the model does. Resolution: omit until L2-r2-1 is approved.
- C-r2-4 Range chip order: the mockup `PRR` is Day, Month, 3 Mo, 6 Mo, Year, All, Custom; answer 5 says Month, 3 Mo, 6 Mo, Year, Custom, All and Day is open (Q-O1). Resolution: follow answer 5; the mockup registry should be updated by the lead.
- C-r2-5 Ledger tab label: the mockup metric card says "Pending" on the Portfolio Ledger tab; answer 10 and the brief say "Balance" on that tab only. Resolution: "Balance"; update the mockup `mcard('Pending'...)` in the `P.tab==1` branch.
- C-r2-6 By agent share: the mockup prints whole numbers in a 44 px column; code prints one decimal (`toStringAsFixed(1)`) and "100.0%" does not fit 44. Resolution: keep one decimal, min width 56 dp, no fixed width.
- C-r2-7 Side Ledger details: the mockup groups omit the per type pieces rows that the code shows (P-stats 54). Resolution: keep the rows (indented); see L2-r2-2 for the wrong tally.
- C-r2-8 Delete copy: the mockup prints `delete pvc entry #<bill>` (lower case `k`); code prints `PVC entry`, `diesel entry`, `bit entry`, `hammer entry`. Resolution: code copy wins (parity P-PL2-04).
- C-r2-9 Compact in list cells: the mockup rows use `mf()` (compact); answer 3 allows compact only in highlight tiles. Resolution: rows use the full money with the fit pipeline (already C-1).
- C-r2-10 "Settled": the mockup shows a "Settled" pill when `pend <= 0`; code shows no status when nothing is due and treats overpaid as paid. Resolution: add "Settled" as display copy only; an overpaid entry also shows "Settled".
- C-r2-11 Active filter indication: the mockup list shows none; code has a dot and users cannot tell which filter is active. Resolution: keep the dot and add the removable chip row (UI only).
- C-r2-12 Entries count: the mockup shows "N entries" on all four summary cards; the old PVC, Bit and Hammer docs said not to add it. Resolution: show it (length of the shown list, no new calculation).
- C-r2-13 Icons: the old Bit doc suggested `hardware_rounded` for Bit and `gavel_rounded` for Hammer; the mockup registry uses `circle` for Bit and `hardware` for Hammer. Resolution: mockup glyphs.
- C-r2-14 Agent donut colours: `AGC` reuses `catPvc` and `catHammer` for agents five and six, so a pink slice means an agent here but Hammer elsewhere. Resolution: accept for the first pass (the Ledger tab has no category context) or add two neutral series tokens; lead decides.
- C-r2-15 Donut components: the mockup uses SVG ring math; the brief component list has RigRing but no donut. Resolution: RigRing with segments (CustomPainter) or fl_chart with touch disabled; the lead names it.
- C-r2-16 Negative Due slice: the mockup `donut([{v:pa},{v:pe}])` and the code can receive a negative `pe` (advances netted, LR-29). Resolution: draw with `max(0, v)`, keep printed percent as baseline.
- C-r2-17 Form validation: the mockup `slSave` reports a missing bill number only by snackbar; code uses an inline validator. Resolution: inline error under the row plus the same snackbar text.
- C-r2-18 Swipe actions: the mockup uses swipe buttons (76 px) on rows; needs `flutter_slidable` or `Dismissible` (Q-O7 open). Resolution: long press menu and TalkBack custom actions regardless.
- C-r2-19 Form header: the mockup form uses a close (x) button and an inline title (sheet like full screen), while the lists use a back chevron. Resolution: follow the mockup per screen; both go through the same dirty guard.
- C-r2-20 Hint copy: the mockup Bit ID hint "Unique identifier" promises uniqueness the code does not check. Resolution: hint "Optional. Use an identifier you can recognize".

#### Account Ledger (r3)


Mockup versus Flutter code conflicts found in group r3 (Account Ledger). One line each: mockup says X, code says Y, suggested resolution.

| Id | Conflict | Suggested resolution |
|---|---|---|
| C-01 | Mockup shows the hub (`cbDrawer`) as a full-height RigSheet titled "Account Ledger" with a close button; code (`cashbook_hub_screen.dart`) uses a left `Drawer` opened by the menu button. | Keep the Flutter `Drawer` (no navigation change), restyle its content as in the mockup; ask the developer whether a full-height sheet is wanted instead (question Q-r3-1). |
| C-02 | Mockup Accounts root has the large title "Accounts", a book pill under it, the totals strip above the list and inline (scrolling) Income and Expense buttons; code has the book selector as the title, and a pinned bottom block with the buttons and the totals strip (home:395-435). | Mockup wins (the floating RigTabBar owns the bottom edge); remove the pinned bottom block; keep all provider reads. |
| C-03 | Mockup `mf` and `mfit` allow compact L and Cr in list cells, account balance cells and the Account Ledger strip; binding answer 3 and DESIGN_DIRECTION_APPLE.md 8.4 say lists, rows and the Account Ledger strip never compact. | Binding answer wins: MoneyText without compact on every Account Ledger screen; the mockup helper should be corrected by the lead. |
| C-04 | Mockup home shows the previous balance twice (the strip group "Previous balance" and "Balance with previous", and a first list row "Previous balance"); code `CashbookTotalsStrip` shows the two lines in the bottom block and the list has the `prev` marker row. | Keep both as the mockup draws them (both exist in code today); confirm with the developer if one should go. |
| C-05 | Mockup calculator key order is C, DEL, 000, / then 7 8 9 *, 4 5 6 -, 1 2 3 +, 0 00 . = ; code keypad (calculator sheet lines 119-123) is 7 8 9 /, 4 5 6 *, 1 2 3 -, . 0 00 +, C DEL 000 =. | Layout only; adopt the mockup order and round keys (62 dp, radius 31, gap 10). No evaluator change. |
| C-06 | Mockup Summary puts the grand total ("All accounts" strip) at the end of the scroll; the old design and code (summary:... pinned grand strip) show it pinned at the bottom. | Mockup wins; values identical. |
| C-07 | Mockup shows a snackbar ("Enter item, quantity and rate", "Saved") while a sheet is open; a Flutter SnackBar renders behind a modal route. | Host a RigSnack in the sheet own Scaffold or use an inline ErrorBanner row for validation inside sheets. |
| C-08 | Mockup second delete alert title "Are You Sure?"; code uses "Are You Sure ?" (PARITY-009 text). | Keep the code text if a test pins it; otherwise use the mockup text. Grep tests before changing. |
| C-09 | Mockup entry form order is type, amount card, date and time, notes, account, bills, items; code order is type, date, time, amount, notes (entry form lines 387-470). | Adopt the mockup order (visual reorder, no logic); autofocus the amount stays. |
| C-10 | Mockup screen title is "All Transactions"; hub label (mockup and code) and the code title are "Transaction-All Accounts". | Keep "Transaction-All Accounts" for the title (PARITY-077 wording) unless the developer prefers the short title. |
| C-11 | Mockup calendar cell shows one net value (income minus expense); code and PARITY-064 show income and expense per day. | Open question Q-r3-2. Default: keep both values in the cell at normal text scale, net is a display-only option. |
| C-12 | Mockup Notebook stats colour Pending in `moneyOutText` (red); the old doc and the TOKENS roles use the orange outstanding role for pending. | Question for the developer; default to the mockup (red) because the lead approved it visually. |
| C-13 | Mockup notebook swipe Delete shows the snackbar "Note deleted" with no confirm; code and PARITY-066 ask "Delete this note?" before deleting. | Keep the confirm (data loss guard); UI-only entry point. |
| C-14 | Mockup entry form (`fscr`) is a full-screen sheet with grabber and a close X; code pushes a `MaterialPageRoute` page with an AppBar back arrow. | Keep the route and PopScope; style the page as the mockup (close X, grabber optional). No navigation change. |
| C-15 | Mockup Format Date samples are 12 Oct 2026, Oct 12, 2026, 12-10-2026, 12-10-26, 10-12-2026, 2026-10-12; code `CashSettings.dateFormats` is MMM-dd-yyyy, dd-MMM-yyyy, dd-MM-yyyy, dd-MM-yy, MM-dd-yyyy, yyyy-MMM-dd (default MMM-dd-yyyy). | Samples are illustrative (MOCKUP_NOTES). Proposed L2-r3-2 adds `d MMM yyyy` as the default and keeps the six old patterns. |
| C-16 | Mockup settings shows "Currency Format: Grouped (1,234)"; LR-24 and TOKENS.md section 7 make the rupee sign and en-IN grouping universal, while code keeps group digits and fixed decimals as settings and `formatMoney` prints "Rs.". | Proposed L2-r3-1. |
| C-17 | Mockup toggles Time Format with one tap and the More button on the entry form toggles Description / Category directly; code opens a choice dialog for Time Format and a one-item popup for the description. | Keep the code interaction (choice sheet, one-item menu); visual only. |
| C-18 | Mockup Add Items sheet does not draw the half-typed warning (LR-26) and the entry form does not draw the discard alert (LR-25). | Specified in the reconciliation sections from the LR texts; the lead may add alert screens to the mockup. |
| C-19 | Mockup Account Ledger screens have no Today button on the Calendar and no swap button on Transfer; the old design had both. | Dropped; both are UI only and can return on request. |
| C-20 | Mockup search placeholder is "Search notes and accounts"; code placeholder is "Search". | Use the mockup copy. |
| C-21 | Controller audit result: every TextEditingController and FocusNode in lib/features/cashbook is created in a State and disposed in dispose; no dialog creates one outside State or disposes it after await showDialog. | No violation; keep controllers in sheet State when dialogs become sheets. |

#### Agents, settings, exports, theme (r4)


1. Agent delete: mockup `agentDel` preselects "Delete all entries" (`F.adm=F.adm||'del'`) and enables the red pill; code starts with reassignToAgentId null (delete-all effectively default) and bug G3-B15 says no default. Resolution: no default, pill disabled until a choice; update the mockup.
2. Clear All Data: mockup text lists entries, agents, side-ledger entries and rigs but not the Account Ledger; LR-28 requires naming Account Ledger books, transactions and notes. Resolution: add to the mockup text and the Flutter alert.
3. Restore Backup: mockup shows the alert directly; LR-28 requires the file picker first, the alert after. Resolution: the alert appears after a file is chosen and should name the file (mockup only draws the alert).
4. Settings section order: mockup is Drive hero, Appearance and Rigs, Backup and restore, Export and import, About, Data; code and parity line 13 are Vehicle, Export and Import, Backup and Restore, Google Drive, Data, About. Resolution: follow the mockup; parity line 13 changes on purpose.
5. Rigs screen: mockup tap on a rig switches and stays on the screen; `_switchVehicle` pops back to Settings (parity 28). Resolution: keep the pop (navigation outcome frozen); mockup should close the screen.
6. Switch handlers: LR-01 omits the fourth copy in vehicle_management_screen.dart (see L2-r4-1).
7. About: mockup says "Available for Android."; about_screen.dart:69 says "Available for Android and macOS." Resolution: developer decides the string (macOS is frozen, not removed).
8. Export to CSV: mockup column list (17 names such as "Extra-chargers") differs from `LedgerEntry.csvHeaders` (21, including Notes and Commission). Resolution: render the real headers; the mockup text is illustrative.
9. Export to CSV: mockup keeps the switch "Export all entries" with subtitle "Export the entire dataset"; the earlier spec proposed a segmented control and said "entire dataset" is inaccurate (active rig only, UNVERIFIED for the Ledger). Resolution: keep the switch; subtitle wording is the developer's call after the scope is verified.
10. Export to PDF: mockup shows two Preview controls (header and bottom bar), the earlier spec removes the duplicate. Resolution: keep the bottom one only. Mockup also shows no preset chips, no group labels, no rig context row and no "N of M" count: all dropped or optional.
11. Export to PDF: the mockup lists 20 column chips, which matches `PdfColumn` (20); the earlier doc said 18. Resolution: use 20; the old text is stale.
12. Import from CSV: mockup draws static mapping text, Flutter keeps a dropdown per field; mockup step indicator is a read-only segmented control, the earlier spec proposed circles. Resolution: RigFormRow with the existing dropdown, RigSegmented read-only.
13. Import from CSV: earlier spec section 5 says the auto-mapping bug stays; LR-31 (approved) fixes it in Phase 1. Resolution: LR-31 wins.
14. Lazy tabs: `main_navigation.dart:33` builds all five screens at launch; answer 12 requires first-visit builds. Resolution: lazy wrapper in the shell task; Agents and Settings have no screen-level state except the Drive card flags and scroll positions, which keep-alive preserves.
15. Settings Drive error: mockup shows an error card with Retry; code has no such UI, but `SyncState` already exposes `status` and `errorMessage` (sync_provider.dart:21-24). Resolution: read them (no logic); show a fixed plain message, not the developer text of `GoogleDriveService.signIn`.
16. Agents: mockup shows swipe Edit and Delete only; no long press menu exists for agents (it exists for rigs and bills). Resolution: same RowActions sheet for the non-gesture path; swipe needs `flutter_slidable` or `Dismissible` (Q-O7).
17. Agents list: mockup `mf()` compacts commission (list cell) while answer 3 forbids compact in rows. Resolution: full value with the fit pipeline, no L or Cr (already C-1).
18. Agents loading and error: mockup draws both for the tab; code has no failure or loading path (C-3, LR-34). Resolution: not built.
19. main.dart: earlier spec says keep `immersiveSticky`; the mockup shows visible transparent system bars (edge to edge). Resolution: `SystemUiMode.edgeToEdge`.
20. Deleting AppColors breaks macOS: `desktop_shell.dart` uses `AppColors` 21 times (see L2-r4-4).
21. Vehicle strings: validator "Please enter a vehicle name" and snackbars say Vehicle; answer 4 says Rig in UI copy. Resolution: copy change only, identifiers unchanged.
22. Drive hero copy "Automatic backup every 6 hours" reads as always on; Auto Backup is a toggle, default off (parity 19). Resolution: say "Optional automatic backup every 6 hours".


## 9. Open questions, answered by Claude on 2026-10-13 (delegated by the developer)

The developer asked Claude to answer every open question without waiting. These are DELEGATED DEFAULTS, chosen to be the smallest, safest reading of the approved answers: they change no data, sync or model behaviour, add no dependency and approve no new logic change. The developer can overrule any row; the consequence column says what to edit. Items that would need a logic change stay PROPOSED, not approved.

| ID | Question | Answer | Consequence |
|---|---|---|---|
| Q-O1 | Portfolio has a Day chip the Ledger tab lacks | Keep Day on Portfolio only, as the first chip, then the shared order Month, 3 Mo, 6 Mo, Year, Custom, All. No capability is removed and the Ledger tab gets no new period (that would be a logic change) | T-S20 uses `RigChipRow` with the shared order plus a leading Day chip on Portfolio |
| Q-O2 | Portfolio metric card "Pending" | Keep "Pending" on Portfolio. Answer 10 limits the rename to the Stats Ledger tab | no change to T-S20 labels; revisit only if the developer wants one word everywhere |
| Q-O3 | Should Accounts also be lazy | No. Ledger and Accounts are built at launch, Portfolio, Agents and Settings lazily (as in answer 12) | T-P01 as written |
| Q-O4 | Reference device | Provisional: the attached Android emulator, `sdk_gphone64_arm64` (Google), Android 16 (API 36), about 2 GB RAM, arm64, 1080 x 2400 at 420 dpi (411 x 914 dp). Read from `adb` on 2026-10-13. An emulator is not representative for raster time, so every number measured on it is marked PROVISIONAL; a physical mid-range Android phone must be named and the baseline repeated on it before any number is trusted | T-B00 is no longer blocked: it runs on the emulator and records "provisional"; a second run on a physical device is added as T-B01 |
| Q-O5 | Feet with two or more decimals | Option (a): display rounded to one decimal with trailing .0 hidden, exactly as answered. LR-30 (limit input to one decimal) stays PROPOSED, not approved | T-F05 default rule as written; no input formatter change |
| Q-O6 | Back on a root tab | Do nothing, as the mockup and the brief say (root `PopScope(canPop: false)`) | T-S01 as written |
| Q-O7 | Swipe actions | No new dependency. Rows get a long-press menu (Edit, Delete) and an explicit trailing "more" button for discoverability; Delete still goes through the existing confirm alert. Swipe-to-act is NOT built: it fights the tab swipe, risks accidental deletes and needs `flutter_slidable` | `RowActions` in T-F13 is long-press plus "more" only; the mockup's swipe is a deliberate deviation (add to the conflicts list) |
| Q-O8 | Account Ledger Format Date | Keep every stored user choice; change only the default for new installs and for users who never chose one (`d MMM yyyy`) | LR-24 / L2-r3-2 as written; no migration |
| Q-O9 | macOS fate | Stay frozen through the whole revamp. One decision point: T-P05 (project docs) asks the developer whether to keep building, archive on a branch, or delete. Claude's recommendation: archive on a branch and remove it from main, because the app is Android only. Nothing is deleted without a yes | D-08 in BUGS_FOUND.md keeps the entry |
| Q-O10 | Account Ledger hub | Keep the left drawer of the code | T-S34 as written; the mockup's sheet is a deviation |
| Q-O11 | Account Ledger calendar cell | Keep the code: income and expense shown separately, not a net value | T-S33 |
| Q-O12 | Sticky Total and Balance strip on forms | Yes, a compact strip appears when the live total card scrolls off (UI only) | already in T-S10 acceptance |
| Q-O13 | Agent donut slice colours | Do not reuse the category colours; use the chart series colours | T-S21 |
| Q-O14 | Notebook pending count colour | Orange (`outstandingText`), as in the code | T-S34 |
| Q-O15 | About text "Available for Android and macOS" | Change to Android only (the product is Android only) | T-S42 copy |
| Q-O16 | StartupGate and edge-to-edge | Edge-to-edge: yes (T-F03). StartupGate (splash and error screen that move initialisation into a widget): NO, it moves where initialisation runs, which is a startup behaviour change; keep `main()` order as it is | T-F03 only; r4's StartupGate item is dropped |
| Q-O17 | PVC Paid date row | Omit (L2-r2-1 stays proposed) | no change |
| Q-O18 | Per-type pieces tally in Portfolio Side Ledger details | Keep the current numbers during the revamp; L2-r2-2 stays PROPOSED as a wrong-number fix that needs the developer's yes | T-X02 does not include it |

Deliberate deviations from the mockup created by these answers: swipe actions are not built (Q-O7), the Account Ledger hub stays a drawer (Q-O10), the calendar cell keeps income and expense separate (Q-O11), Day stays only on Portfolio (Q-O1).

Also decided with the same delegation (small items raised by the screen docs): LR-29 (side ledger Pending netting) stays PROPOSED and the summaries keep netting during the revamp; LR-03 (calendar day tap) stays PROPOSED and out of the first pass; LR-21 and LR-22 stay PROPOSED (metric cards first); the 90 conflict lines of section 8.5 resolve to the suggested resolution written in each line unless it contradicts an approved answer, in which case the answer wins.

Answered from the code while reconciling: `DatabaseService.getAllLedgerEntries()` is scoped to the CURRENT rig only (filters on `currentVehicleId`), so CSV and PDF export subtitles that say "current rig" are correct.
