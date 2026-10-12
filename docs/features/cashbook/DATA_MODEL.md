# Cashbook - Data Model (reverse-engineered from a backup .db)

Source: SQLite file created by Android Room (has `room_master_table` and `android_metadata`). All examples below are synthetic.

## Tables and row counts (reference backup)
| Table | Rows | Purpose |
|---|---|---|
| accounts | 24 | Books (a "book" is called an account; the default is "Cash Book") |
| cashTransaction | 2008 | Entries (cash in / cash out), including soft-deleted |
| CurrencyNotes | 2134 | Reference data: banknote denominations per country (183 countries), used by a note-counting tool |
| notebook | 0 | Notes/to-do list (date, note, completed). Empty in the backup |
| room_master_table | 1 | Room housekeeping (identity_hash). Not replicated |
| android_metadata, sqlite_sequence | - | SQLite/Android housekeeping |

No explicit indexes and no foreign keys exist.

## Schema
```sql
CREATE TABLE accounts (_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL);
CREATE TABLE cashTransaction (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  date INTEGER NOT NULL, cash_out REAL NOT NULL, cash_in REAL NOT NULL, balance REAL NOT NULL,
  notes TEXT, description TEXT, bill TEXT, accounts TEXT,
  isDeleted INTEGER DEFAULT 0 NOT NULL, deletedDate INTEGER DEFAULT 0 NOT NULL,
  bill2 TEXT, bill3 TEXT, transactionType INTEGER NOT NULL DEFAULT 2);
CREATE TABLE CurrencyNotes (_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, denomination REAL NOT NULL, country TEXT, show TEXT);
CREATE TABLE notebook (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, date INTEGER NOT NULL, note TEXT, completed TEXT);
```

## Column dictionary: cashTransaction
| Column | Type | Meaning | Evidence |
|---|---|---|---|
| id | int autoincrement | Entry id | max id equals sqlite_sequence seq (2008), no gaps reused |
| date | int, epoch milliseconds (true UTC instant; the app renders it in the device local zone; verified: 03:30 PM IST stored as 10:00 UTC) | Date and time of the entry | Every value is a multiple of 1000 (seconds precision); range 2025-06-20 to 2026-10-07 |
| cash_in | real | Amount received | 0.0 for cash-out rows |
| cash_out | real | Amount paid | 0.0 for cash-in rows |
| balance | real | Running balance column | ALWAYS 0.0 in all 2008 rows: not stored, computed at display time |
| notes | text, nullable | The main one-line label users type (this is what is shown as the entry title). Unicode (Tamil) is stored as is | non-empty in 2004 rows |
| description | text, nullable | Secondary text. Empty/unused in the reference data | 0 non-empty rows |
| bill | text, nullable | Attachment (bill image) path or uri, slot 1 | all NULL in reference data |
| bill2, bill3 | text, nullable | Attachment slots 2 and 3 (added by later migrations, no NOT NULL) | all NULL |
| accounts | text | Book NAME (not id). The link to `accounts.name` is by string | all 2008 values match an accounts.name |
| isDeleted | int 0/1 | Soft delete flag (trash) | 31 rows deleted |
| deletedDate | int epoch ms, 0 when not deleted | When moved to trash | `isDeleted=1` iff `deletedDate>0` for all rows |
| transactionType | int | 1 = cash in, 2 = cash out (default 2) | type 1 rows all have cash_in>0, type 2 all have cash_out>0 |

## Proven invariants
1. At most one of cash_in / cash_out is non-zero per row (both are never non-zero); transactionType matches it (1 in, 2 out). Both-zero rows are possible (the app accepts a 0 amount) but absent from the reference data.
2. Amounts are non-negative; the app rounds to 2 decimals on save (typed 1.239 stored 1.24) and also accepts zero amounts (verified on test data); the reference data has only whole numbers (max in 500000, max out 600000) but the column is REAL so decimals are allowed by the schema.
3. balance is never stored (all zero). Running balance and totals are derived from non-deleted rows.
4. Soft delete: isDeleted=1 with deletedDate set; deleted rows stay in the table.
5. Book link is by name, so renaming a book must rewrite cashTransaction.accounts (or the original loses the link). Not verified in the app yet; see BEHAVIOUR.md.
6. No timestamps for createdAt/updatedAt exist: `date` is the only time field, so there is no per-row modification time (matters for RigLedger sync, see SPEC.md).

## Other tables
- accounts: `_id` autoincrement, `name` unique in practice (not enforced). Default book "Cash Book" is _id 1. 24 books in the reference data.
- CurrencyNotes: `denomination` real, `country` ISO-like 2-letter code (183 distinct), `show` text, always 'show' (a visibility toggle for a denomination). Seeded constant data for a banknote counter tool; not part of bookkeeping.
- notebook: `date` epoch ms, `note` text, `completed` text flag (values unknown, table empty). To be confirmed via the UI.

## Synthetic examples
| id | date (UTC) | cash_in | cash_out | notes | accounts | isDeleted | transactionType |
|---|---|---|---|---|---|---|---|
| 1 | 2026-01-05 09:30:00 | 2500.0 | 0.0 | Advance from client A | Site Book | 0 | 1 |
| 2 | 2026-01-05 12:10:00 | 0.0 | 400.0 | Diesel top up | Site Book | 0 | 2 |
| 3 | 2026-01-06 08:00:00 | 0.0 | 150.0 | Tea and snacks | Site Book | 1 (deletedDate 2026-01-07 10:00:00) | 2 |

Derived: running balance after row 2 = 2500 - 400 = 2100 (row 3 excluded because deleted).

## Notes from a fresh backup produced by the app (see BEHAVIOUR.md B16)
- PRAGMA user_version = 6. Same tables. Column order of cashTransaction differs between an old upgraded database and a fresh one (bill2, bill3 come after bill in a fresh one), so import by column name.
- The Room identity hash row exists in room_master_table; ignore it on import.
- Transfers are two independent rows (cash out in source with notes "To <book>" newline notes, cash in in destination with "From <book>" newline notes); there is no link column.
- Opening balance is a normal row (notes "Opening Balance").
