> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# settings_screen (lib/features/settings/settings_screen.dart, 809 lines)

Tab 5 of both shells. Also holds `_SettingsCard`, `_SettingsTile` and `_GoogleDriveBackupCard` (the Drive card with sign-in, auto backup, backup now, restore). All share this doc. Navigation targets (vehicle management, CSV export/import, PDF export, About) have their own docs.

## 1. Purpose and primary user task

One place to: switch or manage rigs, export or import ledger files, create and restore backups (file and Google Drive), connect Drive and toggle auto backup, wipe all data, and open About. The two high-risk jobs are Restore and Clear All Data: both destroy every record on the device.

## 2. Current structure

- `SettingsScreen` (ConsumerWidget, line 24): `Scaffold` > `Column` > [`AdaptiveHeader(title: 'Settings')`, `Expanded(ListView(padding 16))`]. Sections (text titles built by `_buildSectionTitle`, 192): Vehicle, Export & Import, Backup & Restore, Google Drive Backup, Data, About. Each is a `_SettingsCard` (white rounded `Container` with shadow, 16 radius) containing `_SettingsTile`s (`ListTile` with leading icon, 12 sp subtitle, chevron).
- Providers read: `currentVehicleProvider` (Consumer, line 48), `packageInfoProvider` (about_screen.dart FutureProvider, line 159). Written (on restore and clear): `ledgerEntriesProvider`, `agentsProvider`, `vehiclesProvider`, `dieselEntriesProvider`, `pvcEntriesProvider`, `bitEntriesProvider`, `hammerEntriesProvider`, `cashBooksProvider`, `cashEntriesProvider`, `cashNotesProvider`, `cashSettingsProvider`, `currentCashBookIdProvider` `.notifier.refresh()` (lines 279-290, 362-373, 583-594).
- Services: `DatabaseService.createBackup/restoreBackup/clearAllData`, `FileSaveService.saveStringFile`, `FilePicker.platform.pickFiles`, `GoogleDriveService.initialize/signIn/signOut/backup/restore/isSignedIn/userEmail/lastBackupTime/isAutoBackupEnabled/setAutoBackupEnabled`.
- `_GoogleDriveBackupCardState` (464): flags `_isLoading`, `_isBackingUp`, `_isRestoring`. Platform variants: Windows/Linux (desktop and not macOS) shows a static hint card (643-688); Android and macOS show the live card. Because the app ships for Android and macOS only (CLAUDE.md), the Windows/Linux branch is unreachable.

## 3. Problems found

Destructive safety (highest priority)
1. Restore order is wrong for safety (243-278): the app asks "replace all current data?" first and only then opens the file picker. The user confirms without knowing which file or what it contains, and the file is never validated (no check that the JSON is a RigLedger backup, no date, no record counts) before `DatabaseService.restoreBackup` clears the boxes. A wrong .json file wipes data (restoreBackup runs `_clearAllDataForRestore` first, database_service.dart:373, and is not atomic: MEMORY.md open bug).
2. Restore confirm button is amber `AppColors.warning` with white text (257): 2.15:1, and amber signals "caution", not "this deletes everything". Same for the Drive restore text button (566).
3. Clear All Data dialog lists "ledger entries, agents, side-ledger entries, vehicles (except default)" (323-335) but `DatabaseService.clearAllData` (database_service.dart:469) also clears every Account Ledger book, transaction and note, and the tombstone box. The user is not told that the cash book is erased. Copy must list it. UNVERIFIED: whether clearing tombstones lets a later Drive sync resurrect deleted records from the remote snapshot (logic request).
4. Clear All Data is one tap plus one confirm; the red button "Delete Everything" (353) is enabled immediately and white on #EF4444 is 3.76:1. No offer to create a backup first, no typed confirmation. `clearAllData` is awaited without try/catch (361) so a Hive error becomes an unhandled exception.
5. Restore from Drive replaces local data (551-626) but the dialog does not show what will be restored (backup time, size, or counts) and does not show when the local data was last backed up. A local-only recent change can be lost silently.
6. Disconnect dialog says "Auto-backup will be disabled" (514) but `signOut` does not visibly change `isAutoBackupEnabled` in this file; copy may be inaccurate. UNVERIFIED (google_drive_service.dart:125).

