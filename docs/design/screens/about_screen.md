> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# about_screen (lib/features/settings/about_screen.dart, 210 lines)

Contains `packageInfoProvider` (FutureProvider), `AboutScreen`, `_Section` and `_LicenseTextScreen`. All share this doc.

## 1. Purpose and primary user task

Read the installed version and build, see what the app stores and what permissions it uses, read the proprietary license, open the third-party license page, and open the developer link. Mostly read-only; used when someone reports a bug (version) or asks about privacy.

## 2. Current structure

- `AboutScreen` (ConsumerWidget, 15): `Scaffold(backgroundColor: AppColors.background)` with `AppBar(title: 'About', flexibleSpace: gradient)` and body `Center > ConstrainedBox(maxWidth: 700) > ListView(padding 16)`.
- Children: logo (72 dp, radius 18) + `AppInfo.name` (22 w700) + "Version X (build N)" + package name (12 sp, `textHint`); three `_Section`s ("What it is", "Your data", "Permissions (Android)"); a `Card` with three `ListTile`s (License, Open source licenses, Developer); footer copyright 12 sp.
- Provider read: `packageInfoProvider` (`PackageInfo.fromPlatform()`); until it resolves `version` and `packageName` are empty strings and their lines are not rendered.
- `_LicenseTextScreen` (175): second gradient app bar, `FutureBuilder<String>(future: rootBundle.loadString(AppInfo.licenseAsset))` creating the future inside `build`, `SelectableText` 13 sp in a 700 dp column.
- Constants from `AppInfo` (`lib/core/utils/app_info.dart`): name, driveFile, driveFolder, copyright, developerLink, developerUrl, licenseAsset.

## 3. Problems found

1. Theme trap: `AppTheme.appBarTheme` makes every `AppBar` transparent with white title and white icons (app_theme.dart:25-36). This screen and `_LicenseTextScreen` repair it with `flexibleSpace: gradient` (28-33, 181-185). `showLicensePage` (109-114) builds its own `AppBar` without that gradient, so its title and back arrow are white on the `#F8FAFC` page background (contrast about 1.05:1). UNVERIFIED on device, certain from the theme code.
2. Version and package lines pop in after the future resolves (52-59): layout shift of about 40 dp under the logo. No loading placeholder.
3. Package name uses `AppColors.textHint` #94A3B8 at 12 sp = 2.56:1 on white (59); copyright footer uses `textSecondary` 12 sp (134) 4.76:1 but is tiny.
4. Section titles 14 sp w700 `textSecondary` and body 14 sp `height 1.35` (157-167): paragraphs run as separate unbulleted lines; "Your data" has four independent facts with no visual separation. At 200 percent the page is a long scroll with no anchors.
5. `launchUrl` is fire-and-forget (123-124): no `await`, no failure feedback if no browser/handler, no `canLaunchUrl` check, and the row looks like a plain text row (no external-link icon; `Icons.code` leading with a bare URL text).
6. `_LicenseTextScreen` creates its future in `build` (188): each rebuild (for example window resize on macOS) restarts the FutureBuilder and flashes the spinner. `rootBundle` caches, so cost is low.
7. Card has default theme elevation 2 and 16 radius (87) while other settings cards use shadow containers: third card style on the Settings path.
8. The 700 dp max width is hard-coded in two places (36, 198); on macOS the page is centered but app bar spans the full width.
9. Tap targets: ListTiles are 56 dp+ so fine; the logo and version are not interactive (no copy-to-clipboard for the version string, which is what a user needs for a bug report). Copying is a UI action, not a logic change.
10. No dark/contrast concern beyond items 1 and 3; icons use the outlined style (`gavel_outlined`, `description_outlined`, `code`), inconsistent with the rounded system.

## 4. Redesign

Page: `RigScaffold(appBar: RigAppBar(title: 'About', leading: back), maxContentWidth: 700)`. Keep calling `showLicensePage` unchanged. It becomes legible without code in this file because the new global `AppBarTheme` has a solid `headerSurface` background with `onPrimary` foreground instead of transparent (see core_theme_and_widgets.md, AppBarTheme row).

