import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import '../services/google_drive_service.dart';
import 'ledger_provider.dart';
import 'agent_provider.dart';
import 'vehicle_provider.dart';
import 'side_ledger_provider.dart';

/// Sync status for UI display.
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// State for the sync notifier.
class SyncState {
  final SyncStatus status;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  const SyncState({
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.lastSyncTime,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? errorMessage,
    DateTime? lastSyncTime,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// Manages sync operations and exposes status to the UI.
class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  Timer? _periodicTimer;

  SyncNotifier(this._ref) : super(const SyncState()) {
    // Initialize last sync time from storage
    SyncService.initialize();
    state = state.copyWith(lastSyncTime: SyncService.lastSyncTime);
  }

  /// Perform a manual sync and refresh all providers afterward.
  Future<void> syncNow() async {
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing, clearError: true);

    final (result, errorMsg) = await SyncService.sync();

    switch (result) {
      case SyncResult.success:
        state = state.copyWith(
          status: SyncStatus.success,
          lastSyncTime: SyncService.lastSyncTime,
          clearError: true,
        );
        _refreshAllProviders();
        break;
      case SyncResult.noChanges:
        state = state.copyWith(status: SyncStatus.idle, clearError: true);
        break;
      case SyncResult.notSignedIn:
        state = state.copyWith(status: SyncStatus.offline, clearError: true);
        break;
      case SyncResult.error:
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: errorMsg,
        );
        break;
    }

    // Reset to idle after a brief display
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && state.status != SyncStatus.syncing) {
        state = state.copyWith(status: SyncStatus.idle, clearError: true);
      }
    });
  }

  /// Start periodic background sync.
  void startPeriodicSync({Duration interval = const Duration(minutes: 10)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) => syncNow());
  }

  /// Stop periodic sync.
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Refresh all data providers after sync.
  void _refreshAllProviders() {
    _ref.read(ledgerEntriesProvider.notifier).refresh();
    _ref.read(agentsProvider.notifier).refresh();
    _ref.read(vehiclesProvider.notifier).refresh();
    _ref.read(currentVehicleProvider.notifier).refresh();
    _ref.read(dieselEntriesProvider.notifier).refresh();
    _ref.read(pvcEntriesProvider.notifier).refresh();
    _ref.read(bitEntriesProvider.notifier).refresh();
    _ref.read(hammerEntriesProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }
}

/// Global sync provider.
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

/// Whether Google Drive is signed in (convenience).
final isGoogleDriveSignedInProvider = Provider<bool>((ref) {
  return GoogleDriveService.isSignedIn;
});
