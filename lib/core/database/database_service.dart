import 'package:hive_flutter/hive_flutter.dart';
import '../models/ledger_entry.dart';
import '../models/agent.dart';
import '../models/vehicle.dart';
import '../models/diesel_entry.dart';
import '../models/pvc_entry.dart';
import '../models/bit_entry.dart';
import '../models/hammer_entry.dart';
import '../models/mini_ledger_entry.dart';

class DatabaseService {
  static const String ledgerBoxName = 'ledger_entries';
  static const String agentBoxName = 'agents';
  static const String settingsBoxName = 'settings';
  static const String vehicleBoxName = 'vehicles';
  static const String dieselBoxName = 'diesel_entries';
  static const String pvcBoxName = 'pvc_entries';
  static const String bitBoxName = 'bit_entries';
  static const String hammerBoxName = 'hammer_entries';
  static const String miniLedgerBoxName = 'mini_ledger_entries';
  static const int schemaVersion = 2;

  static late Box<LedgerEntry> _ledgerBox;
  static late Box<Agent> _agentBox;
  static late Box<dynamic> _settingsBox;
  static late Box<Vehicle> _vehicleBox;
  static late Box<DieselEntry> _dieselBox;
  static late Box<PvcEntry> _pvcBox;
  static late Box<BitEntry> _bitBox;
  static late Box<HammerEntry> _hammerBox;
  static late Box<MiniLedgerEntry> _miniLedgerBox;

  static Box<LedgerEntry> get ledgerBox => _ledgerBox;
  static Box<Agent> get agentBox => _agentBox;
  static Box<dynamic> get settingsBox => _settingsBox;
  static Box<Vehicle> get vehicleBox => _vehicleBox;
  static Box<DieselEntry> get dieselBox => _dieselBox;
  static Box<PvcEntry> get pvcBox => _pvcBox;
  static Box<BitEntry> get bitBox => _bitBox;
  static Box<HammerEntry> get hammerBox => _hammerBox;
  static Box<MiniLedgerEntry> get miniLedgerBox => _miniLedgerBox;

