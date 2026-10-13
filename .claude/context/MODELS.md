# RigLedger - Full Model Schema

All models are Hive-backed (extend HiveObject). All have `id` (UUID string), `createdAt`, `updatedAt` (DateTime).
Serialisation note: LedgerEntry and Agent use `toMap()`/`fromMap()`. All other models use `toJson()`/`fromJson()`. Do not change without updating DatabaseService and SyncService.

---

## Vehicle (typeId: 4) -- lib/core/models/vehicle.dart

| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| name | 1 | String | Rig display name |
| vehicleTypeIndex | 2 | int | 0 = mainBore, 1 = sideBore |
| createdAt | 3 | DateTime | |
| updatedAt | 4 | DateTime | |

Computed getter: `vehicleType` returns `VehicleType` enum (mainBore / sideBore).
Default vehicle: id = `'default_vehicle'`, name = `'Main Rig'`, type = mainBore.
All other entities reference vehicleId as FK for data isolation between rigs.

---

## LedgerEntry (typeId: 0) -- lib/core/models/ledger_entry.dart

Main Bore drilling job record.

| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| date | 1 | DateTime | Job date |
| billNumber | 2 | String | Free-text, manually entered |
| agentId | 3 | String | FK to Agent.id |
| agentName | 4 | String | Denormalised from Agent (kept in sync via DatabaseService.updateAgentInLedgerEntries) |
| address | 5 | String | Customer/party location (no separate Party entity) |
| depth | 6 | String | '7inch' or '8inch' |
| depthInFeet | 7 | double | Depth drilled |
| depthPerFeetRate | 8 | double | Rate per foot |
| pvc | 9 | String | '7inch' or '8inch' |
| pvcRate | 10 | double | LEGACY -- kept for backward compat; use pvcPerFeetRate |
| msPipe | 11 | String | Type, e.g. '6inch' |
| msPipeRate | 12 | double | LEGACY -- kept for backward compat; use msPipePerFeetRate |
| extraCharges | 13 | double | Miscellaneous charges |
| total | 14 | double | Calculated or manually overridden |
| isTotalManuallyEdited | 15 | bool | True if user overrode calculated total |
| received | 16 | double | LEGACY total received (= receivedCash + receivedPhonePe; invariant not enforced at DB layer) |
| balance | 17 | double | total - received - less |
| less | 18 | double | Discount amount |
| notes | 19 | String? | |
| createdAt | 20 | DateTime | |
| updatedAt | 21 | DateTime | |
| pvcInFeet | 22 | double | PVC pipe installed |
| pvcPerFeetRate | 23 | double | PVC rate per foot |
| msPipeInFeet | 24 | double | MS pipe installed |
| msPipePerFeetRate | 25 | double | MS pipe rate per foot |
| stepRate | 26 | double | Calculated or manually overridden |
| isStepRateManuallyEdited | 27 | bool | |
| vehicleId | 28 | String | FK to Vehicle.id |
| receivedCash | 29 | double | Cash portion of payment |
| receivedPhonePe | 30 | double | UPI/PhonePe portion |
| phonePeName | 31 | String? | Sender's UPI name for reconciliation |
| paymentsJson | 32 | String? | v2.0.0 payment log: JSON list of `LedgerPayment` (see below) |
| depthCommissionRate | 33 | double | v2.0.0, Rs per foot of depth, default 0 |
| pvcCommissionRate | 34 | double | v2.0.0, Rs per foot of PVC, default 0 |
| msPipeCommissionRate | 35 | double | v2.0.0, Rs per foot of MS pipe, default 0 |
| commission | 36 | double | v2.0.0, calculated or manually overridden, NEVER part of `total` |
| isCommissionManuallyEdited | 37 | bool | v2.0.0 |

### Payments and commission (v2.0.0)