Layout (all widths; wide screens only change padding 16 / 24 / 32 and cap 700):
1. Identity block, centered, vertical gap s2: logo 72 dp (`RigRadius.lg` 16), `headlineSmall` "RigLedger" (AppInfo.name), then a `Chip`-like row "Version 2.0.0 (build 5)" in `bodyMedium` `onSurfaceVariant` with a trailing `IconButton(Icons.copy_rounded, size 20, tooltip 'Copy version')` (48 dp hit) that copies "RigLedger 2.0.0 (5)" and shows `RigSnack` info "Version copied". While `packageInfoProvider` loads, a 16 dp-tall skeleton bar reserves the space (no layout shift); on error the line is hidden. Package id below in `bodySmall` `textMuted` (6.1:1 target; the replacement for `textHint`).
2. Info cards: each `_Section` becomes a `RigCard` with `RigSection` title (`titleSmall`) and its lines as list items with a 4 dp `Icons.circle` bullet 6 dp in `onSurfaceVariant`, text `bodyMedium` (14/20), line gap s2. Same strings; order unchanged ("What it is", "Your data", "Permissions (Android)").
3. Links card (`RigCard` padding 0) with `RigListRow`s: License (leading `Icons.gavel_rounded`, subtitle "RigLedger Proprietary License", trailing chevron), Open source licenses (leading `Icons.description_rounded`, subtitle "Flutter, packages and bundled fonts", trailing chevron), Developer (leading `Icons.code_rounded`, subtitle the link text, trailing `Icons.open_in_new_rounded`). Tapping Developer opens the URL; failure shows `RigSnack` error "Could not open the link" (new copy, UI only) because `launchUrl` returns false.
4. Footer: "(c) <copyright>. All rights reserved." `bodySmall` `textMuted`, centered, bottom padding s8.
5. `_LicenseTextScreen`: `RigScaffold` with `RigAppBar(title: 'License')`; text `SelectableText` `bodyMedium` (14/20) in a `RigCard` of max width 700, `Scrollbar` visible on macOS. Loading: skeleton lines; error: `EmptyState(icon: Icons.error_outline_rounded, title: 'License text is not available')` (same text as today).

State table
| State | Behavior |
|---|---|
| Default | all content |
| Loading | version skeleton; license skeleton |
| Empty | n/a |
| Error | version row hidden; license `EmptyState`; link failure snack |
| Disabled | n/a |

Motion: route push `slow` 300 ms (platform default); no other motion.

Desktop: hover on link rows (`surfaceContainerHigh`), cursor click on Developer, the version text is selectable (`SelectableText`), Cmd+W is the shell's job (not specified here).

Tokens: spacing s2 s4 s6 s8; radius lg; type headlineSmall, titleSmall, bodyMedium, bodySmall; colors surface, onSurface, onSurfaceVariant, textMuted, outlineVariant, primary.

Components: `RigScaffold`, `RigAppBar`, `RigCard`, `RigSection`, `RigListRow`, `EmptyState`, `RigSnack`.

## 5. Logic touchpoints that must stay untouched

- `packageInfoProvider` (`PackageInfo.fromPlatform()`), referenced also by settings_screen.dart:159 (keep its name and file).
- `AppInfo.name/driveFile/driveFolder/copyright/developerLink/developerUrl/licenseAsset` values and the interpolated sentences in "Your data" (they are verified facts, see MEMORY.md T-V207).
- `showLicensePage(applicationName, applicationVersion, applicationLegalese: '(c) ${AppInfo.copyright}')`, `registerAppLicenses()` in main.dart.
- `launchUrl(Uri.parse(AppInfo.developerUrl), mode: LaunchMode.externalApplication)`.
- The widget test for About (test added in T-V207): keep texts "Version", "RigLedger Proprietary License", "Open source licenses" findable.

## 6. Acceptance criteria