Feedback during long operations
7. File backup (206-240) and clear all (361) show no progress. A large database freezes the UI with no indication; the tile stays tappable, so a second tap starts a second backup.
8. Local restore (278-290) has no progress UI and is not guarded against double invocation or leaving the screen; the user can switch tabs mid-restore (IndexedStack keeps the widget alive, but navigation is possible).
9. Drive card replaces itself by a full-card spinner on init and sign-in (690-699): the card collapses to about 72 dp and everything below jumps. Backup Now and Restore use a 24 dp spinner as the leading icon (766-792) with the subtitle unchanged ("Upload backup to Google Drive") so the text never says "Uploading...".
10. Errors are only snackbars with raw exception text (`'Failed to restore backup: $e'`, 303; 'Failed to restore: $e', 618). A raw `FormatException`/`PlatformException` string is meaningless to the user and the snackbar disappears. `GoogleDriveService.signIn` returns multi-line developer instructions (keytool, Firebase Console, a GitHub handle; google_drive_service.dart:93-99) that are shown to end users in a snackbar.
11. Last backup text is computed once per build (628-637): "1 hours ago" (grammar), never refreshes while the screen is open, no absolute time.

Correctness and state
12. `setState` after `await` without `mounted` check: auto-backup switch (754-757) and `_signOut` (531-532 checks `mounted` before the await only, setState after). Possible "setState called after dispose".
13. `ref` captured in a `ConsumerWidget` method and used after awaits (279-290, 362-373). If the tab is rebuilt/disposed during the await, `ref.read` throws. UNVERIFIED (IndexedStack usually keeps it alive).
14. `result.files.first.path!` (274) throws on platforms returning bytes only; caught by the generic catch with a technical message.
15. The restore flow refreshes 12 providers in two places and the clear flow repeats the same list (duplicate code; any new provider must be added three times).

Layout, density, contrast
16. `_SettingsTile` subtitles are 12 sp `textSecondary` #64748B (4.76:1 on white, passes) but chevrons and icon colors for destructive tile use `AppColors.error` for both icon and title (146): red title at 16 sp is 3.76:1 (fails AA).
17. Cards use `BoxShadow(blur 10)` plus rounded clip (394-410): 6 shadowed containers on a scroll page; also duplicated three times in the Drive card (645-657, 703-714).
18. Section titles are 14 sp w600 `textSecondary` with 4 dp left inset (192-203), not aligned with card edges (card inset 0): inconsistent with other screens (Portfolio uses 18).
19. The Drive card mixes `ListTile` heights: not-connected tile has a filled `ElevatedButton` "Connect" as trailing (724-727), at 200 percent the title ("Google Drive not connected") and button compete for width and the ListTile trailing is forced to a fixed 56 dp band: overflow risk. UNVERIFIED on device.
20. About tile uses a 32 dp logo image trailing (168-172) with no semantics label.
21. Desktop (macOS): the page has no max width (content wrapper at desktop_shell.dart:793 only removes padding, it does not constrain; comment is misleading), so on a 1280 dp window the tiles stretch to about 1000 dp wide with the chevron far from the text. The desktop-only text "Backup is managed on your Android device. Use Cmd+S ..." (675) is in the unreachable branch.
22. No keyboard or focus affordance specified for desktop; tiles are `ListTile`s so they are focusable but have no hover color change beyond default.
23. Currency/date: `DateFormat('MMM d, yyyy')` (636) differs from the app-wide target `dd MMM yyyy`.

## 4. Redesign

Page: `RigScaffold(appBar: RigAppBar(title: 'Settings'), maxContentWidth: 720)`; body is a `ListView` (padding: 16 compact, 24 medium, 32 expanded, centered, max 720). One section = `RigSection(title)` (title `titleSmall`, `onSurfaceVariant`, padding left s4 so it aligns with row text) + `RigCard` (level 1, 1 px `outlineVariant`, no shadow) containing `RigListRow`s separated by `RigDivider(inset: 56)`. Section order and copy are unchanged: Vehicle, Export & Import, Backup & Restore, Google Drive Backup, Data, About.