- `received`, `receivedCash`, `receivedPhonePe` stay the TOTALS everywhere (stats, export, balance).
- With a payment log: `receivedCash = unloggedCash + sum(cash payments)`, same for PhonePe. `unloggedCash` / `unloggedPhonePe` are getters (`received - sum(logs)`): money received before the log existed or typed without a receiver. Older bills are not migrated: all their received amount is "unlogged".
- `commission = depthInFeet x depthCommissionRate + pvcInFeet x pvcCommissionRate + msPipeInFeet x msPipeCommissionRate` (`LedgerEntry.calculateCommission`). Side bore has no PVC, so only the depth part applies. Never added to `total`.
- Rates are copied from the agent's defaults when a bill is created and can be edited per bill.

### Total formula

```
total = (depthInFeet x depthPerFeetRate) + stepRate + (pvcInFeet x pvcPerFeetRate) + (msPipeInFeet x msPipePerFeetRate) + extraCharges
balance = total - received - less
received = receivedCash + receivedPhonePe
```

### Types are user-defined (v2.0.1)

`depth`, `pvc` and `msPipe` stay plain Strings on the bill (`'9inch'`, `'9.5inch'`); old bills never depend on a list. The lists that the forms, filters and totals offer are `LedgerTypes` (below). A type is always a number of inches. Side bore bills keep the placeholders `'7inch'` / `'6inch'`, which never count as using a type.

### Step rate brackets (hardcoded in LedgerEntry.calculateStepRate -- not user-configurable yet)

7 inch: 0-300ft = 0 extra, 300-400 = +10/ft, 400-500 = +20/ft, 500-600 = +30/ft, 600-700 = +50/ft, 700-800 = +70/ft, 800-900 = +90/ft. Beyond 900: +20 per 100ft bracket cumulative.
8 inch: 0-300ft = 0 extra, 300-400 = +10/ft, 400-500 = +20/ft, 500-600 = +40/ft, 600-700 = +60/ft, 700-800 = +80/ft, 800-900 = +100/ft. Beyond 900: +20 per 100ft bracket cumulative.

These are extra-per-foot rates for feet within each bracket, applied cumulatively.

v2.0.1: `calculateStepRate(..., stepTable)` takes the table to use (`'7inch'`, `'8inch'`). Without it only the types `7inch` and `8inch` have a step rate; every other type has none (it used to fall back silently to the 8 inch table). A user-defined depth type picks its table in Settings > Ledger Types (`LedgerTypes.steps`, `stepTableFor`).

---

## LedgerTypes -- lib/core/models/ledger_types.dart (v2.0.1)

Not a Hive model. Plain class stored as one JSON string in the settings box under the key `ledgerTypes` (absent means the built-in lists). Fields: `depth` (default `7inch`, `8inch`), `pvc` (`7inch`, `8inch`), `ms` (`6inch`), `steps` (depth type -> `'7inch'` | `'8inch'` | `'none'`), `updatedAt`. Included in the backup as `ledgerTypes`, merged on Drive sync by latest `updatedAt` (`SyncService._mergeLedgerTypes`), restored from a backup only when the key exists. `LedgerTypesNotifier` (lib/core/providers/ledger_types_provider.dart): add (a size in inches), rename (updates every main bore bill and carries the step table), delete (refused while a bill uses the type, and for the last one). A type used by bills but missing from the list is shown in memory (`withUsedTypes`). Settings screen: lib/features/settings/ledger_types_screen.dart.

---

## MiniLedgerEntry (typeId: 9) -- lib/core/models/mini_ledger_entry.dart

Side Bore drilling job record (simplified version of LedgerEntry).

| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| vehicleId | 1 | String | FK to Vehicle.id |
| date | 2 | DateTime | |
| billNumber | 3 | String | Free-text |
| agentId | 4 | String | FK to Agent.id |
| agentName | 5 | String | Denormalised |
| address | 6 | String | Customer/party location |
| depth | 7 | double | Depth in feet |
| depthPerFeetRate | 8 | double | |
| total | 9 | double | depth x depthPerFeetRate |
| receivedCash | 10 | double | |
| receivedPhonePe | 11 | double | |
| phonePeName | 12 | String? | UPI sender name |
| balance | 13 | double | total - receivedCash - receivedPhonePe - less |
| less | 14 | double | Discount |
| notes | 15 | String? | |
| createdAt | 16 | DateTime | |
| updatedAt | 17 | DateTime | |