1. The version line shows "Version <x> (build <n>)" matching `pubspec.yaml` once loaded and reserves its space while loading (no vertical jump greater than 2 dp).
2. Tapping the copy button puts "RigLedger <x> (<n>)" on the clipboard and shows a confirmation snack.
3. The "Open source licenses" page title and back arrow are legible (contrast at least 4.5:1) on Android and macOS.
4. If the developer URL cannot be opened, a snack explains it; nothing crashes.
5. License screen shows the license text, selectable, and a scrollbar on macOS; unreadable asset shows "License text is not available".
6. At text scale 200 percent no text is clipped and every row wraps.
7. All icons are rounded variants; no gradient remains in the app bar.
8. Content width never exceeds 700 dp; the app bar spans the window.

## 7. Performance notes

- `_Section` is already `const`-friendly; make list of lines `const` and the page a `ListView` with `const` children where possible.
- Hold the license `Future` in `State` (convert `_LicenseTextScreen` to a `StatefulWidget` with `late final Future<String> _text = rootBundle.loadString(...)` in initState) to stop re-fetching on rebuild; text is about 10 KB so a plain `SelectableText` is fine (no virtualization needed).
- `ref.watch(packageInfoProvider)` is the only watch; use `.when` with the skeleton rather than `maybeWhen`.

## Reconciliation 2026-10-13 (Apple look, Android only)

Dropped from the redesign: macOS and desktop items (hover, selectable version for a pointer, scrollbar visible on macOS, window wide app bar, Cmd keys, the 700 dp cap as a layout rule). Old text stays above.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Mockup function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| About | `SC.about` | `lib/features/settings/about_screen.dart` (`AboutScreen`, `_Section`) | LargeTitleScaffold (pushed, title "About", back control 48 dp), identity block (84 dp rounded logo tile radius 22, name 22 sp, version, package id), three RigCard text blocks, RigGroup of three RigRows (License, Open source licenses, Developer), footer text | pushed from the Settings row |
| (pushed from About, not in the J list) | `SC.license` | same (`_LicenseTextScreen`) | LargeTitleScaffold "License", RigCard with selectable text | the mockup draws the text in one card at 13 sp |
| About, "Open source licenses" row | snackbar placeholder | same (`showLicensePage`) | Flutter license page, themed by the new `AppBarTheme` | must be legible in light and dark |

### R2. What changes in the redesign (supersedes section 4)

Layout (360 dp and 412 dp, one width):
1. LargeTitleScaffold, large title "About" collapsing to 17 inline, solid 94 percent bar, hairline, no blur by default.
2. Identity block, centered, padding 8 x 18: logo tile 84 dp, radius 22, fill `accentButton`, glyph `onAccent` 46 dp (the real asset `assets/images/logo.png` replaces the glyph when shown; a flat tile behind it only if the asset has transparency); "RigLedger" 22 sp w700 (`AppInfo.name`); "Version 2.0.0 (build 5)" 15 sp `labelSecondary` from `packageInfoProvider`; package id 12 sp `labelSecondary` (AA, replaces `textHint`). While the future loads a Skeleton bar reserves both lines so nothing shifts (kept from the old criterion 1).
3. Three RigCards (`surfaceContainerLow`, radius 20, padding 16, margin 20 and gap 12): title 13 sp w600 uppercase `labelSecondary` ("What it is", "Your data", "Permissions (Android)") and paragraphs 15 sp line height 1.4, 8 dp between paragraphs. Strings are the verified facts from `AppInfo`; no bullets (the mockup uses paragraphs).
4. RigGroup with three RigRows: License (icon gavel, subtitle "RigLedger Proprietary License", chevron), Open source licenses (icon description, subtitle "Flutter, packages and bundled fonts", chevron), Developer (icon code, subtitle `github.com/...` from `AppInfo.developerLink`, external link affordance). Developer failure shows RigSnack "Could not open the link" (UI copy only).
5. Footer: "(c) <AppInfo.copyright>. All rights reserved." 13 sp `labelSecondary`, inset 36.
6. License screen: LargeTitleScaffold "License", one RigCard with `SelectableText` 13 sp line height 1.5; the future is held in State (`late final`); loading = Skeleton lines; failure = EmptyState "License text is not available" (same text).

