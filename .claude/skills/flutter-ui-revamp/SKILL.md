---
name: flutter-ui-revamp
description: Audit every screen of a Flutter app (Android and macOS) and write a complete UI and UX revamp specification (design system, per-screen redesign, shared components, performance plan, parity checklist, task breakdown) with zero logic changes. Use when the user asks for a redesign, UI or UX revamp, new look and feel, design system, or polish of a Flutter app. Produces markdown documents only, never code.
---

# Flutter UI and UX Revamp (spec only, no logic changes)

## Hard rules
- Documentation pass only. Do not modify lib/, pubspec.yaml, or any existing
  file. Write only under docs/design/.
- Logic freeze. Never change: models, DatabaseService, SyncService,
  providers, calculations, validators, field meanings, navigation outcomes,
  export content. A design may change layout, widgets, theme, copy, spacing,
  motion, and how screens are split into widgets. If a UX improvement needs
  a logic change (undo, new field, new filter), do NOT include it in the
  redesign. List it in docs/design/LOGIC_REQUESTS.md instead.
- Style: English only. No emojis and no em-dashes in any file. Icons:
  Material Symbols (rounded variants of the built-in Icons class). No emoji
  glyphs. No new icon package unless you prove the built-in set cannot cover
  the need.
- Brand: the app name RigLedger does not change. The logo and brand colors
  are pending. Define ALL color through semantic tokens so changing one seed
  color updates the whole app. Use the current primary (#315D9A) as a
  PROVISIONAL seed and label it so.
- Real data: screenshots contain financial data. Keep them in ~/design-ref,
  outside the repo. Never put real amounts or names in docs/.
- Token discipline: read big files by section (grep -n first). Never read
  *.g.dart, build/, .dart_tool/, secrets. Prefer text over images; downscale
  screenshots (sips -Z 900) before viewing.
- Checkpoint: update docs/design/PROGRESS.md after EVERY screen or topic
  (status DONE, PARTIAL, TODO, and the exact next step). A new session must
  be able to resume from PROGRESS.md alone.
- If the user names a phase, run only that phase.

## Phase 0: Inventory
- Read CLAUDE.md, MEMORY.md, .claude/context/ARCHITECTURE.md and
  CONVENTIONS.md, and the dependency list in pubspec.yaml.
- Find every screen and overlay: grep Navigator.push, showDialog,
  showModalBottomSheet, showDatePicker, PopupMenuButton, SnackBar,
  AlertDialog, DropdownButton, TabBar.
- Write PROGRESS.md with a table: screen, file, line count, mobile or
  desktop variant, status.

## Phase 1: Visual baseline (recommended)
- Run the app on the Android emulator and on macOS with test or demo data.
  Capture one screenshot per distinct screen and state into ~/design-ref.
  Android: adb exec-out screencap -p. macOS: screencapture.
- Record screen size classes you tested (compact phone, wide window).

## Phase 2: Per-screen audit and redesign
For each screen write docs/design/screens/<screen_name>.md with:
1. Purpose and primary user task.
2. Current structure: widget tree summary and state sources (providers used).
3. Problems found: visual hierarchy, density, tap target size (48dp min),
   contrast (WCAG AA), inconsistent spacing or components, missing empty,
   loading and error states, feedback after actions, form friction
   (keyboard type, field order, validation timing), destructive action
   safety, number alignment.
4. Redesign: layout for compact, medium and expanded widths, desktop
   specifics (sidebar, hover, focus, keyboard shortcuts, context menu),
   exact tokens used (spacing, radius, type style, color role), component
   list, state table (default, loading, empty, error, disabled), motion.
5. Logic touchpoints that must stay untouched: provider calls, validators,
   calculations, widget Keys, callbacks, with file and symbol names.
6. Acceptance criteria written as testable lines.
7. Performance notes: rebuild scope, list strategy, what to extract into
   const or small widgets.

## Phase 3: System documents (docs/design/)
- DESIGN_SYSTEM.md: design direction (calm, trustworthy, data-first,
  professional finance tool), color roles (primary, surface levels,
  money-in, outstanding or negative, warning, info) with light and dark
  proposals and contrast ratios, typography scale (one bundled family,
  tabular figures for all amounts, no runtime font download), 4pt spacing
  scale, radii, tonal elevation, motion (150 to 300 ms, curves, honor
  reduced motion), iconography rules and sizes, INR formatting and alignment
  rules, form patterns, list row anatomy, chart style for fl_chart, empty
  and error states, dialog versus bottom sheet rules, navigation (Material 3
  NavigationBar on mobile, sidebar on macOS), desktop density and window
  behavior, accessibility (text scale to 200 percent, semantics labels).
- COMPONENTS.md: catalogue of shared widgets to build, with name, props,
  states and which screens use them. Note duplicates found in the audit.
- UX_FLOWS.md: top journeys (add entry, check balances, side ledger entry,
  export, sync, switch rig) before and after, with step counts and shortcuts.
- PERFORMANCE.md: concrete rules and a per-screen budget. Cover const
  constructors, ListView.builder or slivers, ref.watch with select, caching
  NumberFormat and DateFormat instances, no heavy work in build, avoiding
  Opacity, saveLayer-heavy clips and BackdropFilter, RepaintBoundary only
  where measured, splitting 1000 line screens into small widgets, the cost
  of IndexedStack keeping all tabs alive (flag as a decision, because it
  affects state retention), controller disposal, image and asset sizing.
  Include how to measure: flutter run --profile, DevTools timeline, frame
  build and raster targets, cold start, scroll jank on the longest list.
- PARITY_CHECKLIST.md: per screen, every behavior that must be identical
  after the redesign (fields, validations, calculations, flows, export
  content), as numbered manual test lines.
- LOGIC_REQUESTS.md: improvements that would need a logic change, kept out
  of scope, each with why it matters.
- MIGRATION_PLAN.md: ordered tasks in the CURRENT.md format (T-id, Goal,
  Files, Depends, Resume notes, Commit), each small enough for one commit.
  Suggested order: theme tokens, shared components, navigation shells,
  screens by traffic, desktop polish, motion, dark mode (only if approved),
  cleanup. Each task lists its verification: flutter analyze, parity lines,
  screenshot comparison, profile-mode check.

## Phase 4: Questions
End with numbered questions (Brand, Scope, Platform, Performance targets,
Dark mode, Export documents) for things the code cannot answer. Then stop
and wait.

## Quality bar
- Be specific: exact dp values, token names, widget names. No vague
  adjectives such as modern or clean without a concrete rule behind them.
- Every recommendation ties to an observed problem or a stated principle.
- Do not invent features. Do not change meaning of any label that carries
  business meaning (Balance, Less, Received, Step Rate).