Computed getter: `totalReceived` = receivedCash + receivedPhonePe.

**Orphaned**: no screen or provider references `MiniLedgerEntry`. Side Bore
jobs are actually saved as plain `LedgerEntry` records via
`ledgerEntriesProvider` (see `SideBoreFormScreen`). This model's Hive box,
`DatabaseService` CRUD, and `SyncService` backup/merge are all still live --
only the UI path is missing. See `BACKLOG.md` for the wire-up-or-remove
decision.

---

## Agent (typeId: 1) -- lib/core/models/agent.dart

| Field | Type | Notes |
|---|---|---|
| id | String | UUID |
| vehicleId | String | FK to Vehicle.id (agents are vehicle-scoped) |
| depthCommissionRate | double | HiveField 7, v2.0.0 default commission Rs per foot of depth |
| pvcCommissionRate | double | HiveField 8, v2.0.0 |
| msPipeCommissionRate | double | HiveField 9, v2.0.0 |
| commissionRatesJson | String | HiveField 10, v2.0.1 JSON map of per-type prices keyed `depth:9inch`, `pvc:7inch`, `ms:6inch`; default ''. `rateFor(category, type)` returns the type price or falls back to the matching default rate above. Renaming or deleting a ledger type updates the keys (`DatabaseService.renameAgentRateType`/`removeAgentRateType`). |
| name | String | Broker/agent display name |
| createdAt | DateTime | |
| updatedAt | DateTime | |

Bill count computed on-the-fly via `DatabaseService.getAgentBillCount(agentId)` -- not stored.
When agent is renamed, all linked LedgerEntry.agentName fields are updated via `DatabaseService.updateAgentInLedgerEntries()`.

---

## DieselEntry (typeId: 5) -- lib/core/models/diesel_entry.dart

Side ledger: fuel.

| Field | Type | Notes |
|---|---|---|
| id | String | UUID |
| vehicleId | String | |
| date | DateTime | |
| litres | double | Quantity |
| amount | double | Total cost |
| updatedAt | DateTime | |

---

## PvcEntry (typeId: 6) -- lib/core/models/pvc_entry.dart

Side ledger: PVC pipe purchase. Supports multi-type selection via TypeDetail.

| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| vehicleId | 1 | String | |
| date | 2 | DateTime | |
| billNumber | 3 | String | |
| type | 4 | String | LEGACY single type ('7inch', '8inch', '10inch', 'MS') |
| count | 5 | int | LEGACY total count |
| rate | 6 | double | LEGACY single rate |
| total | 7 | double | Total cost |
| paid | 8 | double | Amount paid to supplier |
| pending | 9 | double | total - paid |
| balance | 10 | double | |
| paidDate | 11 | DateTime? | When payment was made |
| storagePlace | 12 | String | Where stored |
| notes | 13 | String? | |
| createdAt | 14 | DateTime | |
| updatedAt | 15 | DateTime | |
| types | 16 | List<String>? | DEPRECATED, use typeDetailsJson |
| typeDetailsJson | 17 | String? | JSON-encoded List<TypeDetail> (current approach) |

Available types: `PvcEntry.pvcTypes` = ['7 inch', '8 inch', '10 inch', 'MS'].

BitEntry and HammerEntry follow the same pattern and schema as PvcEntry.

---

## TypeDetail -- lib/core/models/type_detail.dart

Not a Hive model. Plain Dart class. Used by PvcEntry, BitEntry, HammerEntry.

| Field | Type | Notes |
|---|---|---|
| type | String | e.g. '7 inch', '8 inch' |
| count | int | Quantity |
| rate | double | Price per unit |