`RigListRow` anatomy: leading `Icon` 24 in a 40 dp circle `primaryContainer` tint (icon `primary`), title `bodyLarge` w500 `onSurface`, subtitle `bodySmall` `onSurfaceVariant` (max 2 lines, wraps at large text), trailing `Icons.chevron_right_rounded` 24 `onSurfaceVariant` (or a control). Min height 64 dp, whole row is the tap target. Icons switch to rounded variants: `Icons.directions_car_rounded`, `Icons.file_download_rounded`, `Icons.file_upload_rounded`, `Icons.picture_as_pdf_rounded`, `Icons.backup_rounded`, `Icons.restore_rounded`, `Icons.cloud_done_rounded`, `Icons.cloud_off_rounded`, `Icons.sync_rounded`, `Icons.cloud_download_rounded`, `Icons.delete_forever_rounded`, `Icons.info_rounded`.

Layout by width
- Compact: single column as above. Drive card rows stack: the signed-out row shows title and subtitle, with the "Connect" `FilledButton` on its own line below (full width of the card, 48 dp) instead of as ListTile trailing.
- Medium (600-900): same, centered at 600 max.
- Expanded (>900): max width 720 centered; additionally the Data section sits last with a `negativeContainer` hairline (1 px `negative` at 24 percent) around the card so it reads as the danger zone. Hover `surfaceContainerHigh` on rows, cursor click. Remove the Windows/Linux hint branch from the design (platforms are Android and macOS only); keep the code path untouched, just do not design for it.

Google Drive card states (single `RigCard`)
| State | Layout |
|---|---|
| Initializing | card keeps its normal height; a 2 px `LinearProgressIndicator` along the top edge and the first row reads "Checking Google Drive..." (no full-card spinner) |
| Signed out | row: `cloud_off` + "Google Drive not connected" + subtitle "Connect for automatic cloud backup"; `FilledButton.tonal` "Connect" below |
| Signed in | account row (email, "Last backup: 12 Oct 2026, 10:30 (2 hours ago)"), disconnect `IconButton(logout, tooltip: 'Disconnect')` 48 dp; Auto Backup row with `Switch` (title "Auto Backup", subtitle "Backup automatically every 6 hours"); Backup Now row; Restore from Drive row |
| Backing up | Backup Now row title "Backing up...", spinner 20 dp leading, row disabled; other Drive rows disabled; screen-level Back stays allowed |
| Restoring | modal non-dismissible `RigDialogShell` "Restoring from Google Drive" with indeterminate progress and text "Do not close the app"; closes on completion, then success or error snackbar |
| Error | `ErrorBanner` inside the card under the row that failed with the same message text plus "Retry" when a retry exists (Backup Now, Restore). Developer-only help text is moved out of the user path: the long ApiException 10 message is shown in a collapsed "Details" expander (copy only, the string itself comes from the service) |

Destructive flows (UI only; function calls unchanged)
- Restore Backup (file): new UI order: tap row, file picker opens first (the `FilePicker.pickFiles` call is the same, just invoked before the dialog), then a `RigDialogShell` titled "Restore this backup?" shows file name, and, if the already decoded JSON map exposes them, the backup counts (ledger entries, agents, vehicles) and date, plus the sentence "This replaces all data on this device. This cannot be undone." and a button "Create a backup of current data first" (calls the existing `_createBackup`). Actions: Cancel (left, default focus) and "Restore" as a filled `negative` button. After confirm: modal progress dialog during `restoreBackup`, then `RigSnack` success "Backup restored successfully". If counts are not available in the file, the dialog shows only the file name.
- Restore from Drive: same dialog without the picker; shows "Backup on Google Drive" and the last local backup time; same buttons and progress modal.
- Clear All Data: `RigDialogShell` with a `negativeContainer` banner, list "All ledger entries, agents, vehicles (except default), side-ledger entries (Diesel, PVC, Bit, Hammer), and all Account Ledger books, transactions and notes", a `RigTextField` "Type DELETE to confirm" and the confirm button "Delete everything" disabled until the text equals DELETE (case-insensitive). The dialog also carries a text button "Create backup first". After confirm: progress modal then snack "All data cleared".
- Disconnect Google Drive: keep `ConfirmDialog`, destructive text button in `negative`; keep the existing sentence.
- In every dialog the destructive action is a text/filled `negative` button on the right, Cancel on the left and focused; Esc closes; Enter does not trigger the destructive action.

