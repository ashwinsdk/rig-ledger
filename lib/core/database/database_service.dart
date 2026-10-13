import 'package:hive_flutter/hive_flutter.dart';
import '../models/ledger_entry.dart';
import '../models/agent.dart';
import '../models/vehicle.dart';
import '../models/diesel_entry.dart';
import '../models/pvc_entry.dart';
import '../models/bit_entry.dart';
import '../models/hammer_entry.dart';
import '../models/other_expense_entry.dart';
import '../models/mini_ledger_entry.dart';
import '../models/tombstone.dart';
import '../models/cash_book.dart';
import '../models/cash_entry.dart';
import '../models/cash_note.dart';
import '../models/ledger_types.dart';

class DatabaseService {
  static const String ledgerBoxName = 'ledger_entries';
  static const String agentBoxName = 'agents';
  static const String settingsBoxName = 'settings';
  static const String vehicleBoxName = 'vehicles';
  static const String dieselBoxName = 'diesel_entries';
  static const String pvcBoxName = 'pvc_entries';
  static const String bitBoxName = 'bit_entries';
  static const String hammerBoxName = 'hammer_entries';
  static const String otherExpenseBoxName = 'other_expense_entries';
  static const String miniLedgerBoxName = 'mini_ledger_entries';
  static const String tombstoneBoxName = 'tombstones';
  static const String cashBookBoxName = 'cash_books';
  static const String cashEntryBoxName = 'cash_entries';
  static const String cashNoteBoxName = 'cash_notes';
  static const String defaultCashBookId = 'default_cash_book';
  static const Duration cashTrashRetention = Duration(days: 30);
  static const int schemaVersion = 6;

  static late Box<LedgerEntry> _ledgerBox;
  static late Box<Agent> _agentBox;
  static late Box<dynamic> _settingsBox;
  static late Box<Vehicle> _vehicleBox;
  static late Box<DieselEntry> _dieselBox;
  static late Box<PvcEntry> _pvcBox;
  static late Box<BitEntry> _bitBox;
  static late Box<HammerEntry> _hammerBox;
  static late Box<OtherExpenseEntry> _otherExpenseBox;
  static late Box<MiniLedgerEntry> _miniLedgerBox;
  static late Box<Tombstone> _tombstoneBox;
  static late Box<CashBook> _cashBookBox;
  static late Box<CashEntry> _cashEntryBox;
  static late Box<CashNote> _cashNoteBox;

  static Box<LedgerEntry> get ledgerBox => _ledgerBox;
  static Box<Agent> get agentBox => _agentBox;
  static Box<dynamic> get settingsBox => _settingsBox;
  static Box<Vehicle> get vehicleBox => _vehicleBox;
  static Box<DieselEntry> get dieselBox => _dieselBox;
  static Box<PvcEntry> get pvcBox => _pvcBox;
  static Box<BitEntry> get bitBox => _bitBox;
  static Box<HammerEntry> get hammerBox => _hammerBox;
  static Box<OtherExpenseEntry> get otherExpenseBox => _otherExpenseBox;
  static Box<MiniLedgerEntry> get miniLedgerBox => _miniLedgerBox;
  static Box<Tombstone> get tombstoneBox => _tombstoneBox;
  static Box<CashBook> get cashBookBox => _cashBookBox;
  static Box<CashEntry> get cashEntryBox => _cashEntryBox;
  static Box<CashNote> get cashNoteBox => _cashNoteBox;

