# RigLedger - Architecture Reference

## Platform split

```dart
// lib/main.dart
home: PlatformHelper.isDesktop
    ? const DesktopShell()    // macOS: sidebar + custom title bar
    : const MainNavigation(), // Android: bottom nav bar
```

`PlatformHelper.isDesktop` = macOS | Windows | Linux (not kIsWeb).
`PlatformHelper.isAndroid`, `PlatformHelper.isMobile` available.
`PlatformHelper.wideBreakpoint` = 900.0, `PlatformHelper.extraWideBreakpoint` = 1200.0.

## Navigation

No named routes. No go_router.
All screens pushed via `Navigator.push(MaterialPageRoute(...))`.
Top-level split: `DesktopShell` vs `MainNavigation`.
Both use `IndexedStack` of 5 screens: Ledger (0), Stats (1), Agents (2), Account Ledger (3, `CashbookRootScreen`), Settings (4).
Within Ledger: `homeTabIndexProvider` (StateProvider<int>) tracks tab 0=Ledger, 1=Side Ledger.

Desktop nav index: `desktopNavIndexProvider` (StateProvider<int>) -- separate from mobile.

## State management

Riverpod. ProviderScope at root.
Pattern: `StateNotifierProvider<XxxNotifier, List<T>>` for mutable collections.
`Provider<T>` for derived/computed state (filters, stats, grouped entries).
`StateProvider<T>` for ephemeral UI state (selected month, search query, nav index).

All providers are hand-written StateNotifier style. `riverpod_generator` is installed but not used yet.

### Provider locations

```
lib/core/providers/
  ledger_provider.dart      -- ledger entries, filters, time period, stats, phonePeNames
  agent_provider.dart       -- agents list
  vehicle_provider.dart     -- vehicles list, current vehicle
  side_ledger_provider.dart -- diesel, pvc, bit, hammer entries
  sync_provider.dart        -- sync status (SyncNotifier, SyncState, SyncStatus enum)
  cashbook_provider.dart    -- Account Ledger: books, entries, notes, settings, view config, summaries
```

### Adding a new provider

1. Create a `StateNotifier<List<YourModel>>` with `loadXxx()`, `addXxx()`, `updateXxx()`, `deleteXxx()`, `refresh()`.
2. Create a `StateNotifierProvider<XxxNotifier, List<YourModel>>`.
3. If filtered/computed state is needed, add a `Provider<T>` that watches the base provider.
4. Call `DatabaseService.saveXxx()` / `deleteXxx()` from the notifier. Never call DatabaseService from UI.

## Database layer

`DatabaseService` is a static class. All boxes are `late` static fields.
Call `DatabaseService.initialize()` once at startup (done in `main.dart`).
Hive box key for all typed boxes: entity `id` (UUID string).

```
Hive boxes:
  ledger_entries       -> Box<LedgerEntry>
  agents               -> Box<Agent>
  vehicles             -> Box<Vehicle>
  diesel_entries       -> Box<DieselEntry>
  pvc_entries          -> Box<PvcEntry>
  bit_entries          -> Box<BitEntry>
  hammer_entries       -> Box<HammerEntry>
  mini_ledger_entries  -> Box<MiniLedgerEntry>  (orphaned: no screen/provider uses it, see BACKLOG.md)
  cash_books           -> Box<CashBook>         (Account Ledger, global not vehicle-scoped)
  cash_entries         -> Box<CashEntry>
  cash_notes           -> Box<CashNote>
  tombstones           -> Box<Tombstone>
  settings             -> Box<dynamic>   (key-value store)
```

Settings keys: `schemaVersion`, `currentVehicleId`, `lastGoogleDriveBackup`, `autoGoogleDriveBackup`, `lastSyncTime`.

Schema version: 5 (4 added the Account Ledger boxes, 5 added the payment log and commission fields). Migration logic is a stub (_performMigrations bumps version only, no data transforms).

## Google Drive sync

Single file in user's Drive: `RigLedger Backups/rigledger_backup.json`.
Full snapshot of all 11 collections (8 original + cashBooks, cashEntries, cashNotes) + tombstones + version + createdAt. A remote snapshot with a higher `version` than the build is refused.

Bi-directional merge in `SyncService._merge()`:
- Latest `updatedAt` wins for each entity.
- Tombstone beats entity if `tombstone.deletedAt >= entity.updatedAt`.
- Entity re-created after deletion removes the tombstone.
- Tombstones pruned at 30 days.