Motion: dialog and sheet entrance `slow` 300 ms; row press color `fast`; progress modal appears with no extra animation; with reduced motion all zero.

Tokens: spacing s2 s3 s4 s6; radius lg (cards), md (buttons, inputs), full (icon circle); type bodyLarge, bodySmall, titleSmall, labelLarge; colors surface, primary, primaryContainer, onSurface, onSurfaceVariant, outlineVariant, negative, negativeContainer, moneyIn (connected icon).

Components: `RigAppBar`, `RigScaffold`, `RigSection`, `RigCard`, `RigListRow`, `RigDivider`, `RigDialogShell`, `ConfirmDialog`, `RigTextField`, `ErrorBanner`, `RigSnack`, new `ProgressDialog` (components_g3.md), new `TypedConfirmDialog` (components_g3.md).

## 5. Logic touchpoints that must stay untouched

- `DatabaseService.createBackup()`, `restoreBackup(map)`, `clearAllData()`, the JSON encoder (`JsonEncoder.withIndent('  ')`) and file name `rigledger_backup_yyyyMMdd_HHmmss.json`; `FileSaveService.saveStringFile` argument names (`shareSubject`, `dialogTitle`).
- The 12-provider refresh list after restore and after clear (same members, same order is not required, but none may be dropped), including the `cashSettingsProvider` and `currentCashBookIdProvider` refreshes.
- `FilePicker` extension filter `['json']`.
- `GoogleDriveService` calls and their `(bool, String?)` record contracts; the platform guard `!PlatformHelper.isDesktop || PlatformHelper.isMacOS` for initialization.
- Auto backup toggle persists via `setAutoBackupEnabled(value)`; copy "every 6 hours" must match the service interval.
- Navigation targets: `VehicleManagementScreen`, `CsvExportScreen`, `CsvImportScreen`, `PdfExportScreen`, `AboutScreen` (MaterialPageRoute pushes, no named routes).
- Section and row titles and snackbar strings listed in the current code.

## 6. Acceptance criteria

1. Tapping Restore Backup opens the file picker before any destructive confirmation; cancelling the picker changes nothing and shows no message.
2. Choosing a valid backup shows a confirmation naming the file; confirming restores the data and all 12 providers refresh (ledger, agents, vehicles, side ledgers, all Account Ledger lists update without restart).
3. Choosing a non-RigLedger JSON shows an error banner/snackbar "Failed to restore backup" with the exception text only in Details and leaves existing data unchanged (current behavior at the service level is to clear first; if that cannot be guaranteed, log it in logic_g3.md).
4. The Clear All Data confirm button is disabled until DELETE is typed; the dialog text mentions Account Ledger books, transactions and notes.
5. While backing up, restoring or clearing, the triggering row is disabled and a progress indicator with a text label is visible; a second tap cannot start a second operation.
6. Drive card keeps its height during initialization and sign-in (no jump greater than 8 dp).
7. After signing out, Auto Backup switch and Backup Now rows are no longer displayed; after signing in they appear.
8. At text scale 200 percent no row overflows; subtitles wrap to up to 3 lines; the Connect button is full width.
9. All rows have a 48 dp minimum tap height, chevrons are not separate tap targets.
10. On macOS at 1280 dp window width the settings content is at most 720 dp wide and centered.
11. The destructive text color `negative` has at least 4.5:1 on its background in every dialog; no amber button remains.
12. About row still shows "Version X (build N), license, notices" and opens AboutScreen.

