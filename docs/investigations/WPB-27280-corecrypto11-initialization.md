# WPB-27280: CoreCrypto 11 database initialization races

Status: confirmed against the released CoreCrypto **11.0.0** iOS simulator binary on 2026-11-12.
All experiments used synthetic keys, checkpoints and databases. No customer data is included here.

**Resolution:** fixed upstream in CoreCrypto **11.0.1** (2026-11-13), which iOS now pins.
[core-crypto#2852](https://github.com/wireapp/core-crypto/pull/2852) makes `Database::open` acquire the cross-process
`TransactionLock` before opening the connection, so salt migration, the `user_version` rewrite and schema migrations
all run under the same lock as transactions. This closes the salt-migration race (part 1 of the proposal below). It
should also replace the open-time `SQLITE_BUSY` with waiting for the lock, which has not been verified. 11.0.1 also
contains the #2844 cross-connection staleness fix. Parts 2 and 3 (atomic salt write with length check; fail closed for an
existing database without any salt source) are **not** in 11.0.1. With the lock in place they only matter for rarer
cases (termination during the salt write, a keychain item missing for other reasons) and are tracked as follow-up
hardening in WPB-29993. The sections below describe the original 11.0.0 analysis.

## Findings

Both failures originate in the iOS database-open path running outside CoreCrypto's cross-process transaction lock.
The concurrent migration can lose the correct encryption salt. Opening alongside an active transaction can fail
with `SQLITE_BUSY` before the opener attempts to acquire that lock.

