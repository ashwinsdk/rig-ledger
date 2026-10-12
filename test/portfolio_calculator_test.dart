import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/core/models/bit_entry.dart';
import 'package:rig_ledger/core/models/diesel_entry.dart';
import 'package:rig_ledger/core/models/hammer_entry.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/pvc_entry.dart';
import 'package:rig_ledger/core/utils/portfolio_calculator.dart';

LedgerEntry bill(String id, String agent, DateTime d,
    {double total = 1000,
    double received = 0,
    double less = 0,
    double commission = 0}) {
  return LedgerEntry(
    id: id,
    date: d,
    billNumber: id,
    agentId: agent,
    agentName: 'Agent $agent',
    address: '',
    depth: '7inch',
    depthInFeet: 0,
    depthPerFeetRate: 0,
    pvc: '7inch',
    msPipe: '6inch',
    extraCharges: 0,
    total: total,
    isTotalManuallyEdited: false,
    received: received,
    balance: total - received - less,
    less: less,
    createdAt: d,
    updatedAt: d,
    commission: commission,
  );
}

DieselEntry diesel(DateTime d, double total, {String v = 'v1'}) => DieselEntry(
      id: 'd$total',
      vehicleId: v,
      date: d,
      billNumber: '1',
      litre: 1,
      rate: total,
      total: total,
      paid: 0,
      pending: total,
      balance: 0,
      bunkDetails: '',
      createdAt: d,
      updatedAt: d,
    );

PvcEntry pvc(DateTime d, double total, {String v = 'v1'}) => PvcEntry(
      id: 'p$total',
      vehicleId: v,
      date: d,
      billNumber: '1',
      type: '7 inch',
      count: 1,
      rate: total,
      total: total,
      paid: 0,
      pending: total,
      balance: 0,
      storagePlace: '',
      createdAt: d,
      updatedAt: d,
    );

BitEntry bitE(DateTime d, double total) => BitEntry(
      id: 'b$total',
      vehicleId: 'v1',
      date: d,
      billNumber: '1',
      type: '7 inch',
      bitId: 'x',
      count: 1,
      rate: total,
      total: total,
      paid: 0,
      pending: total,
      balance: 0,
      createdAt: d,
      updatedAt: d,
    );

HammerEntry hammer(DateTime d, double total) => HammerEntry(
      id: 'h$total',
      vehicleId: 'v1',
      date: d,
      billNumber: '1',
      type: '7 inch',
      hammerName: 'h',
      count: 1,
      rate: total,
      total: total,
      paid: 0,
      pending: total,
      balance: 0,
      createdAt: d,
      updatedAt: d,
    );

void main() {
  final d1 = DateTime(2026, 10, 5);
  final d2 = DateTime(2026, 9, 5);

  test('totals, pending, commission and profit', () {
    final s = PortfolioCalculator.compute(
      bills: [
        bill('1', 'a', d1,
            total: 10000, received: 6000, less: 500, commission: 800),
        bill('2', 'b', d1, total: 5000, received: 5000, commission: 200),
        bill('3', 'a', d2, total: 3000, received: 0),
      ],
      diesel: [diesel(d1, 1000)],
      pvc: [pvc(d1, 500)],
      bit: [bitE(d1, 250)],
      hammer: [hammer(d1, 250)],
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31, 23, 59, 59),
    );
    expect(s.bills, 2);
    expect(s.total, 15000);
    expect(s.less, 500);
    expect(s.received, 11000);
    expect(s.pending, 3500); // 10000-6000-500 + 0
    expect(s.commission, 1000);
    expect(s.expenses, 2000);
    expect(s.netBilled, 14500);
    expect(s.realisedProfit, 11000 - 2000 - 1000);
    expect(s.expectedProfit, 14500 - 2000 - 1000);
    expect(s.expensesApply, isTrue);
    expect(s.agents.first.agentId, 'a'); // largest total first
    expect(s.agents.length, 2);
  });

  test('agent filter hides expenses and profit inputs', () {
    final s = PortfolioCalculator.compute(
      bills: [
        bill('1', 'a', d1, total: 100, received: 40, commission: 5),
        bill('2', 'b', d1, total: 900),
      ],
      diesel: [diesel(d1, 1000)],
      pvc: const [],
      bit: const [],
      hammer: const [],
      agentId: 'a',
    );
    expect(s.expensesApply, isFalse);
    expect(s.expenses, 0);
    expect(s.total, 100);
    expect(s.commission, 5);
    expect(s.agents.length, 1);
  });

  test('all time uses every record; day range is inclusive', () {
    final bills = [bill('1', 'a', d1), bill('2', 'a', d2)];
    expect(
        PortfolioCalculator.compute(
            bills: bills,
            diesel: const [],
            pvc: const [],
            bit: const [],
            hammer: const []).bills,
        2);
    final day = PortfolioCalculator.compute(
      bills: bills,
      diesel: const [],
      pvc: const [],
      bit: const [],
      hammer: const [],
      start: DateTime(2026, 10, 5),
      end: DateTime(2026, 10, 5, 23, 59, 59, 999),
    );
    expect(day.bills, 1);
  });

  test('PVC purchases of side bore rigs are ignored', () {
    final s = PortfolioCalculator.compute(
      bills: const [],
      diesel: const [],
      pvc: [pvc(d1, 500, v: 'side'), pvc(d1, 300, v: 'main')],
      bit: const [],
      hammer: const [],
      sideBoreVehicleIds: {'side'},
    );
    expect(s.pvc, 300);
  });

  test('money sums do not drift', () {
    final bills = [
      for (var i = 0; i < 10; i++)
        bill('$i', 'a', d1, total: 0.1, received: 0.1),
    ];
    final s = PortfolioCalculator.compute(
        bills: bills,
        diesel: const [],
        pvc: const [],
        bit: const [],
        hammer: const []);
    expect(s.total, 1.0);
    expect(s.received, 1.0);
  });
}
