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
