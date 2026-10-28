# Pending messages (WPB-26307) – notes

## Which message types stay pending (flag `offlinePendingMessages` on)

Based on reading the code on this branch; not tested in the app except for text.

**Stay pending:** everything sent as a `ZMClientMessage` through `ClientMessageRequestStrategy`, except ephemeral messages:
- text, ping, location, reactions, edits, deletes, read and delivery receipts
- Drive messages ("multipart"), once they've been created
- Editing or deleting without the receiver seeing a change only works for plain text. Other types follow the existing rules.

**Assets with Drive off (`ZMAssetClientMessage`): unchanged**
- They go through `AssetV3UploadRequestStrategy` and `AssetClientMessageRequestStrategy`.
- Offline the upload fails, the message is marked failed and needs Retry. After a restart they still expire.
- They don't block later text messages, because the ordering exception only applies to `ZMClientMessage`.

**Drive on**
- Files are uploaded as Drive drafts, and sending first publishes them (`publishDraftsUseCase` in `ConversationInputBarViewController+SendButton.swift`). That needs the network.
- Offline, publishing fails and `_sendText` returns before the input bar is cleared. No message is created, and the text and attachments should stay in the input bar.
- The only feedback is a log entry: `Failed to publish drafts`. What the user actually sees hasn't been checked.
- Text-only messages with Drive on take the normal path and stay pending.

## Manual tests for other types (flag on, offline)

1. A ping, a location and a reaction stay pending and arrive after reconnecting.
2. An image or file with Drive off fails as before and works with Retry. A text sent after it still arrives.
3. Text only, with Drive on, behaves like text with Drive off.
4. A file with Drive on: nothing is sent and the input bar stays filled. Check how this looks to the user.
5. Online, send a Drive message, then go offline before it's delivered. It stays pending and arrives after reconnecting.

## What the PRD says about assets
PRD "Pending connection, pending invite, pending message":
- **M0, "Send message in a pending scenario 1":** "send a message while I am in a pending scenario". It doesn't name a message type, so assets are neither included nor excluded.
- **M0 note:** "Messages in pending state should stay floating at the bottom". This is the deferred Part 3.
- **M0, "Editing pending messages":** in scope for M0.
- **M2 (GA), "Sending of multipart messages when offline" (MEDIUM/LOW):** "As a Wire user with Drive, I want to be able to draft and send a message with attachments, that will be sent after I have internet connection again." It's marked "To be discussed".
- **Open questions:** "How to handle multipart messages (drive)".
- **No-Drive assets:** not mentioned anywhere.

## Follow-up PR: assets with Drive off (sketch)

### Current behaviour (from reading the code, not tested)
1. **Preprocessing** (`AssetsPreprocessor`): local, no network needed.
2. **Upload** (`AssetV3UploadRequestStrategy` via `ZMUpstreamModifiedObjectSync`):
   - On `tryAgainLater`, which is what we get offline, the object is retried, not expired.
   - It's expired only on `cancelled`/`expired` (`requestExpired`) or on a real error (`shouldRetryToSyncAfterFailed`).
   - In the background it uses a background URLSession, whose offline behaviour is unchecked.
3. **Message** (`AssetClientMessageRequestStrategy`): same pattern as text before our change.
   - It expires on restart (`!isFresh`) and on any `MessageSender` error.
   - Its deadline is checked by the shared `MessageExpirationTimer`, which lives in `ClientMessageRequestStrategy`.

**Step 0:** manual test with logs. Send an image offline with the flag on and check which of the above actually fails it (log lines with "asset" and "expir").

### Sketch
1. **Rule:** move `staysPendingWhileOffline` from `ZMClientMessage` up to `ZMOTRMessage`.
2. **Timer:**
   - `timerFired` ignores messages whose deadline has been removed, so the retry loop only needs `removeExpirationDate()` and no timer reference.
   - Extend the startup cleanup to assets.
3. **Shared retry loop:** move the loop, including releasing the groups while waiting, from `ClientMessageRequestStrategy` into a small `PendingMessageSending` helper. Both strategies use it, with their own `shouldBeSentPredicate`.
4. **Asset strategy:** skip expiring stale messages for pending messages and use the helper. If the user cancels the upload, the predicate no longer matches and the loop stops.
5. **Upload strategy:**
   - For pending messages, `cancelled`/`expired` while offline or in the background re-queue the upload instead of expiring the message.
   - Check that interrupted uploads resume after a restart; the encrypted data should still be in the cache.
   - Real errors still fail.
6. **Ordering:** the dependency fetch also includes `ZMAssetClientMessage`, so text and images stay in order. Within the 3-minute window that's already the rule today.
7. **UI:** check how an image waiting for the network looks (progress or pending, not failed) and that Cancel still works. Delete while pending stays text-only unless wanted for assets.
8. **Tests:**
   - `AssetClientMessageRequestStrategyTests`: the same cases as for text.
   - `AssetV3UploadRequestStrategyTests`: a cancel while offline keeps the message pending.

**Estimate:** about 150–250 lines plus tests.

**Risks:**
- Background URLSession behaviour.
- Large files: the upload restarts from the beginning.
- Long uploads block later text messages; already the case today within the 3-minute window.
