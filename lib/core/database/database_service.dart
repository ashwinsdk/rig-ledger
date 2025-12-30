import 'package:hive_flutter/hive_flutter.dart';
import '../models/ledger_entry.dart';
import '../models/agent.dart';

class DatabaseService {
  static const String ledgerBoxName = 'ledger_entries';
  static const String agentBoxName = 'agents';
  static const String settingsBoxName = 'settings';
  static const int schemaVersion = 1;

  static late Box<LedgerEntry> _ledgerBox;
  static late Box<Agent> _agentBox;
  static late Box<dynamic> _settingsBox;

  static Box<LedgerEntry> get ledgerBox => _ledgerBox;
  static Box<Agent> get agentBox => _agentBox;
  static Box<dynamic> get settingsBox => _settingsBox;

  static Future<void> initialize() async {
    // Register adapters
    Hive.registerAdapter(LedgerEntryAdapter());
    Hive.registerAdapter(AgentAdapter());

    // Open boxes
    _ledgerBox = await Hive.openBox<LedgerEntry>(ledgerBoxName);
    _agentBox = await Hive.openBox<Agent>(agentBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);

    // Check and perform migrations
    await _performMigrations();
  }

  static Future<void> _performMigrations() async {
    final currentVersion =
        _settingsBox.get('schemaVersion', defaultValue: 0) as int;

    if (currentVersion < schemaVersion) {
      // Perform migrations based on version
      // Currently at version 1, no migrations needed

      await _settingsBox.put('schemaVersion', schemaVersion);
    }
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
    return _ledgerBox.values.toList();
  }

  static List<LedgerEntry> getLedgerEntriesByMonth(int year, int month) {
    return _ledgerBox.values.where((entry) {
      return entry.date.year == year && entry.date.month == month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<LedgerEntry> getLedgerEntriesByDateRange(
      DateTime start, DateTime end) {
    return _ledgerBox.values.where((entry) {
      return !entry.date.isBefore(start) && !entry.date.isAfter(end);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<LedgerEntry> getLedgerEntriesByAgent(String agentId) {
    return _ledgerBox.values
        .where((entry) => entry.agentId == agentId)
        .toList();
  }

  static List<LedgerEntry> searchLedgerEntries(String query) {
    final lowerQuery = query.toLowerCase();
    return _ledgerBox.values.where((entry) {
      return entry.billNumber.toLowerCase().contains(lowerQuery) ||
          entry.address.toLowerCase().contains(lowerQuery) ||
          entry.agentName.toLowerCase().contains(lowerQuery) ||
          (entry.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get all unique addresses from ledger entries
  static List<String> getUniqueAddresses() {
    final addresses = _ledgerBox.values
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
    return _agentBox.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static Agent? getAgentByName(String name) {
    try {
      return _agentBox.values.firstWhere(
        (agent) => agent.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static int getAgentBillCount(String agentId) {
    return _ledgerBox.values.where((entry) => entry.agentId == agentId).length;
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
    final ledgerEntries = getAllLedgerEntries().map((e) => e.toMap()).toList();
    final agents = getAllAgents().map((a) => a.toMap()).toList();

    return {
      'version': schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'ledgerEntries': ledgerEntries,
      'agents': agents,
    };
  }

  static Future<void> restoreBackup(Map<String, dynamic> backup) async {
    // Clear existing data
    await clearAllData();

    // Restore agents first
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
  }

  static Future<void> clearAllData() async {
    await _ledgerBox.clear();
    await _agentBox.clear();
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
