# RigLedger - Business Domain Glossary

## Core concepts

**Rig / Vehicle**: A borewell drilling machine. The app supports multiple rigs. Each rig has its own data (entries, agents, side ledger). Two types: Main Bore and Side Bore. In code: `Vehicle` model, `VehicleType` enum.

**Main Bore**: Standard borewell drilling. Uses 7-inch or 8-inch casing. Complex billing with depth, PVC, MS pipe, step rate, extra charges. Data: `LedgerEntry`.

**Side Bore**: Simplified drilling job. Simpler form: just depth, rate, received, balance. Implemented in code as a plain `LedgerEntry` saved via `ledgerEntriesProvider` (see `SideBoreFormScreen`), not `MiniLedgerEntry`.

**LedgerEntry**: A single drilling job record, used for both Main Bore and Side Bore jobs. Each job = one entry. Has a bill number assigned manually by the operator.

**MiniLedgerEntry**: An orphaned model. It has its own Hive box and is fully wired into `DatabaseService` (CRUD) and `SyncService` (backup/merge), but no screen or provider reads or writes it -- Side Bore uses `LedgerEntry` instead. Do not assume this is live; see `BACKLOG.md` for the decision to wire it up or remove it.

**Bill Number**: Manually entered free-text identifier for a job. Not auto-incremented by the app. Operator assigns numbers.

**Agent**: A broker/intermediary who brings customers (parties) to the rig operator. Vehicle-scoped (each rig has its own agent list). Agents are tracked per job for reporting and commission tracking (commissions themselves are handled outside this app).

**Party**: The customer who commissioned the borewell. There is no separate Party entity in the data model. The party is identified by the "address" field on an entry (which in practice contains the location/customer name).

**Depth (feet)**: How deep the borewell was drilled.

**Depth type (7inch / 8inch)**: The diameter of the casing pipe used. Determines which step rate bracket schedule applies.

**Step Rate**: An automatic surcharge calculated when drilling goes beyond 300 feet. Based on a fixed bracket schedule per depth type. Currently hardcoded in `LedgerEntry.calculateStepRate()` -- not user-configurable. Can be manually overridden per entry.

**PVC**: Plastic casing pipe installed in the borewell. Measured in feet. Types: 7inch, 8inch.

**MS Pipe**: Mild steel pipe. `LedgerEntry.msPipe` is a free-text string field defaulting to `'6inch'`; the form dropdown currently only offers `'6inch'`. Measured in feet.

**Extra Charges**: Miscellaneous charges added to a job (travel, crane hire, etc.).

**Less**: A discount applied to reduce the total owed by the party. Subtracted from the total when calculating balance. Not a payment -- it is an adjustment/write-off.

**Balance**: Amount still owed by the party. Formula: `total - received - less`.

**Received**: Total payment collected from the party. Split into:
- `receivedCash`: Cash payment
- `receivedPhonePe`: UPI/digital payment via PhonePe

**PhonePe Name**: The sender's UPI display name on a PhonePe transaction. Used by the operator to reconcile which party made the payment.

**Side Ledger**: Operational expense tracking, separate from the main drilling ledger. Tracks the rig's own material and fuel costs. Four categories: Diesel, PVC, Bit, Hammer.

**Diesel Entry**: Fuel purchase. Tracks litres and total cost.

**PVC Entry (Side Ledger)**: PVC material purchase for the rig's stock (not installed in a job -- that is LedgerEntry.pvcInFeet). Multi-type: 7inch, 8inch, 10inch, MS. Tracks paid/pending/balance and storage location.

**Bit Entry**: Drill bit purchase. Multi-type with count and rate per type.

**Hammer Entry**: Hammer tool purchase. Multi-type with count and rate per type.

**TypeDetail**: Sub-record inside a side ledger entry (PVC/Bit/Hammer) representing one type variant: { type, count, rate }. Multiple TypeDetails can exist per entry to represent a mixed purchase. Stored as JSON in `typeDetailsJson`.

**Tombstone**: A record of a deletion, used during Drive sync. When entity X is deleted on device A, a tombstone is written so device B knows to delete X too during the next sync.

**Sync**: Bi-directional Google Drive backup/restore merge. One shared Google account across Android and macOS. Not real-time -- triggered periodically and on launch/resume.

## Business context

- Single user, single operator (the rig owner or manager).
- Primary use: track drilling jobs, billing, outstanding balances, and material costs.
- Secondary use: generate PDF/CSV reports for record-keeping and tax purposes.
- Currency: Indian Rupees (INR).
- No multi-user, no roles, no server-side authentication. All data is local.
- The operator may run multiple rigs -- each rig is a separate "Vehicle" with isolated data.
