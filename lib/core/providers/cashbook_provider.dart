import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/cash_book.dart';
import '../models/cash_entry.dart';
import '../models/cash_note.dart';
import '../utils/cashbook_calculator.dart';

const _uuid = Uuid();

/// Notes text of the entry created for a book opening balance.
const String cashOpeningBalanceNotes = 'Opening Balance';

/// Fixed labels (decision D3: Income / Expense everywhere).
class CashLabels {
  CashLabels._();
  static const String income = 'Income';
  static const String expense = 'Expense';
  static const String totalIncome = 'Total Income';
  static const String totalExpense = 'Total Expense';
  static const String balance = 'Balance';
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

/// Account Ledger settings (stored in the settings box, keys "cashbook.*").
class CashSettings {
  static const List<String> dateFormats = [
    'MMM-dd-yyyy',
    'dd-MMM-yyyy',
    'dd-MM-yyyy',
    'dd-MM-yy',
    'MM-dd-yyyy',
    'yyyy-MMM-dd',
  ];

  final String dateFormat;
  final bool showTime;
  final bool use24Hour;
  final bool fixedDecimals; // "1,234.00" instead of "1,234"
  final bool showDateInEntry;
  final bool showPreviousBalance;
  final bool showBalancePerEntry;
  final bool showDescription;
  final bool notesSuggestion;
  final bool showTimeInReports;

  const CashSettings({
    this.dateFormat = 'MMM-dd-yyyy',
    this.showTime = true,
    this.use24Hour = false,
    this.fixedDecimals = false,
    this.showDateInEntry = false,
    this.showPreviousBalance = true,
    this.showBalancePerEntry = true,
    this.showDescription = false,
    this.notesSuggestion = true,
    this.showTimeInReports = false,
  });

  CashSettings copyWith({
    String? dateFormat,
    bool? showTime,
    bool? use24Hour,
    bool? fixedDecimals,
    bool? showDateInEntry,
    bool? showPreviousBalance,
    bool? showBalancePerEntry,
    bool? showDescription,
    bool? notesSuggestion,
    bool? showTimeInReports,
  }) {
    return CashSettings(
      dateFormat: dateFormat ?? this.dateFormat,
      showTime: showTime ?? this.showTime,
      use24Hour: use24Hour ?? this.use24Hour,
      fixedDecimals: fixedDecimals ?? this.fixedDecimals,
      showDateInEntry: showDateInEntry ?? this.showDateInEntry,
      showPreviousBalance: showPreviousBalance ?? this.showPreviousBalance,
      showBalancePerEntry: showBalancePerEntry ?? this.showBalancePerEntry,
      showDescription: showDescription ?? this.showDescription,
      notesSuggestion: notesSuggestion ?? this.notesSuggestion,
      showTimeInReports: showTimeInReports ?? this.showTimeInReports,
    );
  }

  String formatDate(DateTime d) => DateFormat(dateFormat).format(d);
  String formatTime(DateTime d) =>
      DateFormat(use24Hour ? 'HH:mm' : 'hh:mm a').format(d);
  String formatDayHeader(DateTime d) =>
      DateFormat('EEE, MMM dd yyyy').format(d);
  String formatMoney(double v) =>
      CashbookCalculator.formatMoney(v, fixed2: fixedDecimals);
}

class CashSettingsNotifier extends StateNotifier<CashSettings> {
  CashSettingsNotifier() : super(const CashSettings()) {
    loadSettings();
  }

  static T _get<T>(String key, T fallback) {
    final v = DatabaseService.settingsBox.get('cashbook.$key');
    return v is T ? v : fallback;
  }

  void loadSettings() {
    const d = CashSettings();
    state = CashSettings(
      dateFormat: _get('dateFormat', d.dateFormat),
      showTime: _get('showTime', d.showTime),
      use24Hour: _get('use24Hour', d.use24Hour),
      fixedDecimals: _get('fixedDecimals', d.fixedDecimals),
      showDateInEntry: _get('showDateInEntry', d.showDateInEntry),
      showPreviousBalance: _get('showPreviousBalance', d.showPreviousBalance),
      showBalancePerEntry: _get('showBalancePerEntry', d.showBalancePerEntry),
      showDescription: _get('showDescription', d.showDescription),
      notesSuggestion: _get('notesSuggestion', d.notesSuggestion),
      showTimeInReports: _get('showTimeInReports', d.showTimeInReports),
    );
  }

