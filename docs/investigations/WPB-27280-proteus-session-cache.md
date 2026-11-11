# WPB-27280: Proteus sessions corrupted across app and extension processes

Status: investigation findings, November 2026. No product fix has been applied yet.
Customer-specific evidence is kept in the Jira ticket, not in this repository.

## In plain words

**What's broken.** CoreCrypto keeps an in-memory copy of each Proteus session and never checks whether
the database has changed since. On iOS, Wire runs as three processes that share one crypto database: the
app, the notification service extension (NSE) and the share extension. Each process has its own copy. When
one process updates a session, another can keep using its outdated copy, and when it saves, the newer
version is overwritten.

**Why only iOS sees it.** Desktop and web run as a single process, so their copy is always current.

**Why incoming messages fail but sending works.** Every time a device receives a message, the Proteus
ratchet creates a new secret key. The next outgoing message carries the matching public part, and the
other side encrypts its replies for it. If an outdated copy overwrites the session, that new secret key is
lost. The other side keeps encrypting for it, so every incoming message from that device fails with
error 406. Outgoing messages use separate keys and keep working.

**Why broken chats don't heal by themselves.** The other side only switches keys after receiving a
message based on our newest key, and our damaged session can no longer produce one. Preventing new damage
does not repair sessions that are already broken.

## Root cause (CoreCrypto 10.5.3 / 10.5.4, Proteus 3.0.1)

- `crypto/src/proteus/session_cache.rs`: a cache hit returns the in-memory session; only a miss reads the
  database. The cache lives as long as the CoreCrypto instance, not a single transaction.
- `crypto/src/transaction_context/mod.rs`: starting a transaction does not clear the Proteus cache.
  `finish()` (on a failed commit) and `abort()` clear the MLS conversation cache but **not** the Proteus cache, so a
  rolled-back transaction leaves the in-memory session ahead of the database.
- `crypto/src/proteus/message.rs`: every successful encrypt/decrypt saves the cached session, without
  checking it against the database.
- Transactions are already serialized across processes (SQLite `BEGIN IMMEDIATE` plus an exclusive
  `flock` on the database's directory in the Swift wrapper). The problem is not missing locking; the cache
  is simply stale.
- The relevant code is unchanged between 10.5.3 and 10.5.4.

Error codes, as implemented in Proteus `src/internal/session.rs`:
- **406** (`InvalidSignature`): MAC check failed. This also happens for ordinary messages, not only
  prekey messages. It is what a lost or outdated ratchet key produces.
- **202** (`InvalidMessage`): unknown session tag, i.e. the session was replaced or lost.

## Reproduction

Synthetic keys and databases only; no customer data. Two CoreCrypto instances, or two simulator
processes, open the same database file. Each holds its own cache, like the app, NSE and share extension do.

| Scenario | Without refresh | With refresh at the start of each transaction |
|---|---|---|
| Another instance replaces the session; stale instance decrypts | 202 | OK |
| Another instance advances the ratchet; stale instance decrypts | 406 (recoverable by refresh) | OK |
| Another instance receives and sends; stale instance then **sends** | **406 on every incoming message, even in a fresh instance**; outgoing OK | OK |
| App and NSE only, NSE decrypts with stale cache | **406 permanently** | OK |
| Share-like instance only sends; stale app sends the same message again | Recipient rejects the second copy (`DuplicateMessage`); no local failure | — |
| Decrypt, then the transaction rolls back; retry | `DuplicateMessage` (cache ahead of database) | OK |

Conclusions:
- Stale *reads* fail but can be recovered. Stale *successful writes* corrupt the stored session
  permanently. Refreshing only after an error is therefore not enough; it has to happen before every use.
- The share extension is not required: the app and the NSE alone can corrupt sessions. The share
  extension is one more process in the mix.

## Customer log evidence (summary)

Details and per-case counts are in the Jira ticket. In one log bundle, the share extension and the app
uploaded the same asset (same message nonce) and both posted a Proteus message to the same group
within about half a second. Shortly before, the NSE had decrypted Proteus messages while the app had not.
Two 406 failures in the app followed. The logs do not include sender or session IDs, so these failures
cannot be tied to that overlap with certainty. The evidence is consistent with this mechanism but does not prove it.

## Related iOS issues

1. **Session creation after a 412 response does not check for an existing session.**
   `UserClient.establishSessionWithClient` → `ProteusService.establishSession` creates a session from a
   prekey in its own transaction (see the TODO in `UserClient.swift`). CoreCrypto replaces any existing
   session. A process with an outdated view can overwrite a session another process just set up.
2. **Session reset does not repair Proteus for MLS one-to-one conversations.** The reset message is
   sent through the user's one-to-one conversation (`ResetSessionRequestStrategy`). `MessageSender` picks
   the protocol from that conversation, so for MLS no Proteus message is sent and the deleted session is
   not rebuilt. Failed-decryption notices are still marked as resolved after a successful send.
3. **App and share extension can both send the same message.** Send strategies have no notion of which
   process owns an outgoing message. With fresh session state this wastes uploads and creates duplicate
   copies. Recipients deduplicate by nonce, so it does not corrupt sessions.

## Proposed approach

Release mitigation (iOS):
- In `SafeCoreCrypto.transaction`, call `context.proteusInit()` at the start of every transaction, before
  running the caller's block. This rebuilds the Proteus cache from the database once the transaction holds
  the write lock. Every Proteus operation found goes through this wrapper, including batch decryption with
  a supplied context. It does not delete sessions or change identity. If no identity exists,
  `proteusInit` would create one; the app already calls it when CoreCrypto starts up.
- In `ProteusService.establishSession`, skip creating the session if one already exists, checked in the
  same transaction.
- Update the shared transaction mocks so `proteusInit` is allowed.
- Confirm with CoreCrypto maintainers that repeated `proteusInit` calls are supported, and measure NSE
  batch-decrypt latency on a device.

Regression tests (real on-disk CoreCrypto, two instances on one database): session replacement (202),
ratchet advance (406), stale write followed by a fresh reader, app/NSE interleaving, rollback and retry,
batch decryption with a supplied context, and session creation when a session already exists.

Still needed:
- **Repair of already-broken sessions.** The fix above only prevents new damage. Session reset must
  actually rebuild Proteus for users whose one-to-one conversation uses MLS. Automatic reset after
  repeated 406s from the same client is worth considering.
- **Upstream CoreCrypto fix:** clear or scope the Proteus cache per transaction, and clear it on abort. The
  iOS workaround can then be removed.
- **Separate follow-ups:** decide which process owns an outgoing message; log the sender client/session
  ID (no content) on decryption failures so future reports can be attributed.