  static Future<void> initialize() async {
    // Register adapters
    Hive.registerAdapter(LedgerEntryAdapter());
    Hive.registerAdapter(AgentAdapter());
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(DieselEntryAdapter());
    Hive.registerAdapter(PvcEntryAdapter());
    Hive.registerAdapter(BitEntryAdapter());
    Hive.registerAdapter(HammerEntryAdapter());
    Hive.registerAdapter(MiniLedgerEntryAdapter());

    // Open boxes
    _ledgerBox = await Hive.openBox<LedgerEntry>(ledgerBoxName);
    _agentBox = await Hive.openBox<Agent>(agentBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    _vehicleBox = await Hive.openBox<Vehicle>(vehicleBoxName);
    _dieselBox = await Hive.openBox<DieselEntry>(dieselBoxName);
    _pvcBox = await Hive.openBox<PvcEntry>(pvcBoxName);
    _bitBox = await Hive.openBox<BitEntry>(bitBoxName);
    _hammerBox = await Hive.openBox<HammerEntry>(hammerBoxName);
    _miniLedgerBox = await Hive.openBox<MiniLedgerEntry>(miniLedgerBoxName);

    // Check and perform migrations
    await _performMigrations();

    // Ensure at least one default vehicle exists
    await _ensureDefaultVehicle();
  }

  static Future<void> _performMigrations() async {
    final currentVersion =
        _settingsBox.get('schemaVersion', defaultValue: 0) as int;

    if (currentVersion < schemaVersion) {
      // Perform migrations based on version
      // Version 2: Added vehicles and side-ledger

      await _settingsBox.put('schemaVersion', schemaVersion);
    }
  }

  static Future<void> _ensureDefaultVehicle() async {
    if (_vehicleBox.isEmpty) {
      final defaultVehicle = Vehicle(
        id: 'default_vehicle',
        name: 'Main Rig',
        vehicleTypeIndex: 0, // mainBore
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _vehicleBox.put(defaultVehicle.id, defaultVehicle);
      await _settingsBox.put('currentVehicleId', defaultVehicle.id);
    }
  }

  // Current Vehicle
  static String get currentVehicleId {
    return _settingsBox.get('currentVehicleId', defaultValue: 'default_vehicle')
        as String;
  }

  static Future<void> setCurrentVehicle(String vehicleId) async {
    await _settingsBox.put('currentVehicleId', vehicleId);
  }

  static Vehicle? getCurrentVehicle() {
    return _vehicleBox.get(currentVehicleId);
  }

  // Vehicle Operations
  static Future<void> saveVehicle(Vehicle vehicle) async {
    await _vehicleBox.put(vehicle.id, vehicle);
  }

  static Future<void> deleteVehicle(String id) async {
    // Don't delete if it's the only vehicle
    if (_vehicleBox.length <= 1) return;

    // Delete all associated data
    await _deleteSideLedgerByVehicle(id);
    await _deleteMiniLedgerByVehicle(id);
    await _vehicleBox.delete(id);

    // If deleting current vehicle, switch to first available
    if (currentVehicleId == id) {
      final firstVehicle = _vehicleBox.values.first;
      await setCurrentVehicle(firstVehicle.id);
    }
  }

  static Vehicle? getVehicle(String id) {
    return _vehicleBox.get(id);
  }

  static List<Vehicle> getAllVehicles() {
    return _vehicleBox.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // Ledger Entry Operations
  static Future<void> saveLedgerEntry(LedgerEntry entry) async {
    await _ledgerBox.put(entry.id, entry);
  }

  static Future<void> deleteLedgerEntry(String id) async {
    await _ledgerBox.delete(id);
  }

  static LedgerEntry? getLedgerEntry(String id) {
    return _ledgerBox.get(id);
  }

  static List<LedgerEntry> getAllLedgerEntries() {
    final vehicleId = currentVehicleId;
    return _ledgerBox.values.where((e) => e.vehicleId == vehicleId).toList();
  }

  static List<LedgerEntry> getLedgerEntriesByMonth(int year, int month) {
    final vehicleId = currentVehicleId;
    return _ledgerBox.values.where((entry) {
      return entry.vehicleId == vehicleId &&
          entry.date.year == year &&
          entry.date.month == month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<LedgerEntry> getLedgerEntriesByDateRange(
      DateTime start, DateTime end) {
    final vehicleId = currentVehicleId;
    return _ledgerBox.values.where((entry) {
      return entry.vehicleId == vehicleId &&
          !entry.date.isBefore(start) &&
          !entry.date.isAfter(end);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<LedgerEntry> getLedgerEntriesByAgent(String agentId) {
    final vehicleId = currentVehicleId;
    return _ledgerBox.values
        .where(
            (entry) => entry.vehicleId == vehicleId && entry.agentId == agentId)
        .toList();
  }

  static List<LedgerEntry> searchLedgerEntries(String query) {
    final vehicleId = currentVehicleId;
    final lowerQuery = query.toLowerCase();
    return _ledgerBox.values.where((entry) {
      return entry.vehicleId == vehicleId &&
          (entry.billNumber.toLowerCase().contains(lowerQuery) ||
              entry.address.toLowerCase().contains(lowerQuery) ||
              entry.agentName.toLowerCase().contains(lowerQuery) ||
              (entry.notes?.toLowerCase().contains(lowerQuery) ?? false));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get all unique addresses from ledger entries for current vehicle
  static List<String> getUniqueAddresses() {
    final vehicleId = currentVehicleId;
    final addresses = _ledgerBox.values
        .where((entry) => entry.vehicleId == vehicleId)
        .map((entry) => entry.address.trim())
        .where((address) => address.isNotEmpty)
        .toSet()
        .toList();
    addresses.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return addresses;
  }

  // Agent Operations
  static Future<void> saveAgent(Agent agent) async {
    await _agentBox.put(agent.id, agent);
  }

  static Future<void> deleteAgent(String id) async {
    await _agentBox.delete(id);
  }

  static Agent? getAgent(String id) {
    return _agentBox.get(id);
  }

  static List<Agent> getAllAgents() {
    final vehicleId = currentVehicleId;
    return _agentBox.values.where((a) => a.vehicleId == vehicleId).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static Agent? getAgentByName(String name) {
    final vehicleId = currentVehicleId;
    try {
      return _agentBox.values.firstWhere(
        (agent) =>
            agent.vehicleId == vehicleId &&
            agent.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static int getAgentBillCount(String agentId) {
    final vehicleId = currentVehicleId;
    return _ledgerBox.values
        .where(
            (entry) => entry.vehicleId == vehicleId && entry.agentId == agentId)
        .length;
  }

  static Future<void> updateAgentInLedgerEntries(
      String agentId, String newAgentName) async {
    final entries = getLedgerEntriesByAgent(agentId);
    for (final entry in entries) {
      final updated =
          entry.copyWith(agentName: newAgentName, updatedAt: DateTime.now());
      await saveLedgerEntry(updated);
    }
  }

  static Future<void> reassignLedgerEntries(
      String fromAgentId, String toAgentId, String toAgentName) async {
    final entries = getLedgerEntriesByAgent(fromAgentId);
    for (final entry in entries) {
      final updated = entry.copyWith(
        agentId: toAgentId,
        agentName: toAgentName,
        updatedAt: DateTime.now(),
      );
      await saveLedgerEntry(updated);
    }
  }

  static Future<void> deleteLedgerEntriesByAgent(String agentId) async {
    final entries = getLedgerEntriesByAgent(agentId);
    for (final entry in entries) {
      await deleteLedgerEntry(entry.id);
    }
  }

  // Backup and Restore
  static Future<Map<String, dynamic>> createBackup() async {
    // Get ALL data from all vehicles, not just current vehicle
    final ledgerEntries = _ledgerBox.values.map((e) => e.toMap()).toList();
    final agents = _agentBox.values.map((a) => a.toMap()).toList();
    final vehicles = _vehicleBox.values.map((v) => v.toJson()).toList();
    final dieselEntries = _dieselBox.values.map((e) => e.toJson()).toList();
    final pvcEntries = _pvcBox.values.map((e) => e.toJson()).toList();
    final bitEntries = _bitBox.values.map((e) => e.toJson()).toList();
    final hammerEntries = _hammerBox.values.map((e) => e.toJson()).toList();
    final miniLedgerEntries =
        _miniLedgerBox.values.map((e) => e.toJson()).toList();

    // Also save current vehicle selection
    final currentVehicle = currentVehicleId;

    return {
      'version': schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'currentVehicleId': currentVehicle,
      'ledgerEntries': ledgerEntries,
      'agents': agents,
      'vehicles': vehicles,
      'dieselEntries': dieselEntries,
      'pvcEntries': pvcEntries,
      'bitEntries': bitEntries,
      'hammerEntries': hammerEntries,
      'miniLedgerEntries': miniLedgerEntries,
    };
  }

  static Future<void> restoreBackup(Map<String, dynamic> backup) async {
    // Clear existing data without creating default vehicle
    await _clearAllDataForRestore();

    // Restore vehicles first
    final vehiclesData = backup['vehicles'] as List<dynamic>? ?? [];
    for (final vehicleMap in vehiclesData) {
      final vehicle = Vehicle.fromJson(Map<String, dynamic>.from(vehicleMap));
      await saveVehicle(vehicle);
    }

    // Restore agents
    final agentsData = backup['agents'] as List<dynamic>? ?? [];
    for (final agentMap in agentsData) {
      final agent = Agent.fromMap(Map<String, dynamic>.from(agentMap));
      await saveAgent(agent);
    }

    // Restore ledger entries
    final entriesData = backup['ledgerEntries'] as List<dynamic>? ?? [];
    for (final entryMap in entriesData) {
      final entry = LedgerEntry.fromMap(Map<String, dynamic>.from(entryMap));
      await saveLedgerEntry(entry);
    }

    // Restore diesel entries
    final dieselData = backup['dieselEntries'] as List<dynamic>? ?? [];
    for (final entryMap in dieselData) {
      final entry = DieselEntry.fromJson(Map<String, dynamic>.from(entryMap));
      await saveDieselEntry(entry);
    }

    // Restore PVC entries
    final pvcData = backup['pvcEntries'] as List<dynamic>? ?? [];
    for (final entryMap in pvcData) {
      final entry = PvcEntry.fromJson(Map<String, dynamic>.from(entryMap));
      await savePvcEntry(entry);
    }

    // Restore bit entries
    final bitData = backup['bitEntries'] as List<dynamic>? ?? [];
    for (final entryMap in bitData) {
      final entry = BitEntry.fromJson(Map<String, dynamic>.from(entryMap));
      await saveBitEntry(entry);
    }

    // Restore hammer entries
    final hammerData = backup['hammerEntries'] as List<dynamic>? ?? [];
    for (final entryMap in hammerData) {
      final entry = HammerEntry.fromJson(Map<String, dynamic>.from(entryMap));
      await saveHammerEntry(entry);
    }

    // Restore mini ledger entries
    final miniLedgerData = backup['miniLedgerEntries'] as List<dynamic>? ?? [];
    for (final entryMap in miniLedgerData) {
      final entry =
          MiniLedgerEntry.fromJson(Map<String, dynamic>.from(entryMap));
      await saveMiniLedgerEntry(entry);
    }

    // Ensure default vehicle exists
    await _ensureDefaultVehicle();

    // Restore the current vehicle selection if it exists in the backup
    final savedCurrentVehicle = backup['currentVehicleId'] as String?;
    if (savedCurrentVehicle != null &&
        _vehicleBox.containsKey(savedCurrentVehicle)) {
      await setCurrentVehicle(savedCurrentVehicle);
    }
  }

  static Future<void> clearAllData() async {
    await _ledgerBox.clear();
    await _agentBox.clear();
    await _vehicleBox.clear();
    await _dieselBox.clear();
    await _pvcBox.clear();
    await _bitBox.clear();
    await _hammerBox.clear();
    await _miniLedgerBox.clear();
    await _settingsBox.delete('currentVehicleId');
    // Recreate default vehicle after clearing (for normal clear, not restore)
    await _ensureDefaultVehicle();
  }

  /// Clear all data without creating default vehicle (used during restore)
  static Future<void> _clearAllDataForRestore() async {
    await _ledgerBox.clear();
    await _agentBox.clear();
    await _vehicleBox.clear();
    await _dieselBox.clear();
    await _pvcBox.clear();
    await _bitBox.clear();
    await _hammerBox.clear();
    await _miniLedgerBox.clear();
    await _settingsBox.delete('currentVehicleId');
  }

  // ============ DIESEL OPERATIONS ============
  static Future<void> saveDieselEntry(DieselEntry entry) async {
    await _dieselBox.put(entry.id, entry);
  }

  static Future<void> deleteDieselEntry(String id) async {
    await _dieselBox.delete(id);
  }

  static List<DieselEntry> getAllDieselEntries() {
    return _dieselBox.values.toList();
  }

  static List<DieselEntry> getDieselEntriesByVehicle(String vehicleId) {
    return _dieselBox.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<DieselEntry> getDieselEntriesByDateRange(
      String vehicleId, DateTime start, DateTime end) {
    return _dieselBox.values
        .where((e) =>
            e.vehicleId == vehicleId &&
            !e.date.isBefore(start) &&
            !e.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ PVC OPERATIONS ============
  static Future<void> savePvcEntry(PvcEntry entry) async {
    await _pvcBox.put(entry.id, entry);
  }

  static Future<void> deletePvcEntry(String id) async {
    await _pvcBox.delete(id);
  }

  static List<PvcEntry> getAllPvcEntries() {
    return _pvcBox.values.toList();
  }

  static List<PvcEntry> getPvcEntriesByVehicle(String vehicleId) {
    return _pvcBox.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<PvcEntry> getPvcEntriesByDateRange(
      String vehicleId, DateTime start, DateTime end) {
    return _pvcBox.values
        .where((e) =>
            e.vehicleId == vehicleId &&
            !e.date.isBefore(start) &&
            !e.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ BIT OPERATIONS ============
  static Future<void> saveBitEntry(BitEntry entry) async {
    await _bitBox.put(entry.id, entry);
  }

  static Future<void> deleteBitEntry(String id) async {
    await _bitBox.delete(id);
  }

  static List<BitEntry> getAllBitEntries() {
    return _bitBox.values.toList();
  }

  static List<BitEntry> getBitEntriesByVehicle(String vehicleId) {
    return _bitBox.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<BitEntry> getBitEntriesByDateRange(
      String vehicleId, DateTime start, DateTime end) {
    return _bitBox.values
        .where((e) =>
            e.vehicleId == vehicleId &&
            !e.date.isBefore(start) &&
            !e.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ HAMMER OPERATIONS ============
  static Future<void> saveHammerEntry(HammerEntry entry) async {
    await _hammerBox.put(entry.id, entry);
  }

  static Future<void> deleteHammerEntry(String id) async {
    await _hammerBox.delete(id);
  }

  static List<HammerEntry> getAllHammerEntries() {
    return _hammerBox.values.toList();
  }

  static List<HammerEntry> getHammerEntriesByVehicle(String vehicleId) {
    return _hammerBox.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<HammerEntry> getHammerEntriesByDateRange(
      String vehicleId, DateTime start, DateTime end) {
    return _hammerBox.values
        .where((e) =>
            e.vehicleId == vehicleId &&
            !e.date.isBefore(start) &&
            !e.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ MINI LEDGER OPERATIONS ============
  static Future<void> saveMiniLedgerEntry(MiniLedgerEntry entry) async {
    await _miniLedgerBox.put(entry.id, entry);
  }

  static Future<void> deleteMiniLedgerEntry(String id) async {
    await _miniLedgerBox.delete(id);
  }

  static List<MiniLedgerEntry> getAllMiniLedgerEntries() {
    return _miniLedgerBox.values.toList();
  }

  static List<MiniLedgerEntry> getMiniLedgerEntriesByVehicle(String vehicleId) {
    return _miniLedgerBox.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<MiniLedgerEntry> getMiniLedgerEntriesByDateRange(
      String vehicleId, DateTime start, DateTime end) {
    return _miniLedgerBox.values
        .where((e) =>
            e.vehicleId == vehicleId &&
            !e.date.isBefore(start) &&
            !e.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ HELPER METHODS ============
  static Future<void> _deleteSideLedgerByVehicle(String vehicleId) async {
    // Delete diesel entries
    final dieselEntries = getDieselEntriesByVehicle(vehicleId);
    for (final entry in dieselEntries) {
      await deleteDieselEntry(entry.id);
    }
    // Delete PVC entries
    final pvcEntries = getPvcEntriesByVehicle(vehicleId);
    for (final entry in pvcEntries) {
      await deletePvcEntry(entry.id);
    }
    // Delete bit entries
    final bitEntries = getBitEntriesByVehicle(vehicleId);
    for (final entry in bitEntries) {
      await deleteBitEntry(entry.id);
    }
    // Delete hammer entries
    final hammerEntries = getHammerEntriesByVehicle(vehicleId);
    for (final entry in hammerEntries) {
      await deleteHammerEntry(entry.id);
    }
  }

  static Future<void> _deleteMiniLedgerByVehicle(String vehicleId) async {
    final entries = getMiniLedgerEntriesByVehicle(vehicleId);
    for (final entry in entries) {
      await deleteMiniLedgerEntry(entry.id);
    }
  }

  // Statistics
  static Map<String, double> getMonthlyStats(int year, int month) {
    final entries = getLedgerEntriesByMonth(year, month);
    double total = 0;
    double received = 0;
    double balance = 0;

    for (final entry in entries) {
      total += entry.total;
      received += entry.received;
      balance += entry.balance;
    }

    return {
      'total': total,
      'received': received,
      'balance': balance,
    };
  }

  static Map<String, double> getAgentWiseTotals(
      {DateTime? startDate, DateTime? endDate}) {
    List<LedgerEntry> entries;
    if (startDate != null && endDate != null) {
      entries = getLedgerEntriesByDateRange(startDate, endDate);
    } else {
      entries = getAllLedgerEntries();
    }

    final Map<String, double> agentTotals = {};
    for (final entry in entries) {
      agentTotals[entry.agentName] =
          (agentTotals[entry.agentName] ?? 0) + entry.total;
    }
    return agentTotals;
  }
}