  Future<void> updateSettings(CashSettings s) async {
    final box = DatabaseService.settingsBox;
    await box.putAll({
      'cashbook.dateFormat': s.dateFormat,
      'cashbook.showTime': s.showTime,
      'cashbook.use24Hour': s.use24Hour,
      'cashbook.fixedDecimals': s.fixedDecimals,
      'cashbook.showDateInEntry': s.showDateInEntry,
      'cashbook.showPreviousBalance': s.showPreviousBalance,
      'cashbook.showBalancePerEntry': s.showBalancePerEntry,
      'cashbook.showDescription': s.showDescription,
      'cashbook.notesSuggestion': s.notesSuggestion,
      'cashbook.showTimeInReports': s.showTimeInReports,
    });
    state = s;
  }

  void refresh() => loadSettings();
}

final cashSettingsProvider =
    StateNotifierProvider<CashSettingsNotifier, CashSettings>((ref) {
  return CashSettingsNotifier();
});

// ---------------------------------------------------------------------------
// Books
// ---------------------------------------------------------------------------

class CashBooksNotifier extends StateNotifier<List<CashBook>> {
  final Ref _ref;
  CashBooksNotifier(this._ref) : super([]) {
    loadBooks();
  }

  void loadBooks() {
    state = DatabaseService.getAllCashBooks();
  }

  bool _nameTaken(String name, {String? exceptId}) {
    final n = name.trim().toLowerCase();
    return state.any((b) => b.id != exceptId && b.name.toLowerCase() == n);
  }