The relevant released source is
[`connection/mod.rs`](https://github.com/wireapp/core-crypto/blob/v11.0.0/keystore/src/connection/mod.rs)
and [`ios_wal_compat.rs`](https://github.com/wireapp/core-crypto/blob/v11.0.0/keystore/src/connection/ios_wal_compat.rs).
The order is:

1. `Database.open_internal` opens the connection and sets its encryption key.
2. `handle_ios_wal_compat` reads or migrates the salt, then reads and rewrites `PRAGMA user_version`.
3. `Database.init` acquires `TransactionLock` and performs schema initialization and migrations.

Step 2 needs the same exclusion as step 3. The per-provider Swift actor does not coordinate different processes.

The salt-file migration race is specific to the 11 upgrade. The busy failure also reproduces with the released
**10.5.4** binary: it is a pre-existing database-open locking defect, rather than a new Swift object-lifetime regression.

## Confirmed salt-loss interleaving

The test saves the original legacy keychain salt before opening a 10.5.4 database with 11.0.0. A diagnostic library
pauses one opener immediately before its legacy `SecItemCopyMatching` call, after its salt-file read returned
`NotFound`. Another process then completes migration using the unmodified released binary.

| Process | Operation |
| --- | --- |
| B | Finds no `.salt` file, then pauses before looking in the keychain. |
| A | Reads the original keychain salt, writes `.salt`, deletes the keychain item, and opens successfully. |
| B | Resumes; the keychain query returns `errSecItemNotFound` (`-25300`). |
| B | Falls back to `persist_current_salt` without rechecking the file and overwrites A's valid salt. |
| B | Fails to read `PRAGMA user_version` with `SQLITE_NOTADB` (`26`). |

The incorrect salt in this forced schedule was exactly the database's 16-byte plaintext SQLite header,
`SQLite format 3\0`. The fallback queries `cipher_salt` before configuring `cipher_plaintext_header_size`, so it
treats the existing plaintext header as a salt. It must not take the new-database fallback for this existing database.

The database file's SHA-256 stayed unchanged during the failed second open. Reopening continued to fail until the
test restored **only the saved original salt**; all 20 checkpoint reads then passed. This confirms loss of the correct
salt, with intact encrypted database contents in this controlled case. That saved salt is a test control, not a general
recovery mechanism for a user whose original salt is already gone.

An ungated three-process stress run independently failed on its third fixture. All three readers returned
`SQLITE_READONLY` (`8`) at `PRAGMA user_version=0`, the salt no longer matched the saved original, and reopening
returned `file is not a database`. Restoring only the original salt recovered that fixture too. The readonly message
in this experiment does not indicate a filesystem permission change.

## Confirmed busy failure

One process opens a valid database and holds a real CoreCrypto transaction. A second process opens a separate
connection to the same database. SQLite statement tracing and `flock` tracing show:

| Holder duration | Opener result |
| --- | --- |
| 3 seconds | `PRAGMA user_version=48` waits about 3 seconds; open succeeds. |
| 8 seconds | The same statement fails after about 5.27 seconds with `SQLITE_BUSY`, primary and extended code `5`. |
| Holder finished | Twenty subsequent opens and checkpoint reads succeed. |

The failing opener never attempts the transaction-file lock. The compatibility path unconditionally rewrites
`user_version` to persist the plaintext header configuration, even on an already migrated database. Its write reaches
SQLite's busy timeout while the other connection owns `BEGIN IMMEDIATE`.

Idle surviving database handles also allow repeated opens. Destroying every old Swift object is therefore not the
fix for this failure. These are database-level probes; physical-device account switching, logout and re-login still
need end-to-end validation.

The same baseline experiment with 10.5.4 passed the 3-second case and returned primary/extended code `5` in the
8-second case. Its failing statement is `PRAGMA user_version=2`; see the
[10.5.4 compatibility code](https://github.com/wireapp/core-crypto/blob/v10.5.4/keystore/src/connection/ios_wal_compat.rs).
The proposed 11.x exclusion repairs this existing contention window as well as the new salt-migration race.

## Smallest proposed fix

The proposed upstream fix has three parts:

1. Use the existing asynchronous `TransactionLock` around iOS salt and header compatibility setup.
2. Atomically publish and flush the salt before deleting its legacy keychain item; validate its 16-byte length on read.
3. Allow `persist_current_salt` only when the database was just created (`!exists`). For an existing database with
   neither a salt file nor a legacy keychain item, fail without generating a replacement salt or modifying the database.
   Use the existence flag captured **before** `Connection::open`, which can itself create the database file.

The locking change belongs in **CoreCrypto**, around iOS compatibility setup:

```rust
#[cfg(target_os = "ios")]
if !path.is_empty() {
    let transaction_lock = TransactionLock::new(conn.path().unwrap_or_default())?;
    let _guard = transaction_lock.acquire().await?;
    ios_wal_compat::handle_ios_wal_compat(&conn, path)?;
}
```

This adds two statements before the existing compatibility call. Adjust the `clippy::unused_async` expectation on
`open_internal` to exclude iOS, which now awaits the lock. No public API changes are needed.

Use the connection's path for the existing lock-file identity, while retaining the **original caller-provided path**
for salt migration: that exact path determines the old keychain item name. The guard ends after compatibility setup;
the existing schema-initialization guard is subsequently acquired as before. The locks are not nested.

The separate string-to-bytes key migration already holds this same lock before calling compatibility setup in
[`migrations/mod.rs`](https://github.com/wireapp/core-crypto/blob/v11.0.0/keystore/src/connection/migrations/mod.rs).
Keep the compatibility function itself synchronous and do not add another lock inside it.

A separate startup-only lock would serialize new openers but would still allow them to collide with transactions
on existing handles. Increasing SQLite's timeout would leave the salt-loss race intact. The shared transaction lock
addresses both confirmed failures without changing `SafeCoreCrypto.transaction` or the Proteus 412/reset flows.

For a production-safe migration, make salt publication atomic in the same upstream change: write and flush a
same-directory temporary file, rename it into place, and only then remove the legacy keychain item. Validate the
16-byte salt length on read. The existing `fs::write` can leave an empty or partial authoritative sidecar if an NSE is
terminated during the write; locking alone does not close that interruption window. Do not regenerate a salt for an
existing database whose correct salt is unavailable.

## Validation of the proposed exclusion

A reference diagnostic guard acquired the **same** `<database>-cc-tx.lock` before compatibility setup and released it
before the existing schema-lock acquisition. It changed no database keys, salt values, transaction contents or SQLite
timeouts. With that exclusion added to the released binary:

- The forced race made the competing opener wait before inspecting the salt. Both processes completed all 40
  checkpoint reads, and the original salt was preserved.
- Twenty independent three-process first migrations passed all **1,200 checkpoint reads**, preserving every original
  salt. The unguarded comparison failed on its third fixture.
- The 8-second transaction case waited about **8.39 seconds** and opened successfully.

The reference guard validates the critical section. The proposed Rust patch and atomic-file implementation still
require an upstream build and regression tests; they have not been applied to the published iOS dependency.

Required upstream regressions: the forced missing-file/keychain interleaving; concurrent migrated and fresh database
opens; opening during a transaction longer than SQLite's busy timeout; termination before/after salt publication;
and an existing database with neither salt source, which must fail without changing its files.
Keep the separate cross-connection stale-session regression for the #2844 backport as well.

Before releasing the iOS upgrade, verify on a physical device: an in-place update from a used 10.5.4 installation with
app, NSE and share extension opening the keystore concurrently; locked-device NSE access; and account lifecycle flows.