## 7. Performance notes

- Extract `SettingsSection`, `SettingsRow` as `const` widgets; only the Vehicle row and About row are `Consumer`s (already true), keep it so.
- The Drive card is a `StatefulWidget` using `setState({})` for the whole card; split into `DriveAccountRow`, `DriveAutoBackupRow`, `DriveActionRows` so the switch toggle does not rebuild others. Use `ValueNotifier`s only if the service exposes them (it does not: static getters), so keep `setState` but scoped.
- Replace the three copies of the 12-line refresh block with one private function `_refreshAllProviders(WidgetRef)` (pure refactor, same calls).
- Avoid computing `_formatLastBackup()` and `GoogleDriveService.isSignedIn` on every parent rebuild: compute once per build of the card (already) and refresh with a 60 s `Timer.periodic` owned by the State (cancel in dispose) only while the card is visible; skip the timer if reduced motion/performance is a concern (then show the absolute time only).
- Backups of large data: JSON encoding with indentation runs on the UI isolate (line 209); showing the progress dialog before awaiting lets the first frame paint (`await Future<void>.delayed(Duration.zero)`), with the heavy work unchanged.

## Reconciliation 2026-10-13 (Apple look, Android only)

Dropped from the redesign: the macOS and desktop variant (Expanded layout with a 720 dp cap, hover, Esc and Enter rules, the Windows and Linux hint branch), medium widths, and the typed "DELETE" confirmation and the backup-first buttons proposed in section 4 (not in the approved mockup, see R2). Old text stays above; macOS and Drive desktop code stay frozen and untouched.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Mockup function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Settings (Drive connected) | `settingsTab` + `driveCard` (S.drive true) | `lib/features/settings/settings_screen.dart` (`SettingsScreen`, `_GoogleDriveBackupCard`) | LargeTitleScaffold ("Settings"), RigCard hero (account, last backup, RigButton filled "Back up now", RigButton tonal "Restore from Google Drive"), RigGroup with RigRow + RigSwitch (Auto Backup) and RigRow Disconnect, RigGroups of RigRows with leading 30 dp icon tile and chevron | tab 5 of 5, built lazily. Section order changes (R2) |
| Settings (Drive not connected) | `driveCard` with S.drive false | same | RigCard hero (cloud_off avatar 64 dp, title, caption, RigGroup of three benefit rows, RigButton "Connect Google Drive") | benefit copy must stay true: auto backup is a toggle that is off by default |
| Settings Drive sync error | `driveCard` with UI.state error | same | ErrorBanner "Google Drive sync failed" with a Retry action | reads `syncProvider` status and `errorMessage` (existing fields); Retry calls the existing sync or backup call |
| Appearance sheet | `appearanceSheet` | same (new `_AppearanceSheet`) | RigSheet (not full height), RigGroup of three RigRows System, Light, Dark with a check, footer "System follows the device setting." | LR-23 and LR-35; the Appearance row shows the current value and a chevron |
| Clear All Data dialog | `clearDlg` | same (`_showClearDataDialog`) | RigAlertDialog "Clear All Data", buttons Cancel (default) and "Delete Everything" (destructive) | text must add Account Ledger (LR-28), see conflicts |
| Restore Backup dialog | `restoreDlg` | same (`_restoreBackup`) | RigAlertDialog "Restore Backup", Cancel and "Restore" (destructive) | LR-28: the file picker opens first, this alert comes after a file is chosen; the mockup draws only the alert |
| (not in the J list, drawn by the mockup) | `driveRestDlg`, `discDlg` | same | RigAlertDialog "Restore from Google Drive", "Disconnect Google Drive" | same alert style |
| Vehicle Management, Add Vehicle dialog, Export to CSV, Import from CSV, Export to PDF, About | see vehicle_management_screen.md, csv_export_screen.md, csv_import_screen.md, pdf_export_screen.md, about_screen.md | | | rows in this screen push those routes |

### R2. What changes in the redesign (supersedes section 4)