  /// Adds a book. A positive [openingBalance] also creates the
  /// "Opening Balance" entry (cash in for [openingIsPositive], else cash out).
  /// Returns (book, errorMessage). An empty name creates nothing.
  Future<(CashBook?, String?)> addBook({
    required String name,
    int kind = 0,
    double openingBalance = 0,
    bool openingIsPositive = true,
    DateTime? openingDate,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return (null, 'Enter a name');
    if (_nameTaken(trimmed)) return (null, 'A book with this name exists');
    final now = DateTime.now();
    final book = CashBook(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: now,
      updatedAt: now,
      sortOrder: state.length,
      kind: kind,
    );
    await DatabaseService.saveCashBook(book);
    if (openingBalance > 0) {
      await DatabaseService.saveCashEntry(CashEntry(
        id: _uuid.v4(),
        bookId: book.id,
        date: openingDate ?? now,
        amount: CashbookCalculator.roundMoney(openingBalance),
        isCashIn: openingIsPositive,
        notes: cashOpeningBalanceNotes,
        createdAt: now,
        updatedAt: now,
      ));
      _ref.read(cashEntriesProvider.notifier).refresh();
    }
    loadBooks();
    return (book, null);
  }

  Future<(bool, String?)> renameBook(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return (false, 'Enter a name');
    if (_nameTaken(trimmed, exceptId: id)) {
      return (false, 'A book with this name exists');
    }
    final book = DatabaseService.getCashBook(id);
    if (book == null) return (false, 'Book not found');
    await DatabaseService.saveCashBook(
        book.copyWith(name: trimmed, updatedAt: DateTime.now()));
    loadBooks();
    return (true, null);
  }

  Future<void> updateBook(CashBook book) async {
    await DatabaseService.saveCashBook(
        book.copyWith(updatedAt: DateTime.now()));
    loadBooks();
  }

  /// Deletes a book; its entries go to the trash.
  Future<void> deleteBook(String id) async {
    await DatabaseService.deleteCashBook(id);
    loadBooks();
    _ref.read(cashEntriesProvider.notifier).refresh();
    final current = _ref.read(currentCashBookIdProvider);
    if (current == id) {
      _ref.read(currentCashBookIdProvider.notifier).select(null);
    }
  }

  /// Creates or edits the opening balance entry of a book (PARITY-011).
  Future<(bool, String?)> setOpeningBalance({
    required String bookId,
    required double amount,
    required bool isPositive,
    required DateTime date,
  }) async {
    if (amount <= 0) return (false, 'Enter an amount');
    final entries = _ref.read(cashEntriesProvider);
    final existing = entries
        .where((e) =>
            e.bookId == bookId &&
            !e.isDeleted &&
            e.sourceType == null &&
            e.notes == cashOpeningBalanceNotes)
        .toList()
      ..sort(CashbookCalculator.compareChronological);
    final now = DateTime.now();
    final rounded = CashbookCalculator.roundMoney(amount);
    if (existing.isNotEmpty) {
      await DatabaseService.saveCashEntry(existing.first.copyWith(
        amount: rounded,
        isCashIn: isPositive,
        date: date,
        updatedAt: now,
      ));
    } else {
      await DatabaseService.saveCashEntry(CashEntry(
        id: _uuid.v4(),
        bookId: bookId,
        date: date,
        amount: rounded,
        isCashIn: isPositive,
        notes: cashOpeningBalanceNotes,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _ref.read(cashEntriesProvider.notifier).refresh();
    return (true, null);
  }

  void refresh() => loadBooks();
}

final cashBooksProvider =
    StateNotifierProvider<CashBooksNotifier, List<CashBook>>((ref) {
  return CashBooksNotifier(ref);
});

/// Id of the book shown on the Account Ledger home (persisted).
class CurrentCashBookIdNotifier extends StateNotifier<String?> {
  CurrentCashBookIdNotifier()
      : super(
            DatabaseService.settingsBox.get('cashbook.lastBookId') as String?);

  Future<void> select(String? id) async {
    state = id;
    if (id == null) {
      await DatabaseService.settingsBox.delete('cashbook.lastBookId');
    } else {
      await DatabaseService.settingsBox.put('cashbook.lastBookId', id);
    }
  }

  void refresh() {
    state = DatabaseService.settingsBox.get('cashbook.lastBookId') as String?;
  }
}

final currentCashBookIdProvider =
    StateNotifierProvider<CurrentCashBookIdNotifier, String?>((ref) {
  return CurrentCashBookIdNotifier();
});

/// The selected book, falling back to the first book.
final currentCashBookProvider = Provider<CashBook?>((ref) {
  final books = ref.watch(cashBooksProvider);
  final id = ref.watch(currentCashBookIdProvider);
  if (books.isEmpty) return null;
  return books.firstWhere((b) => b.id == id, orElse: () => books.first);
});

// ---------------------------------------------------------------------------
// Entries
// ---------------------------------------------------------------------------

class CashEntriesNotifier extends StateNotifier<List<CashEntry>> {
  CashEntriesNotifier() : super([]) {
    loadEntries();
  }

  /// State holds every entry including trashed ones; derived providers filter.
  void loadEntries() {
    state = DatabaseService.getCashEntries(includeDeleted: true);
  }

  /// Creates and saves an entry. Amount is rounded to 2 decimals and must be
  /// zero or more (PARITY-017, 019, 020).
  Future<(CashEntry?, String?)> addEntry({
    required String bookId,
    required DateTime date,
    required double amount,
    required bool isCashIn,
    String notes = '',
    String? description,
    List<String>? attachmentPaths,
    String? itemsJson,
    String? sourceType,
    String? sourceId,
    String? sourcePaymentId,
  }) async {
    if (amount.isNaN || amount < 0) return (null, 'Enter a valid amount');
    if (DatabaseService.getCashBook(bookId) == null) {
      return (null, 'Book not found');
    }
    final now = DateTime.now();
    final entry = CashEntry(
      id: _uuid.v4(),
      bookId: bookId,
      date: date,
      amount: CashbookCalculator.roundMoney(amount),
      isCashIn: isCashIn,
      notes: notes,
      description:
          (description == null || description.isEmpty) ? null : description,
      attachmentPaths: attachmentPaths,
      itemsJson: itemsJson,
      createdAt: now,
      updatedAt: now,
      sourceType: sourceType,
      sourceId: sourceId,
      sourcePaymentId: sourcePaymentId,
    );
    await DatabaseService.saveCashEntry(entry);
    loadEntries();
    return (entry, null);
  }

  Future<(bool, String?)> updateEntry(CashEntry entry) async {
    if (entry.amount.isNaN || entry.amount < 0) {
      return (false, 'Enter a valid amount');
    }
    entry.amount = CashbookCalculator.roundMoney(entry.amount);
    entry.updatedAt = DateTime.now();
    await DatabaseService.saveCashEntry(entry);
    loadEntries();
    return (true, null);
  }

  Future<void> moveToTrash(String id) async {
    await DatabaseService.moveCashEntryToTrash(id);
    loadEntries();
  }

  Future<void> restore(String id, {String? toBookId}) async {
    await DatabaseService.restoreCashEntry(id, toBookId: toBookId);
    loadEntries();
  }

  Future<void> purge(String id) async {
    await DatabaseService.purgeCashEntry(id);
    loadEntries();
  }

  Future<void> emptyTrash() async {
    await DatabaseService.emptyCashTrash();
    loadEntries();
  }

  /// Transfer between two books as two linked entries (PARITY-058).
  Future<(bool, String?)> transfer({
    required String fromBookId,
    required String toBookId,
    required double amount,
    required DateTime date,
    String notes = '',
  }) async {
    if (amount.isNaN || amount <= 0) return (false, 'Enter an amount');
    if (fromBookId == toBookId) return (false, 'Choose two different books');
    final from = DatabaseService.getCashBook(fromBookId);
    final to = DatabaseService.getCashBook(toBookId);
    if (from == null || to == null) return (false, 'Book not found');
    final now = DateTime.now();
    final group = _uuid.v4();
    final rounded = CashbookCalculator.roundMoney(amount);
    String note(String prefix, String name) =>
        notes.isEmpty ? '$prefix $name' : '$prefix $name\n$notes';
    await DatabaseService.saveCashEntries([
      CashEntry(
        id: _uuid.v4(),
        bookId: fromBookId,
        date: date,
        amount: rounded,
        isCashIn: false,
        notes: note('To', to.name),
        transferGroupId: group,
        createdAt: now,
        updatedAt: now,
      ),
      CashEntry(
        id: _uuid.v4(),
        bookId: toBookId,
        date: date,
        amount: rounded,
        isCashIn: true,
        notes: note('From', from.name),
        transferGroupId: group,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    loadEntries();
    return (true, null);
  }

  void refresh() => loadEntries();
}

final cashEntriesProvider =
    StateNotifierProvider<CashEntriesNotifier, List<CashEntry>>((ref) {
  return CashEntriesNotifier();
});

/// Trashed entries, most recently deleted first.
final cashTrashProvider = Provider<List<CashEntry>>((ref) {
  return ref.watch(cashEntriesProvider).where((e) => e.isDeleted).toList()
    ..sort((a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
});

/// Distinct earlier notes for autocomplete, most recent first.
final cashNoteSuggestionsProvider = Provider<List<String>>((ref) {
  final entries = ref.watch(cashEntriesProvider).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final seen = <String>{};
  final out = <String>[];
  for (final e in entries) {
    final n = e.notes.trim();
    if (n.isNotEmpty && !n.contains('\n') && seen.add(n.toLowerCase())) {
      out.add(n);
    }
  }
  return out;
});

// ---------------------------------------------------------------------------
// Home view (tabs, search, filters, sort) and derived ledger
// ---------------------------------------------------------------------------

enum CashTypeFilter { all, income, expense }

class CashViewConfig {
  final CashPeriod period;
  final DateTime anchor;
  final String query;
  final CashTypeFilter type;
  final bool ascending;

  /// "Date" and "Select Date Range" overflow items; overrides the period.
  final CashDateRange? customRange;

  const CashViewConfig({
    required this.period,
    required this.anchor,
    this.query = '',
    this.type = CashTypeFilter.all,
    this.ascending = false,
    this.customRange,
  });

  factory CashViewConfig.initial() =>
      CashViewConfig(period: CashPeriod.all, anchor: DateTime.now());

  CashDateRange? get activeRange =>
      customRange ?? CashbookCalculator.periodRange(period, anchor);

  CashViewConfig copyWith({
    CashPeriod? period,
    DateTime? anchor,
    String? query,
    CashTypeFilter? type,
    bool? ascending,
    CashDateRange? customRange,
    bool clearCustomRange = false,
  }) {
    return CashViewConfig(
      period: period ?? this.period,
      anchor: anchor ?? this.anchor,
      query: query ?? this.query,
      type: type ?? this.type,
      ascending: ascending ?? this.ascending,
      customRange: clearCustomRange ? null : (customRange ?? this.customRange),
    );
  }
}

class CashViewConfigNotifier extends StateNotifier<CashViewConfig> {
  CashViewConfigNotifier() : super(CashViewConfig.initial());

  void setPeriod(CashPeriod p) {
    state = state.copyWith(
        period: p, anchor: DateTime.now(), clearCustomRange: true);
  }

  void shift(int delta) {
    state = state.copyWith(
        anchor:
            CashbookCalculator.shiftAnchor(state.period, state.anchor, delta),
        clearCustomRange: true);
  }

  void setQuery(String q) => state = state.copyWith(query: q);
  void setType(CashTypeFilter t) => state = state.copyWith(type: t);
  void setAscending(bool a) => state = state.copyWith(ascending: a);
  void setCustomRange(CashDateRange r) =>
      state = state.copyWith(customRange: r);

  /// Shows a single day.
  void setDay(DateTime d) {
    final day = CashbookCalculator.dateOnly(d);
    state = state.copyWith(
        customRange:
            CashDateRange(day, DateTime(day.year, day.month, day.day + 1)));
  }

  void clearFilters() => state = CashViewConfig.initial();
}

final cashViewConfigProvider =
    StateNotifierProvider<CashViewConfigNotifier, CashViewConfig>((ref) {
  return CashViewConfigNotifier();
});

/// What the Account Ledger home list shows.
class CashLedgerView {
  final List<CashLedgerRow> rows;
  final List<CashDayGroup> groups;
  final CashTotals totals; // of the visible rows
  final double previousBalance;
  final bool hasPreviousBalance;
  final CashDateRange? range;

  const CashLedgerView({
    required this.rows,
    required this.groups,
    required this.totals,
    required this.previousBalance,
    required this.hasPreviousBalance,
    required this.range,
  });

  double get finalBalance =>
      CashbookCalculator.roundMoney(previousBalance + totals.balance);
}

bool _matchesQuery(CashEntry e, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return e.notes.toLowerCase().contains(q) ||
      (e.description ?? '').toLowerCase().contains(q);
}

final cashLedgerProvider = Provider<CashLedgerView>((ref) {
  final book = ref.watch(currentCashBookProvider);
  final cfg = ref.watch(cashViewConfigProvider);
  final settings = ref.watch(cashSettingsProvider);
  final all = ref.watch(cashEntriesProvider);

  final bookEntries = book == null
      ? <CashEntry>[]
      : all.where((e) => e.bookId == book.id && !e.isDeleted).toList();

  // Search ignores the period tab (observed in the reference app).
  final searching = cfg.query.trim().isNotEmpty;
  final range = searching ? null : cfg.activeRange;

  final visible = bookEntries.where((e) {
    if (range != null && !range.contains(e.date)) return false;
    if (cfg.type == CashTypeFilter.income && !e.isCashIn) return false;
    if (cfg.type == CashTypeFilter.expense && e.isCashIn) return false;
    return _matchesQuery(e, cfg.query);
  }).toList();

  final hasPrev = range != null && settings.showPreviousBalance;
  final prev = hasPrev
      ? CashbookCalculator.previousBalance(bookEntries, range.start)
      : 0.0;
  final rows = CashbookCalculator.buildRows(visible,
      openingBalance: prev, ascending: cfg.ascending);
  return CashLedgerView(
    rows: rows,
    groups: CashbookCalculator.groupByDay(rows),
    totals: CashbookCalculator.totals(visible),
    previousBalance: prev,
    hasPreviousBalance: hasPrev,
    range: range,
  );
});

// ---------------------------------------------------------------------------
// Summaries (Summary, Account Summary, Transaction-All, Calendar)
// ---------------------------------------------------------------------------

/// Key for the summary families. [bookId] null means all books.
typedef CashQuery = ({
  String? bookId,
  CashPeriod period,
  DateTime anchor,
  CashDateRange? custom,
});

/// Non-deleted entries matching a [CashQuery], newest first.
final cashQueryEntriesProvider =
    Provider.family<List<CashEntry>, CashQuery>((ref, q) {
  final all = ref.watch(cashEntriesProvider);
  final range = q.custom ?? CashbookCalculator.periodRange(q.period, q.anchor);
  return all
      .where((e) =>
          !e.isDeleted &&
          (q.bookId == null || e.bookId == q.bookId) &&
          (range == null || range.contains(e.date)))
      .toList()
    ..sort((a, b) => CashbookCalculator.compareChronological(b, a));
});

class CashBookSummary {
  final CashBook book;
  final CashTotals totals;
  const CashBookSummary(this.book, this.totals);
}

/// Per book totals (only books with entries) and the grand total.
class CashSummaryView {
  final List<CashBookSummary> books;
  final CashTotals grand;
  const CashSummaryView(this.books, this.grand);
}

final cashSummaryProvider =
    Provider.family<CashSummaryView, CashQuery>((ref, q) {
  final books = ref.watch(cashBooksProvider);
  final entries = ref.watch(cashQueryEntriesProvider(
      (bookId: null, period: q.period, anchor: q.anchor, custom: q.custom)));
  final out = <CashBookSummary>[];
  for (final b in books) {
    final mine = entries.where((e) => e.bookId == b.id).toList();
    if (mine.isEmpty) continue;
    out.add(CashBookSummary(b, CashbookCalculator.totals(mine)));
  }
  return CashSummaryView(out, CashbookCalculator.totals(entries));
});

/// Per-day totals (oldest first) for Account Summary and Calendar.
final cashDaySummaryProvider =
    Provider.family<Map<DateTime, CashTotals>, CashQuery>((ref, q) {
  return CashbookCalculator.totalsByDay(ref.watch(cashQueryEntriesProvider(q)));
});

// ---------------------------------------------------------------------------
// Notes (Notebook)
// ---------------------------------------------------------------------------

class CashNotesNotifier extends StateNotifier<List<CashNote>> {
  CashNotesNotifier() : super([]) {
    loadNotes();
  }

  void loadNotes() {
    state = DatabaseService.getAllCashNotes();
  }

  Future<(CashNote?, String?)> addNote(
      {required DateTime date, required String text}) async {
    if (text.trim().isEmpty) return (null, 'Enter a note');
    final now = DateTime.now();
    final note = CashNote(
        id: _uuid.v4(),
        date: date,
        text: text.trim(),
        createdAt: now,
        updatedAt: now);
    await DatabaseService.saveCashNote(note);
    loadNotes();
    return (note, null);
  }

  Future<void> updateNote(CashNote note) async {
    await DatabaseService.saveCashNote(
        note.copyWith(updatedAt: DateTime.now()));
    loadNotes();
  }

  Future<void> toggleCompleted(String id) async {
    final note = state.firstWhere((n) => n.id == id);
    await updateNote(note.copyWith(isCompleted: !note.isCompleted));
  }

  Future<void> deleteNote(String id) async {
    await DatabaseService.deleteCashNote(id);
    loadNotes();
  }

  void refresh() => loadNotes();
}

final cashNotesProvider =
    StateNotifierProvider<CashNotesNotifier, List<CashNote>>((ref) {
  return CashNotesNotifier();
});

/// Refreshes every Account Ledger provider (after sync or restore).
void refreshCashbookProviders(Ref ref) {
  ref.read(cashBooksProvider.notifier).refresh();
  ref.read(cashEntriesProvider.notifier).refresh();
  ref.read(cashNotesProvider.notifier).refresh();
  ref.read(cashSettingsProvider.notifier).refresh();
  ref.read(currentCashBookIdProvider.notifier).refresh();
}