  static Future<void> initialize() async {
    // Register adapters
    Hive.registerAdapter(LedgerEntryAdapter());
    Hive.registerAdapter(AgentAdapter());
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(DieselEntryAdapter());
    Hive.registerAdapter(PvcEntryAdapter());
    Hive.registerAdapter(BitEntryAdapter());
    Hive.registerAdapter(HammerEntryAdapter());
    Hive.registerAdapter(OtherExpenseEntryAdapter());
    Hive.registerAdapter(MiniLedgerEntryAdapter());
    Hive.registerAdapter(TombstoneAdapter());
    Hive.registerAdapter(CashBookAdapter());
    Hive.registerAdapter(CashEntryAdapter());
    Hive.registerAdapter(CashNoteAdapter());

    // Open boxes
    _ledgerBox = await Hive.openBox<LedgerEntry>(ledgerBoxName);
    _agentBox = await Hive.openBox<Agent>(agentBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    _vehicleBox = await Hive.openBox<Vehicle>(vehicleBoxName);
    _dieselBox = await Hive.openBox<DieselEntry>(dieselBoxName);
    _pvcBox = await Hive.openBox<PvcEntry>(pvcBoxName);
    _bitBox = await Hive.openBox<BitEntry>(bitBoxName);
    _hammerBox = await Hive.openBox<HammerEntry>(hammerBoxName);
    _otherExpenseBox =
        await Hive.openBox<OtherExpenseEntry>(otherExpenseBoxName);
    _miniLedgerBox = await Hive.openBox<MiniLedgerEntry>(miniLedgerBoxName);
    _tombstoneBox = await Hive.openBox<Tombstone>(tombstoneBoxName);
    _cashBookBox = await Hive.openBox<CashBook>(cashBookBoxName);
    _cashEntryBox = await Hive.openBox<CashEntry>(cashEntryBoxName);
    _cashNoteBox = await Hive.openBox<CashNote>(cashNoteBoxName);

    // Check and perform migrations
    await _performMigrations();

    // Ensure at least one default vehicle exists
    await _ensureDefaultVehicle();

    // Account Ledger: default book and 30 day trash purge
    await _ensureDefaultCashBook();
    await purgeExpiredCashTrash();
  }

  static Future<void> _performMigrations() async {
    final currentVersion =
        _settingsBox.get('schemaVersion', defaultValue: 0) as int;

    if (currentVersion < schemaVersion) {
      // Perform migrations based on version
      // Version 2: Added vehicles and side-ledger
      // Version 4: Added Account Ledger boxes (cash_books, cash_entries,
      // cash_notes). New boxes start empty, so no data transform is needed.
      // Version 5: LedgerEntry payment log + commission fields and Agent
      // default commission rates. New fields default to empty/0 on old data
      // (Hive defaultValue and fromMap defaults), so no transform is needed.
      // Version 6 (v2.0.1): user-defined ledger types (settings key
      // `ledgerTypes`, absent means the built-in lists) and, later in the same
      // version, new Agent and Other expenses data. All default safely.

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

    // Delete all associated data (the confirmation dialog promises ledger
    // entries, side ledger data and agents of this vehicle).
    for (final entry
        in _ledgerBox.values.where((e) => e.vehicleId == id).toList()) {
      await deleteLedgerEntry(entry.id);
    }
    for (final agent
        in _agentBox.values.where((a) => a.vehicleId == id).toList()) {
      await deleteAgent(agent.id);
    }
    await _deleteSideLedgerByVehicle(id);
    await _deleteMiniLedgerByVehicle(id);
    await recordTombstone(id, vehicleBoxName);
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
    await recordTombstone(id, ledgerBoxName);
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
    await recordTombstone(id, agentBoxName);
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

  // ============ LEDGER TYPES (user-defined depth, PVC, MS pipe types) ============

  static LedgerTypes getLedgerTypes() {
    final raw = _settingsBox.get('ledgerTypes');
    return raw == null ? LedgerTypes.defaults() : LedgerTypes.fromJson(raw);
  }

  static Future<void> saveLedgerTypes(LedgerTypes types) =>
      _settingsBox.put('ledgerTypes', types.encode());

  /// Bills of main bore rigs, across all rigs. Side bore bills carry placeholder
  /// types (7inch, 6inch) that mean nothing, so they never count as using a type.
  static Iterable<LedgerEntry> _mainBoreBills() {
    final mainIds = _vehicleBox.values
        .where((v) => v.vehicleType == VehicleType.mainBore)
        .map((v) => v.id)
        .toSet();
    return _ledgerBox.values.where((e) => mainIds.contains(e.vehicleId));
  }

  static String _billType(LedgerEntry e, LedgerTypeCategory c) => switch (c) {
        LedgerTypeCategory.depth => e.depth,
        LedgerTypeCategory.pvc => e.pvc,
        LedgerTypeCategory.ms => e.msPipe,
      };

  /// How many bills use [type] in category [c].
  static int countBillsWithType(LedgerTypeCategory c, String type) =>
      _mainBoreBills().where((e) => _billType(e, c) == type).length;

  /// Types that bills actually use (a type may be missing from the list after a
  /// sync of an older device).
  static Set<String> usedLedgerTypes(LedgerTypeCategory c) => _mainBoreBills()
      .map((e) => _billType(e, c))
      .where((t) => t.isNotEmpty)
      .toSet();

  /// Renames a type on every bill that uses it. Returns how many bills changed.
  static Future<int> renameBillType(
      LedgerTypeCategory c, String from, String to) async {
    final bills =
        _mainBoreBills().where((e) => _billType(e, c) == from).toList();
    final now = DateTime.now();
    for (final b in bills) {
      final updated = switch (c) {
        LedgerTypeCategory.depth => b.copyWith(depth: to, updatedAt: now),
        LedgerTypeCategory.pvc => b.copyWith(pvc: to, updatedAt: now),
        LedgerTypeCategory.ms => b.copyWith(msPipe: to, updatedAt: now),
      };
      await saveLedgerEntry(updated);
    }
    return bills.length;
  }

  /// Moves an agent price from the old type name to the new one (rename).
  static Future<void> renameAgentRateType(
      LedgerTypeCategory c, String from, String to) async {
    final fromKey = Agent.rateKey(c.name, from);
    final toKey = Agent.rateKey(c.name, to);
    for (final agent in _agentBox.values.toList()) {
      final rates = agent.commissionRates;
      if (!rates.containsKey(fromKey)) continue;
      rates[toKey] = rates.remove(fromKey)!;
      await saveAgent(agent.copyWith(
          commissionRatesJson: Agent.encodeRates(rates),
          updatedAt: DateTime.now()));
    }
  }

  /// Drops every agent price of a deleted type.
  static Future<void> removeAgentRateType(
      LedgerTypeCategory c, String type) async {
    final key = Agent.rateKey(c.name, type);
    for (final agent in _agentBox.values.toList()) {
      final rates = agent.commissionRates;
      if (rates.remove(key) == null) continue;
      await saveAgent(agent.copyWith(
          commissionRatesJson: Agent.encodeRates(rates),
          updatedAt: DateTime.now()));
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
    final otherExpenseEntries =
        _otherExpenseBox.values.map((e) => e.toJson()).toList();
    final miniLedgerEntries =
        _miniLedgerBox.values.map((e) => e.toJson()).toList();

    final cashBooks = _cashBookBox.values.map((b) => b.toJson()).toList();
    final cashEntries = _cashEntryBox.values.map((e) => e.toJson()).toList();
    final cashNotes = _cashNoteBox.values.map((n) => n.toJson()).toList();

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
      'otherExpenseEntries': otherExpenseEntries,
      'miniLedgerEntries': miniLedgerEntries,
      'cashBooks': cashBooks,
      'cashEntries': cashEntries,
      'cashNotes': cashNotes,
      'ledgerTypes': getLedgerTypes().toJson(),
      'tombstones': _tombstoneBox.values.map((t) => t.toJson()).toList(),
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

    // Restore other expense entries (missing in backups before 2.0.1)
    final otherData = backup['otherExpenseEntries'] as List<dynamic>? ?? [];
    for (final entryMap in otherData) {
      final entry =
          OtherExpenseEntry.fromJson(Map<String, dynamic>.from(entryMap));
      await saveOtherExpenseEntry(entry);
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

    // Ledger types (absent in backups from older versions: keep the local lists)
    final ledgerTypesData = backup['ledgerTypes'];
    if (ledgerTypesData != null) {
      await saveLedgerTypes(LedgerTypes.fromJson(ledgerTypesData));
    }

    // Restore Account Ledger (keys are absent in backups from older versions)
    final cashBooksData = backup['cashBooks'] as List<dynamic>? ?? [];
    for (final map in cashBooksData) {
      final book = CashBook.fromJson(Map<String, dynamic>.from(map));
      await _cashBookBox.put(book.id, book);
    }
    final cashEntriesData = backup['cashEntries'] as List<dynamic>? ?? [];
    for (final map in cashEntriesData) {
      final entry = CashEntry.fromJson(Map<String, dynamic>.from(map));
      await _cashEntryBox.put(entry.id, entry);
    }
    final cashNotesData = backup['cashNotes'] as List<dynamic>? ?? [];
    for (final map in cashNotesData) {
      final note = CashNote.fromJson(Map<String, dynamic>.from(map));
      await _cashNoteBox.put(note.id, note);
    }

    // Restore tombstones
    final tombstonesData = backup['tombstones'] as List<dynamic>? ?? [];
    for (final tombstoneMap in tombstonesData) {
      final tombstone =
          Tombstone.fromJson(Map<String, dynamic>.from(tombstoneMap));
      await _tombstoneBox.put(tombstone.entityId, tombstone);
    }

    // Ensure default vehicle exists
    await _ensureDefaultVehicle();
    await _ensureDefaultCashBook();

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
    await _otherExpenseBox.clear();
    await _miniLedgerBox.clear();
    await _cashBookBox.clear();
    await _cashEntryBox.clear();
    await _cashNoteBox.clear();
    await _tombstoneBox.clear();
    await _settingsBox.delete('currentVehicleId');
    // Recreate default vehicle after clearing (for normal clear, not restore)
    await _ensureDefaultVehicle();
    await _ensureDefaultCashBook();
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
    await _otherExpenseBox.clear();
    await _miniLedgerBox.clear();
    await _cashBookBox.clear();
    await _cashEntryBox.clear();
    await _cashNoteBox.clear();
    await _tombstoneBox.clear();
    await _settingsBox.delete('currentVehicleId');
  }

  // ============ DIESEL OPERATIONS ============
  static Future<void> saveDieselEntry(DieselEntry entry) async {
    await _dieselBox.put(entry.id, entry);
  }

  static Future<void> deleteDieselEntry(String id) async {
    await recordTombstone(id, dieselBoxName);
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
    await recordTombstone(id, pvcBoxName);
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
    await recordTombstone(id, bitBoxName);
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
    await recordTombstone(id, hammerBoxName);
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

  // ============ OTHER EXPENSE OPERATIONS ============
  static Future<void> saveOtherExpenseEntry(OtherExpenseEntry entry) async {
    await _otherExpenseBox.put(entry.id, entry);
  }

  static Future<void> deleteOtherExpenseEntry(String id) async {
    await recordTombstone(id, otherExpenseBoxName);
    await _otherExpenseBox.delete(id);
  }

  static List<OtherExpenseEntry> getAllOtherExpenseEntries() {
    return _otherExpenseBox.values.toList();
  }

  static List<OtherExpenseEntry> getOtherExpenseEntriesByVehicle(
      String vehicleId) {
    return _otherExpenseBox.values
        .where((e) => e.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<OtherExpenseEntry> getOtherExpenseEntriesByDateRange(
      String vehicleId, DateTime start, DateTime end) {
    return _otherExpenseBox.values
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
    await recordTombstone(id, miniLedgerBoxName);
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

  // ============ ACCOUNT LEDGER (CASH BOOK) OPERATIONS ============

  /// Creates the default "Cash Book" when no book exists. The fixed id and the
  /// old timestamps make an existing tombstone or any edit on another device
  /// win during sync, so the default book is never resurrected by a merge.
  static Future<void> _ensureDefaultCashBook() async {
    if (_cashBookBox.isEmpty) {
      final old = DateTime(2000);
      final book = CashBook(
        id: defaultCashBookId,
        name: 'Cash Book',
        createdAt: old,
        updatedAt: old,
      );
      await _cashBookBox.put(book.id, book);
    }
  }

  static List<CashBook> getAllCashBooks() {
    return _cashBookBox.values.toList()
      ..sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
  }

  static CashBook? getCashBook(String id) => _cashBookBox.get(id);

  static Future<void> saveCashBook(CashBook book) async {
    await _cashBookBox.put(book.id, book);
  }

  /// Deletes a book. Its entries move to the trash (soft delete) keeping the
  /// book name, so they can be restored into another book.
  static Future<void> deleteCashBook(String id) async {
    final book = _cashBookBox.get(id);
    if (book == null) return;
    final now = DateTime.now();
    final updated = <String, CashEntry>{};
    for (final entry in _cashEntryBox.values.where((e) => e.bookId == id)) {
      if (entry.isDeleted) {
        updated[entry.id] = entry.copyWith(
          bookNameSnapshot: entry.bookNameSnapshot ?? book.name,
          updatedAt: now,
        );
      } else {
        updated[entry.id] = entry.copyWith(
          isDeleted: true,
          deletedAt: now,
          bookNameSnapshot: book.name,
          updatedAt: now,
        );
      }
    }
    await _cashEntryBox.putAll(updated);
    await recordTombstone(id, cashBookBoxName);
    await _cashBookBox.delete(id);
  }

  /// All entries, optionally limited to one book. Trashed entries are
  /// excluded unless [includeDeleted] is true.
  static List<CashEntry> getCashEntries(
      {String? bookId, bool includeDeleted = false}) {
    return _cashEntryBox.values
        .where((e) =>
            (bookId == null || e.bookId == bookId) &&
            (includeDeleted || !e.isDeleted))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<CashEntry> getCashTrash() {
    return _cashEntryBox.values.where((e) => e.isDeleted).toList()
      ..sort(
          (a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
  }

  static CashEntry? getCashEntry(String id) => _cashEntryBox.get(id);

  static Future<void> saveCashEntry(CashEntry entry) async {
    await _cashEntryBox.put(entry.id, entry);
  }

  /// Saves several entries in one write (used by transfers and import).
  static Future<void> saveCashEntries(List<CashEntry> entries) async {
    await _cashEntryBox.putAll({for (final e in entries) e.id: e});
  }

  static Future<void> moveCashEntryToTrash(String id) async {
    final entry = _cashEntryBox.get(id);
    if (entry == null || entry.isDeleted) return;
    final now = DateTime.now();
    await _cashEntryBox.put(
      id,
      entry.copyWith(
        isDeleted: true,
        deletedAt: now,
        bookNameSnapshot: _cashBookBox.get(entry.bookId)?.name,
        updatedAt: now,
      ),
    );
  }

  /// Restores a trashed entry, optionally into a different book.
  static Future<void> restoreCashEntry(String id, {String? toBookId}) async {
    final entry = _cashEntryBox.get(id);
    if (entry == null || !entry.isDeleted) return;
    final restored = entry.copyWith(
      bookId: toBookId ?? entry.bookId,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );
    // copyWith cannot clear nullable fields, so rebuild the trash markers.
    restored.deletedAt = null;
    restored.bookNameSnapshot = null;
    await _cashEntryBox.put(id, restored);
  }

  /// Permanently removes an entry (tombstone first, as for every delete).
  static Future<void> purgeCashEntry(String id) async {
    if (!_cashEntryBox.containsKey(id)) return;
    await recordTombstone(id, cashEntryBoxName);
    await _cashEntryBox.delete(id);
  }

  static Future<void> emptyCashTrash() async {
    for (final id in getCashTrash().map((e) => e.id).toList()) {
      await purgeCashEntry(id);
    }
  }

  /// Removes trashed entries older than [cashTrashRetention].
  static Future<void> purgeExpiredCashTrash({Duration? maxAge}) async {
    final cutoff = DateTime.now().subtract(maxAge ?? cashTrashRetention);
    final expired = _cashEntryBox.values
        .where((e) =>
            e.isDeleted && e.deletedAt != null && e.deletedAt!.isBefore(cutoff))
        .map((e) => e.id)
        .toList();
    for (final id in expired) {
      await purgeCashEntry(id);
    }
  }

  static List<CashNote> getAllCashNotes() {
    return _cashNoteBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveCashNote(CashNote note) async {
    await _cashNoteBox.put(note.id, note);
  }

  static Future<void> deleteCashNote(String id) async {
    await recordTombstone(id, cashNoteBoxName);
    await _cashNoteBox.delete(id);
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
    // Delete other expense entries
    for (final entry in getOtherExpenseEntriesByVehicle(vehicleId)) {
      await deleteOtherExpenseEntry(entry.id);
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

  // ============ TOMBSTONE OPERATIONS ============

  /// Record a tombstone when an entity is deleted (for sync)
  static Future<void> recordTombstone(
      String entityId, String collection) async {
    final tombstone = Tombstone(
      entityId: entityId,
      collection: collection,
      deletedAt: DateTime.now(),
    );
    await _tombstoneBox.put(entityId, tombstone);
  }

  /// Get all tombstones
  static List<Tombstone> getAllTombstones() {
    return _tombstoneBox.values.toList();
  }

  /// Check if an entity ID has been tombstoned
  static bool isTombstoned(String entityId) {
    return _tombstoneBox.containsKey(entityId);
  }

  /// Clear tombstones older than a given duration (e.g., 30 days)
  static Future<void> pruneTombstones(
      {Duration maxAge = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = _tombstoneBox.values
        .where((t) => t.deletedAt.isBefore(cutoff))
        .map((t) => t.entityId)
        .toList();
    for (final id in toRemove) {
      await _tombstoneBox.delete(id);
    }
  }

  /// Clear all tombstones
  static Future<void> clearTombstones() async {
    await _tombstoneBox.clear();
  }
}