Layout (single column, 20 dp margin, 12 dp gap):
1. LargeTitleScaffold "Settings" (34 collapsing to 17).
2. Drive hero card (`RigCard`, radius 20, padding 16): not connected = centered 64 dp avatar (`accentTint`, cloud_off in `accentText`), title "Google Drive backup" 22 sp, caption "Keep a private copy of your ledger in your own Drive." 15 sp `labelSecondary`, a flat RigGroup of three rows with icons (Automatic backup every 6 hours, Restore on a new device, Stored only in your own Drive), RigButton filled "Connect Google Drive". Connected = 52 dp avatar (cloud_done, `moneyIn`), account email 17 sp w600 (ellipsis), "Last backup: <relative time>" 13 sp, RigButton filled "Back up now", RigButton tonal "Restore from Google Drive"; then a RigGroup: row "Auto Backup" with subtitle "Every 6 hours" and a RigSwitch (track `moneyIn` on, `fillStrong` off, 51 x 31, padded 48 dp target), row "Disconnect" (`labelSecondary` icon logout). Error = ErrorBanner (radius 16, `fill` background, error icon `moneyOut`) "Google Drive sync failed" with a Retry text button; the long developer instructions of `GoogleDriveService.signIn` are not shown (L3 L-08) and the raw exception text is not shown.
3. Group "Appearance" and "Rigs" (no section label): Appearance row (icon contrast, value "System", chevron, opens the Appearance sheet); Rigs row (icon `directions_car` in `accentText`, title "Rigs", subtitle "Current: <rig name>", chevron).
4. Section label "BACKUP AND RESTORE" (13 sp uppercase `labelSecondary`) then a RigGroup: Create Backup ("Backup all data to a file"), Restore Backup ("Restore data from a backup file").
5. Section label "EXPORT AND IMPORT": Export to CSV, Import from CSV (icons `moneyInButton`), Export to PDF (icon `moneyOutButton`).
6. Section label "ABOUT": "About RigLedger", subtitle "Version 2.0.0 (build 5), license, notices" (version from `package_info_plus`).
7. Section label "DATA": Clear All Data row, destructive (`moneyOutText` title and icon `moneyOutButton`), subtitle "Delete all ledger entries and agents" (kept as the mockup text; the alert gives the full scope).
8. Row anatomy (RigRow): min height 48 dp, padding 11 x 16, leading icon tile 30 dp with radius 8 (fill `accent`, white 19 dp glyph, or the semantic colour), title 17 sp w400, subtitle 13 sp `labelSecondary`, trailing chevron 20 dp `labelTertiary` or a RigSwitch. Rounded icon set only. Section labels sit 36 dp from the left edge (margin 20 + 16).
9. Alerts: RigAlertDialog radius 14, 270 dp wide, buttons stacked 48 dp, destructive in `moneyOutText`, Cancel is the default action. Copy: Restore Backup "This will replace all current data with the backup data. This action cannot be undone. Continue?"; Restore from Google Drive "This will replace all current data with the backup from Google Drive. This action cannot be undone."; Disconnect "Are you sure you want to disconnect from Google Drive? Auto-backup will be disabled."; Clear All Data text per LR-28: it must also name the Account Ledger (books, transactions and notes), see conflicts_r4.md.
10. Appearance sheet: RigSheet with RigGroup rows System (brightness_auto), Light (light_mode), Dark (dark_mode), a check in `accent` on the active one, footer "System follows the device setting." Choosing a row applies the theme at once (200 ms cross fade of colours is not needed; a rebuild is enough) and the sheet stays open so the change is visible, as in the mockup.

States:

| State | Behaviour |
|---|---|
| Default | hero card plus groups |
| Loading | while `GoogleDriveService.initialize()` runs the hero card keeps its height and shows a Skeleton line in place of the account text (no full-card spinner). Backing up: the "Back up now" pill shows a 20 dp spinner and "Backing up...", other Drive buttons disabled. Restore and Clear run behind a non-dismissible progress alert |
| Empty | not applicable |
| Error | ErrorBanner in the hero card (sync error, backup or restore failure) with Retry; backup and restore failures not tied to sync show a RigSnack with plain text, details only in the banner |
| Disabled | the pressed row or button while an operation runs (no second backup or restore can start) |

