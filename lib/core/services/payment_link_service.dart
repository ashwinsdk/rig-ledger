import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/cash_entry.dart';
import '../models/ledger_entry.dart';
import '../models/ledger_payment.dart';

const _uuid = Uuid();

/// Keeps payments logged on a bill (LedgerEntry.paymentsJson) and the income
/// entries in the receiver books of the Account Ledger in step (v2.0.0).
///
/// Rules:
/// - A payment with a receiver book has one linked [CashEntry] with
///   sourceType 'ledger_payment', sourceId = bill id, sourcePaymentId =
///   payment id. Date, amount and book follow the payment.
/// - Notes of the linked entry are generated once ("Bill 101 - Town") and are
///   then owned by the book (user edits are kept).
/// - Editing the linked entry in the book updates the payment and the bill
///   totals. Trashing it keeps the payment on the bill but clears its
///   receiver; restoring it (optionally into another book) links it again.
/// - Removing a payment, or its receiver, on the bill trashes the linked entry.
///
/// Callers refresh the Riverpod providers afterwards.
class PaymentLinkService {
  PaymentLinkService._();

  static const String sourceType = 'ledger_payment';

  static bool isLinked(CashEntry e) =>
      e.sourceType == sourceType &&
      e.sourceId != null &&
      e.sourcePaymentId != null;

  static List<CashEntry> _linkedTo(String ledgerEntryId) {
    return DatabaseService.cashEntryBox.values
        .where((e) => e.sourceType == sourceType && e.sourceId == ledgerEntryId)
        .toList();
  }

  static String _notesFor(LedgerEntry bill, LedgerPayment p) {
    final head =
        'Bill ${bill.billNumber}${bill.address.isEmpty ? '' : ' - ${bill.address}'}';
    final extra = <String>[
      if (!p.isCash)
        'PhonePe${(p.payerName ?? '').isEmpty ? '' : ' from ${p.payerName}'}',
      if ((p.notes ?? '').isNotEmpty) p.notes!,
    ];
    return extra.isEmpty ? head : '$head\n${extra.join(', ')}';
  }

  /// Creates, updates and trashes linked cash entries so they match the
  /// payments of [bill]. Call after the bill is saved.
  static Future<void> syncEntry(LedgerEntry bill) async {
    final payments = bill.payments;
    final linked = _linkedTo(bill.id);
    final now = DateTime.now();
    final toSave = <CashEntry>[];

    final wanted = <String>{};
    for (final p in payments) {
      final bookId = p.receiverBookId;
      if (bookId == null || DatabaseService.getCashBook(bookId) == null)
        continue;
      wanted.add(p.id);
      final existing =
          linked.where((c) => c.sourcePaymentId == p.id).firstOrNull;
      if (existing == null) {
        toSave.add(CashEntry(
          id: _uuid.v4(),
          bookId: bookId,
          date: p.date,
          amount: p.amount,
          isCashIn: true,
          notes: _notesFor(bill, p),
          createdAt: now,
          updatedAt: now,
          sourceType: sourceType,
          sourceId: bill.id,
          sourcePaymentId: p.id,
        ));
      } else {
        final changed = existing.bookId != bookId ||
            existing.amount != p.amount ||
            existing.date != p.date ||
            existing.isDeleted;
        if (changed) {
          existing
            ..bookId = bookId
            ..amount = p.amount
            ..date = p.date
            ..isCashIn = true
            ..isDeleted = false
            ..deletedAt = null
            ..bookNameSnapshot = null
            ..updatedAt = now;
          toSave.add(existing);
        }
      }
    }

    // Payments that were removed or lost their receiver: trash the entry.
    for (final c in linked) {
      if (!c.isDeleted && !wanted.contains(c.sourcePaymentId)) {
        await DatabaseService.moveCashEntryToTrash(c.id);
      }
    }
    if (toSave.isNotEmpty) await DatabaseService.saveCashEntries(toSave);
  }

  /// A bill is being deleted: trash its linked entries. Call before or after
  /// the bill is removed.
  static Future<void> onBillDeleted(String ledgerEntryId) async {
    for (final c in _linkedTo(ledgerEntryId)) {
      if (!c.isDeleted) await DatabaseService.moveCashEntryToTrash(c.id);
    }
  }