Computed: `total` = count x rate.
Stored as JSON string inside the parent entry's `typeDetailsJson` HiveField.
Encoding: `TypeDetail.encodeList(list)` -> String. Decoding: `TypeDetail.decodeList(jsonString)` -> List<TypeDetail>?.
Display helpers: `TypeDetail.displayTypes()`, `TypeDetail.displayDetailed()`, `TypeDetail.totalCount()`, `TypeDetail.totalAmount()`.

---

## LedgerPayment -- lib/core/models/ledger_payment.dart

Not a Hive model. Plain Dart class stored as JSON in `LedgerEntry.paymentsJson`
(like `TypeDetail`). Fields: `id`, `date`, `amount`, `mode` ('cash' | 'phonepe'),
`receiverBookId` (CashBook.id, optional), `payerName` (PhonePe sender),
`notes`. Encoding: `LedgerPayment.encodeList` / `decodeList` (never throws).
A payment with a receiver has a linked income `CashEntry`
(`sourceType: 'ledger_payment'`, `sourceId: LedgerEntry.id`,
`sourcePaymentId: payment.id`).

---

## Tombstone -- lib/core/models/tombstone.dart

Soft-delete marker for bi-directional Drive sync.

| Field | Type | Notes |
|---|---|---|
| entityId | String | ID of deleted entity (also used as Hive box key) |
| collection | String | Box name, e.g. 'ledger_entries', 'agents' |
| deletedAt | DateTime | When deletion happened |

Pruned after 30 days via `DatabaseService.pruneTombstones()`.
Applied during Drive sync merge: tombstone beats entity if `tombstone.deletedAt >= entity.updatedAt`.

---

## CashBook (typeId: 2) -- lib/core/models/cash_book.dart

Account Ledger book (also a receiver book). Global, not vehicle-scoped. Spec: `docs/features/cashbook/SPEC.md`.

| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| name | 1 | String | |
| createdAt | 2 | DateTime | |
| updatedAt | 3 | DateTime | |
| sortOrder | 4 | int | default 0 |
| kind | 5 | int | 0 = custom, 1 = receiver |

Serialisation: `toJson()`/`fromJson()`. Adapter not yet registered (T-CB02).

---

## CashEntry (typeId: 3) -- lib/core/models/cash_entry.dart

| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| bookId | 1 | String | FK to CashBook.id |
| date | 2 | DateTime | local date and time |
| amount | 3 | double | >= 0, rounded to 2 decimals |
| isCashIn | 4 | bool | |
| notes | 5 | String | may be empty |
| description | 6 | String? | |
| attachmentPaths | 7 | List<String>? | up to 3 |
| itemsJson | 8 | String? | |
| isDeleted | 9 | bool | trash flag |
| deletedAt | 10 | DateTime? | auto-purged after 30 days |
| transferGroupId | 11 | String? | links the two rows of a transfer |
| importedLegacyId | 12 | int? | reference app row id |
| createdAt | 13 | DateTime | |
| updatedAt | 14 | DateTime | |
| bookNameSnapshot | 15 | String? | |
| sourceType | 16 | String? | 'ledger_payment' |
| sourceId | 17 | String? | LedgerEntry.id |
| sourcePaymentId | 18 | String? | |

No stored balance: balances are computed. Getter `signedAmount`.

---

## CashNote (typeId: 11) -- lib/core/models/cash_note.dart

| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| date | 1 | DateTime | |
| text | 2 | String | |
| isCompleted | 3 | bool | |
| createdAt | 4 | DateTime | |
| updatedAt | 5 | DateTime | |

---

## Hive typeId registry

| Model | typeId |
|---|---|
| LedgerEntry | 0 |
| Agent | 1 |
| Vehicle | 4 |
| DieselEntry | 5 |
| PvcEntry | 6 |
| BitEntry | 7 |
| HammerEntry | 8 |
| MiniLedgerEntry | 9 |
| Tombstone | 10 |
| CashNote | 11 |
| CashBook | 2 |
| CashEntry | 3 |

typeIds 2, 3 (CashBook, CashEntry) and 11 (CashNote) were claimed by the Account
Ledger feature. Next free: 12.

When adding a new Hive model, check existing typeIds to avoid collision. Use the next available integer.
