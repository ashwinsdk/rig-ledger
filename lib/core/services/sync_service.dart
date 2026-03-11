import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../models/ledger_entry.dart';
import '../models/agent.dart';
import '../models/vehicle.dart';
import '../models/diesel_entry.dart';
import '../models/pvc_entry.dart';
import '../models/bit_entry.dart';
import '../models/hammer_entry.dart';
import '../models/mini_ledger_entry.dart';
import '../models/tombstone.dart';
import 'google_drive_service.dart';

/// The result of a sync operation.
enum SyncResult {
  /// Sync completed, data merged successfully.
  success,

  /// No changes needed (local and remote are identical).
  noChanges,

  /// Sync failed.
  error,

  /// Not signed in to Google Drive.
  notSignedIn,
}

/// Cross-device sync service using Google Drive as the transport layer.
///
/// Algorithm:
///   1. Pull remote snapshot from Google Drive.
///   2. Merge remote data into local data:
///      - For each entity: keep the one with the latest `updatedAt`.
///      - Honour tombstones: if an entity was deleted on either side,
///        the deletion wins if the tombstone's `deletedAt` > entity's `updatedAt`.
///      - Entities not present on either side are simply added.
///   3. Push the merged snapshot back to Google Drive.
///   4. Refresh all Riverpod providers.
class SyncService {
  SyncService._();

  static bool _isSyncing = false;
  static DateTime? _lastSyncTime;
  static Timer? _periodicTimer;

  /// Whether a sync is currently in progress.
  static bool get isSyncing => _isSyncing;

  /// When the last successful sync happened.
  static DateTime? get lastSyncTime => _lastSyncTime;

  // ─── Public API ───────────────────────────────────────────────────────