Motion: sheet rise and alert fade 200 to 350 ms ease-out; ink press feedback on rows; all zero under reduced motion.

Old section 4 items:

| Old item | Verdict |
|---|---|
| RigScaffold, RigAppBar, maxContentWidth 720 | CHANGED (LargeTitleScaffold, one width) |
| Section order Vehicle, Export & Import, Backup & Restore, Google Drive Backup, Data, About | CHANGED (Drive hero, Appearance and Rigs, Backup and restore, Export and import, About, Data) |
| RigListRow with 40 dp tinted circle, min height 64 | CHANGED (RigRow, 30 dp rounded tile, min 48) |
| Rounded icon list | KEPT |
| Drive signed out: Connect button on its own line, full width | KEPT (inside the hero card) |
| Initializing: card keeps height, 2 px bar, "Checking Google Drive..." | CHANGED (Skeleton line, no bar) |
| Signed in rows (account, Auto Backup, Backup Now, Restore) | CHANGED (hero card with two buttons, then Auto Backup and Disconnect group) |
| Backing up and Restoring modal | KEPT |
| Error banner inside the card, developer text moved out | KEPT |
| Restore: file picker first, then confirm | KEPT and APPROVED as LR-28 |
| Restore dialog showing counts, date, "Create a backup of current data first" | DROPPED (not in the mockup and it needs the JSON read before restore; file validation is data item D-02 in BUGS_FOUND.md) |
| Clear All Data with typed DELETE and "Create backup first" | DROPPED (the approved scope is the warning text only, LR-28) |
| Clear All Data list names Account Ledger | KEPT (LR-28) |
| Disconnect ConfirmDialog | KEPT as RigAlertDialog |
| Expanded layout, danger zone hairline, hover, Esc/Enter | DROPPED |
| Windows and Linux hint card | DROPPED (code untouched) |
| Date format `MMM d, yyyy` for last backup | CHANGED (`dFull`, "12 Oct 2026", plus relative time) |

### R3. Logic touchpoints and LR items

Untouched: `DatabaseService.createBackup`, `restoreBackup(map)`, `clearAllData`, `JsonEncoder.withIndent('  ')` and the file name `rigledger_backup_yyyyMMdd_HHmmss.json`; `FileSaveService.saveStringFile` arguments; the 12 provider refreshes after restore and clear; `FilePicker` filter `['json']`; every `GoogleDriveService` call and its `(bool, String?)` contract; the platform guard for init; `setAutoBackupEnabled`; "every 6 hours" must match the service interval; navigation by `MaterialPageRoute` push to the five screens.

| Id | Dependency | Status |
|---|---|---|
| LR-23, LR-35 | Appearance row and sheet, one settings key (for example `themeMode`: system, light, dark), `themeModeProvider`, no schema bump, not synced | approved |
| LR-28 | Restore asks for the file first then confirms; Clear All Data warning names Account Ledger | approved |
| LR-24 | rupee sign and en-IN formats do not touch this screen except dates | approved |
| LR-32 | double tap guard on Back up now, Restore, Clear (disabled while running) | approved (UI guard) |
| LR-01 | clearing and restoring refresh the same providers; Settings is lazy so its own state is only built on first visit | approved |
| L3 L-06 / D-02 | atomic restore and file validation before restore | not scheduled, data item (plan mode) |
| L3 L-08 | plain language Drive sign-in errors | not scheduled; the hero error banner must not show the developer text, so until L-08 lands show the fixed text "Could not connect to Google Drive" and keep the service string unused in the UI (UI choice only, no service change) |
| L3 L-10 | sync status in the card | `SyncState` already exposes `status` and `errorMessage` (`sync_provider.dart:21-24`), so reading it is not a logic change; no new item |
| L2-r4-3 | refresh the 12 providers through one shared function | proposed, new, pure refactor (see temp/design_wip/logic2_r4.md) |