  /// Rewrites the payment list of [bill] and recomputes the received totals
  /// and balance. Unlogged (older) amounts are preserved.
  static Future<LedgerEntry> _applyPayments(
      LedgerEntry bill, List<LedgerPayment> payments) async {
    final cash = bill.unloggedCash + LedgerPayment.totalCash(payments);
    final pe = bill.unloggedPhonePe + LedgerPayment.totalPhonePe(payments);
    final received = (cash + pe);
    final updated = bill.copyWith(
      paymentsJson: LedgerPayment.encodeList(payments),
      clearPayments: payments.isEmpty,
      receivedCash: cash,
      receivedPhonePe: pe,
      received: received,
      balance: LedgerEntry.calculateBalance(
          total: bill.total, received: received, less: bill.less),
      updatedAt: DateTime.now(),
    );
    await DatabaseService.saveLedgerEntry(updated);
    return updated;
  }

  static LedgerEntry? _bill(String id) => DatabaseService.ledgerBox.get(id);

  /// The linked entry was edited in the book: copy book, date and amount to
  /// the payment. Returns true when the bill changed.
  static Future<bool> onCashEntryEdited(CashEntry e) async {
    if (!isLinked(e) || e.isDeleted) return false;
    final bill = _bill(e.sourceId!);
    if (bill == null) return false;
    final list = bill.payments;
    final i = list.indexWhere((p) => p.id == e.sourcePaymentId);
    if (i < 0) return false;
    final p = list[i];
    if (p.receiverBookId == e.bookId &&
        p.amount == e.amount &&
        p.date == e.date) {
      return false;
    }
    list[i] =
        p.copyWith(receiverBookId: e.bookId, amount: e.amount, date: e.date);
    await _applyPayments(bill, list);
    return true;
  }

  /// The linked entry went to the trash: the payment stays on the bill (the
  /// money was received) but loses its receiver.
  static Future<bool> onCashEntryTrashed(CashEntry e) async {
    if (!isLinked(e)) return false;
    final bill = _bill(e.sourceId!);
    if (bill == null) return false;
    final list = bill.payments;
    final i = list.indexWhere((p) => p.id == e.sourcePaymentId);
    if (i < 0 || list[i].receiverBookId == null) return false;
    list[i] = list[i].copyWith(clearReceiver: true);
    await _applyPayments(bill, list);
    return true;
  }

  /// The linked entry was restored (possibly into another book): relink.
  static Future<bool> onCashEntryRestored(CashEntry e) async {
    if (!isLinked(e) || e.isDeleted) return false;
    final bill = _bill(e.sourceId!);
    if (bill == null) return false;
    final list = bill.payments;
    final i = list.indexWhere((p) => p.id == e.sourcePaymentId);
    if (i < 0) return false;
    list[i] = list[i]
        .copyWith(receiverBookId: e.bookId, amount: e.amount, date: e.date);
    await _applyPayments(bill, list);
    return true;
  }

  /// A book is being deleted: payments received by it lose their receiver.
  static Future<void> onBookDeleted(String bookId) async {
    for (final bill in DatabaseService.ledgerBox.values.toList()) {
      final list = bill.payments;
      var changed = false;
      for (var i = 0; i < list.length; i++) {
        if (list[i].receiverBookId == bookId) {
          list[i] = list[i].copyWith(clearReceiver: true);
          changed = true;
        }
      }
      if (changed) await _applyPayments(bill, list);
    }
  }

  /// Repairs differences after a sync (two devices edited the bill and the
  /// book independently): the side with the newer updatedAt wins. Returns the
  /// number of repaired links.
  static Future<int> reconcileAll() async {
    var fixed = 0;
    try {
      // Bills -> entries (create missing, update older cash entries).
      for (final bill in DatabaseService.ledgerBox.values.toList()) {
        final payments = bill.payments;
        if (payments.isEmpty) continue;
        final linked = _linkedTo(bill.id);
        // Newer cash entry wins over the bill's payment.
        var current = bill;
        for (final c in linked) {
          if (c.isDeleted || c.updatedAt.isBefore(current.updatedAt)) continue;
          if (await onCashEntryEdited(c)) {
            fixed++;
            current = _bill(bill.id) ?? current;
          }
        }
        await syncEntry(current);
      }
      // Entries whose bill or payment disappeared.
      for (final c in DatabaseService.cashEntryBox.values.toList()) {
        if (!isLinked(c) || c.isDeleted) continue;
        final bill = _bill(c.sourceId!);
        final exists =
            bill != null && bill.payments.any((p) => p.id == c.sourcePaymentId);
        if (!exists) {
          await DatabaseService.moveCashEntryToTrash(c.id);
          fixed++;
        }
      }
    } catch (e, st) {
      debugPrint('[PaymentLink] reconcile failed: $e\n$st');
    }
    return fixed;
  }
}