  /// Perform a full bi-directional sync.
  ///
  /// Returns (`SyncResult`, optional error message).
  static Future<(SyncResult, String?)> sync() async {
    if (_isSyncing) return (SyncResult.noChanges, 'Sync already in progress');
    if (!GoogleDriveService.isSignedIn) return (SyncResult.notSignedIn, null);

    _isSyncing = true;
    try {
      // 1. Create local snapshot
      final localSnapshot = await DatabaseService.createBackup();

      // 2. Pull remote snapshot
      final remoteSnapshot = await GoogleDriveService.restore();

      Map<String, dynamic> mergedSnapshot;

      if (remoteSnapshot == null) {
        // First sync ever — just push local data
        mergedSnapshot = localSnapshot;
      } else {
        // 3. Merge
        mergedSnapshot = _merge(localSnapshot, remoteSnapshot);
      }

      // 4. Restore merged snapshot locally
      await DatabaseService.restoreBackup(mergedSnapshot);

      // 5. Restore tombstones
      final tombstoneData =
          mergedSnapshot['tombstones'] as List<dynamic>? ?? [];
      await DatabaseService.clearTombstones();
      for (final tj in tombstoneData) {
        final t = Tombstone.fromJson(Map<String, dynamic>.from(tj));
        await DatabaseService.tombstoneBox.put(t.entityId, t);
      }

      // 6. Push merged snapshot to remote
      final (pushOk, pushErr) = await GoogleDriveService.backup();
      if (!pushOk) {
        return (SyncResult.error, 'Failed to push: $pushErr');
      }

      // 7. Prune old tombstones (30 days)
      await DatabaseService.pruneTombstones();

      _lastSyncTime = DateTime.now();
      await DatabaseService.settingsBox
          .put('lastSyncTime', _lastSyncTime!.toIso8601String());

      debugPrint('[Sync] Completed successfully at $_lastSyncTime');
      return (SyncResult.success, null);
    } catch (e, st) {
      debugPrint('[Sync] Error: $e\n$st');
      return (SyncResult.error, e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Start periodic sync (every N minutes). Call once from main().
  static void startPeriodicSync(
      {Duration interval = const Duration(minutes: 10)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) async {
      if (GoogleDriveService.isSignedIn) {
        await sync();
      }
    });
  }

  /// Stop periodic sync.
  static void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Initialize from stored last sync time.
  static void initialize() {
    final stored = DatabaseService.settingsBox.get('lastSyncTime');
    if (stored != null) {
      _lastSyncTime = DateTime.tryParse(stored);
    }
  }

  // ─── Merge Logic ──────────────────────────────────────────────────────

  /// Merge two full backup snapshots, producing a merged snapshot.
  ///
  /// For each collection we:
  ///   - Build a combined set of all entity IDs from both sides.
  ///   - Collect tombstones from both sides.
  ///   - For each entity:
  ///       • If tombstoned and tombstone.deletedAt >= entity.updatedAt → skip.
  ///       • If present on both sides → keep the one with the latest updatedAt.
  ///       • If present on one side only → add it (unless tombstoned).
  static Map<String, dynamic> _merge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Build combined tombstone set
    final localTombstones = _parseTombstones(local['tombstones']);
    final remoteTombstones = _parseTombstones(remote['tombstones']);
    final allTombstones = _mergeTombstones(localTombstones, remoteTombstones);

    // Keep track of merged tombstone list
    final tombstoneMap = <String, Tombstone>{};
    for (final t in allTombstones) {
      tombstoneMap[t.entityId] = t;
    }

    return {
      'version': DatabaseService.schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'currentVehicleId': local['currentVehicleId'] ??
          remote['currentVehicleId'] ??
          'default_vehicle',
      'vehicles': _mergeCollection(
        localItems: local['vehicles'] ?? [],
        remoteItems: remote['vehicles'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'agents': _mergeCollection(
        localItems: local['agents'] ?? [],
        remoteItems: remote['agents'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'ledgerEntries': _mergeCollection(
        localItems: local['ledgerEntries'] ?? [],
        remoteItems: remote['ledgerEntries'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'dieselEntries': _mergeCollection(
        localItems: local['dieselEntries'] ?? [],
        remoteItems: remote['dieselEntries'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'pvcEntries': _mergeCollection(
        localItems: local['pvcEntries'] ?? [],
        remoteItems: remote['pvcEntries'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'bitEntries': _mergeCollection(
        localItems: local['bitEntries'] ?? [],
        remoteItems: remote['bitEntries'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'hammerEntries': _mergeCollection(
        localItems: local['hammerEntries'] ?? [],
        remoteItems: remote['hammerEntries'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'miniLedgerEntries': _mergeCollection(
        localItems: local['miniLedgerEntries'] ?? [],
        remoteItems: remote['miniLedgerEntries'] ?? [],
        tombstones: tombstoneMap,
        getId: (m) => m['id'] as String,
        getUpdatedAt: (m) => DateTime.parse(m['updatedAt'] as String),
      ),
      'tombstones': allTombstones.map((t) => t.toJson()).toList(),
    };
  }

  /// Generic merge for a single collection of JSON maps.
  static List<Map<String, dynamic>> _mergeCollection({
    required List<dynamic> localItems,
    required List<dynamic> remoteItems,
    required Map<String, Tombstone> tombstones,
    required String Function(Map<String, dynamic>) getId,
    required DateTime Function(Map<String, dynamic>) getUpdatedAt,
  }) {
    // Index both sides by ID
    final localById = <String, Map<String, dynamic>>{};
    for (final item in localItems) {
      final m = Map<String, dynamic>.from(item);
      localById[getId(m)] = m;
    }

    final remoteById = <String, Map<String, dynamic>>{};
    for (final item in remoteItems) {
      final m = Map<String, dynamic>.from(item);
      remoteById[getId(m)] = m;
    }

    // Union of all IDs
    final allIds = {...localById.keys, ...remoteById.keys};
    final merged = <Map<String, dynamic>>[];

    for (final id in allIds) {
      final tombstone = tombstones[id];
      final localItem = localById[id];
      final remoteItem = remoteById[id];

      // Pick the candidate with the latest updatedAt
      Map<String, dynamic>? winner;
      if (localItem != null && remoteItem != null) {
        final localTime = getUpdatedAt(localItem);
        final remoteTime = getUpdatedAt(remoteItem);
        winner = remoteTime.isAfter(localTime) ? remoteItem : localItem;
      } else {
        winner = localItem ?? remoteItem;
      }

      if (winner == null) continue;

      // Check tombstone
      if (tombstone != null) {
        final entityUpdated = getUpdatedAt(winner);
        if (!entityUpdated.isAfter(tombstone.deletedAt)) {
          // Tombstone wins — entity stays deleted
          continue;
        }
        // Entity was re-created after deletion — keep it and remove tombstone
        tombstones.remove(id);
      }

      merged.add(winner);
    }

    return merged;
  }

  // ─── Tombstone Helpers ────────────────────────────────────────────────

  static List<Tombstone> _parseTombstones(dynamic data) {
    if (data == null) return [];
    return (data as List<dynamic>)
        .map((e) => Tombstone.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Merge two lists of tombstones, keeping the latest for each entityId.
  static List<Tombstone> _mergeTombstones(
    List<Tombstone> a,
    List<Tombstone> b,
  ) {
    final map = <String, Tombstone>{};
    for (final t in a) {
      map[t.entityId] = t;
    }
    for (final t in b) {
      final existing = map[t.entityId];
      if (existing == null || t.deletedAt.isAfter(existing.deletedAt)) {
        map[t.entityId] = t;
      }
    }
    return map.values.toList();
  }
}