Lazy tab check: Settings is a `ConsumerWidget` with a `StatefulWidget` child `_GoogleDriveBackupCard` that holds `_isLoading`, `_isBackingUp`, `_isRestoring` and runs `initialize()` in `initState` (`settings_screen.dart:470-483`). Keeping the tab alive therefore keeps those flags; the first build now happens on first visit instead of at launch, so the Drive card initialises when the user first opens Settings (the service is already initialised in `main()`, so the second call is cheap). In-flight operations survive a tab switch. A restore in flight must not rely on `ref` after the tab is disposed: since the tab is retained, `ref.read` after the await stays valid (old problem 13 is resolved by keep-alive, still use `mounted` checks).

### R4. Acceptance criteria delta

1. Section order on screen is: Drive hero, Appearance and Rigs, Backup and restore, Export and import, About, Data.
2. Appearance shows the stored choice (System by default); selecting Dark switches the whole app at once and persists across a cold start; System follows the device theme.
3. Drive card in each of the three states (connected, not connected, sync error) matches the mockup at 360 dp and 412 dp, light and dark; the card height does not jump more than 8 dp when initialisation finishes.
4. Restore Backup opens the file picker first; cancelling the picker changes nothing and shows nothing; after a file is chosen the alert appears; Cancel is the default and changes nothing; Restore refreshes all 12 providers.
5. The Clear All Data alert text names Account Ledger books, transactions and notes; "Delete Everything" is destructive-styled and enabled immediately (no typed confirmation); Cancel is the default.
6. While a backup, restore or clear runs the triggering control is disabled and a progress label is visible; a second tap cannot start a second operation.
7. At text scale 130 and 200 percent no row or the hero card overflows; subtitles wrap; the pills keep 50 dp height; the Drive benefit rows wrap.
8. Every row and button is at least 48 dp; the RigSwitch has a 48 dp tap target.
9. Android back closes the alert or sheet first; on the tab itself back follows the shell (Q-O6).
10. Leaving Settings and returning keeps the scroll position and any running operation state; the first visit builds in under 100 ms.
11. Destructive text `moneyOutText` has at least 4.5:1 on the alert surface in light and dark.

### R5. Parity delta

Changes on purpose: line 13 (section order and titles, see R4.1; the row title "Vehicle" becomes "Rigs" and the row shows "Current: <rig name>"); line 17 (cancel the restore confirmation: now the picker has already opened, so cancelling the picker or the alert changes nothing); line 18 (the Clear All Data alert text now names Account Ledger); line 19 (hero card layout, same facts); line 21 and 22 (same results, new layout); line 25 ("Manage Vehicles" becomes the Rigs row); line 24 (About row text keeps "Version <x> (build <n>)"). New line: Appearance persists and applies (System, Light, Dark).
Must stay identical: lines 14, 15, 16 (record outcome), 20 (auto backup persists), 22 messages "Data restored successfully" and "No backup found on Google Drive", 23, and every message string ("Backup created successfully", "Backup restored successfully", "All data cleared").

### R6. Performance and Android notes

- Insets and edge to edge: list bottom padding = floating RigTabBar (62 dp) + `viewPaddingOf(context).bottom` + 8 + 24; no hard coded 24.
- Back: alert and sheet routes close with system back; no PopScope needed on the tab.
- List strategy: about 15 rows, plain `ListView`; one const RigGroup per section; only the Rigs row and About row are Consumers; the Drive hero is its own widget so a switch toggle rebuilds only the Auto Backup row (scope `setState`).
- Caching: `_formatLastBackup()` computed once per card build; if a 60 s refresh timer is kept it is owned by the card State and cancelled in `dispose`; with reduced motion show the absolute date only.
- Long operations: paint the progress UI before the heavy call (`await Future<void>.delayed(Duration.zero)`); JSON encoding with indent stays on the UI isolate (L3 L-09 is not scheduled).
- Dialogs own their controllers; none are needed here since the typed confirmation is dropped.
- Budgets: p90 build and raster under 8 ms, p99 under 16 ms, tab switch under 100 ms; no BackdropFilter; blur toggle default off.