States:

| State | Behaviour |
|---|---|
| Default | all content |
| Loading | version and package id Skeleton; license text Skeleton |
| Empty | not applicable |
| Error | version lines hidden on failure; license EmptyState; link failure snack |
| Disabled | not applicable |

Motion: route push uses the Android default transition (predictive back enabled); ink press on the three rows; zero under reduced motion.

Old section 4 items:

| Old item | Verdict |
|---|---|
| RigScaffold, RigAppBar, 700 dp cap | CHANGED (LargeTitleScaffold, one width) |
| Copy version button with snack "Version copied" | KEPT as an optional addition not shown in the mockup: long press on the version line copies "RigLedger 2.0.0 (5)" and shows a RigSnack (no extra icon in the identity block, so the mockup look is unchanged); mark as open to the developer, UI only |
| Info sections as bullet lists (circle bullets) | CHANGED (paragraphs, as in the mockup) |
| Links card with rounded icons, trailing open_in_new for Developer | KEPT |
| Failure snack for the developer link | KEPT |
| License screen: skeleton, error EmptyState, scrollbar on macOS | CHANGED (skeleton and EmptyState kept; macOS scrollbar DROPPED) |
| `showLicensePage` legible through a solid AppBarTheme | CHANGED (the new global theme sets a flat `surface` bar with `onSurface` foreground in light and dark, see core_theme_and_widgets.md) |
| Hover, selectable pointer text, Cmd+W | DROPPED |
| Gradient app bar removal | KEPT (no gradient anywhere) |

### R3. Logic touchpoints and LR items

Untouched: `packageInfoProvider` name and file (also read by settings_screen), `AppInfo` values and the interpolated sentences in "Your data", `showLicensePage(applicationName, applicationVersion, applicationLegalese: '(c) ${AppInfo.copyright}')`, `registerAppLicenses()` in `main.dart`, `launchUrl(..., LaunchMode.externalApplication)`, the About widget test texts ("Version", "RigLedger Proprietary License", "Open source licenses").

| Id | Dependency | Status |
|---|---|---|
| LR-23 | the license page and About must follow the chosen theme | approved |
| none new | the mockup About text says "Available for Android." while `about_screen.dart:69` says "Available for Android and macOS."; macOS is frozen, not removed, so the string is a developer decision (conflicts_r4.md) | open question, no logic |

### R4. Acceptance criteria delta

1. The version line equals `pubspec.yaml` ("Version 2.0.0 (build 5)") once loaded and its space is reserved while loading (no jump over 2 dp).
2. The License, Open source licenses and Developer rows are at least 48 dp tall; the Developer row opens the URL or shows the failure snack.
3. The Flutter license page title and back arrow have at least 4.5:1 contrast in light and dark.
4. At text scale 130 and 200 percent no text clips; the three cards and rows wrap; the identity block stays centered.
5. License text is selectable; unreadable asset shows "License text is not available".
6. No gradient or Material elevation shadow remains on this screen; cards use the RigCard style (soft shadow in light only).
7. Android back returns to Settings from About and from License; predictive back animates.

### R5. Parity delta

Changes on purpose: line 26 layout (paragraphs, new card style); the "Available for ..." sentence only if the developer edits the string. Must stay identical: app name, version and build equal to `pubspec.yaml`, package id, the three sections with the same sentences, License text opens, the Flutter license page lists the bundled fonts, the Developer link, the copyright footer.

### R6. Performance and Android notes

- Insets: edge to edge; the scroll body pads the bottom by `viewPaddingOf(context).bottom + 24` (pushed screen: no tab bar).
- Hold the license `Future` in State (stop refetching on rebuild); `rootBundle` caches; plain `SelectableText` is enough for about 10 KB.
- `ref.watch(packageInfoProvider)` uses `.when` with the skeleton; the rest of the page is const.
- No BackdropFilter; budgets: p90 build and raster under 8 ms, p99 under 16 ms.