Auth split:
- Android: `google_sign_in` (Firebase-backed; SHA fingerprint required in Firebase Console).
- macOS: `google_sign_in` native macOS plugin (client ID hardcoded in `google_drive_service.dart` line 24).
- Windows/Linux: `DesktopAuthService` -- browser OAuth flow -- NOT production-ready (placeholder credentials).

Note: `GoogleDriveService._isDesktop` = Windows | Linux ONLY. macOS intentionally uses the mobile path via `google_sign_in`.

Silent sign-in: works on Android and macOS (google_sign_in token persistence). Does NOT work on Windows/Linux (trySignInSilently always returns false; no token storage).

Sync triggers:
- App launch (if signed in).
- App foreground resume.
- Every 5 minutes (mobile: started in RigLedgerApp.initState with Duration(minutes: 5)).
- Every 10 minutes (desktop: started in DesktopShell.initState with default Duration(minutes: 10)).
- Manual: Cmd+S (macOS) / sync indicator tap.

## macOS specifics

Window: 1280x820 default, 900x600 minimum, hidden native title bar.
Custom title bar: 52px gradient, draggable, vehicle switcher, sync indicator.
Keyboard shortcuts: Cmd+1-5 (tabs), Cmd+N (new entry), Cmd+S (sync now). Cmd+F is registered but body is empty (known bug).
Menu bar: RigLedger, File, View, Window menus via `PlatformMenuBar`.

Entitlements (Release): sandbox + network.client + files.user-selected + files.downloads.
Entitlements (Debug): same + network.server + JIT (network.server needed for localhost OAuth redirect in DesktopAuthService).
Distributed as direct .app download (not Mac App Store). Sandbox enabled.

## Android specifics

applicationId: com.rigledger.app
minSdkVersion: flutter default (21)
Orientation locked: portraitUp/portraitDown.
System UI: immersive sticky mode.
Storage: no runtime storage permission is requested on any SDK. Exports use the system file picker (SAF, `FilePicker.saveFile` writes the bytes itself) or Share; `FileSaveService` falls back to Share if the picker fails and encodes text as UTF-8. The manifest keeps only READ_EXTERNAL_STORAGE (maxSdk 32) and WRITE_EXTERNAL_STORAGE (maxSdk 28); MANAGE_EXTERNAL_STORAGE was removed in v2.0.1.

## Riverpod provider refresh pattern

After vehicle switch or sync completes, all providers must be manually refreshed:

```dart
ref.read(ledgerEntriesProvider.notifier).refresh();
ref.read(agentsProvider.notifier).refresh();
ref.read(vehiclesProvider.notifier).refresh();
ref.read(currentVehicleProvider.notifier).refresh();
ref.read(dieselEntriesProvider.notifier).refresh();
ref.read(pvcEntriesProvider.notifier).refresh();
ref.read(bitEntriesProvider.notifier).refresh();
ref.read(hammerEntriesProvider.notifier).refresh();
```

Always include all 8 refresh calls when a full data reload is needed.

## Danger zones

- **`agentName` denormalisation**: stored directly on every `LedgerEntry` and `MiniLedgerEntry`. Renaming an agent requires calling `DatabaseService.updateAgentInLedgerEntries()` before saving the renamed agent -- see `CONVENTIONS.md` "Agent name denormalisation". Skipping either step leaves stale names on existing entries.
- **`received` invariant not enforced**: `LedgerEntry.received` is documented to equal `receivedCash + receivedPhonePe`, but nothing at the DB layer enforces this -- see `MODELS.md`. A bug in any write path can silently desynchronise the two.
- **Sync merge and tombstones**: `SyncService._merge()` resolves conflicts by latest `updatedAt`, with a tombstone beating an entity if `tombstone.deletedAt >= entity.updatedAt`. Tombstones are pruned after 30 days -- a device offline longer than that can resurrect a deleted entity on its next sync.
- **Hive writes during sync**: there is no lock preventing a UI-triggered Hive write while a sync merge is in progress. A write landing mid-merge can be overwritten by the merge or vice versa.
- **macOS Release entitlements**: sandboxed, with only `network.client` (no `network.server`). `DesktopAuthService`'s localhost OAuth redirect needs `network.server`, which is only present in Debug entitlements -- it will not work if ever enabled on macOS Release builds.
- **Never print secrets**: keystore files, `google-services.json`, OAuth client secrets. See `.claude/hooks/pre_read.md`.

## Build runner

Run after any change to a Hive model file (`lib/core/models/*.dart`, not `.g.dart`):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This regenerates `*.g.dart` adapter files. Never edit `*.g.dart` manually.
