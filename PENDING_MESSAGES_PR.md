# PR title

feat: keep messages pending while offline - WPB-26307

# PR description

<!--do not remove the jira markers to link tickets automatically -->
<!--jira-description-action-hidden-marker-start-->

<!--jira-description-action-hidden-marker-end-->

### Issue

Milestone 0 of the PRD "Pending connection, pending invite, pending message", covering pending messages only. Pending connections and invites are not part of this PR.

Today a message written while offline fails after about 60 seconds and has to be resent by hand. With the new developer flag `offlinePendingMessages` turned on, text messages stay pending and are sent automatically once the network is back, including after an app restart.

**Approach:** this extends the existing send path in `ClientMessageRequestStrategy` and doesn't add a separate outbox.
- **Waits for the network:** before each send attempt, the strategy waits until reachability says the backend may be reachable.
- **Doesn't fail while offline:** if a send fails because we're offline, or because the background task was cancelled, the message stays pending. It's sent again later with the same nonce, so receivers deduplicate it. Other transient errors are retried 3 times. Permanent errors expire the message as before.
- **Not expired on restart:** pending messages are no longer expired after an app restart.
- **Ordering:** the existing rule that a message only waits for earlier messages from the last 3 minutes now also covers older pending messages from the self user, so they're still sent in order.
- **New `sendAttemptStarted` attribute:** added to `ClientMessage` in data model 2.145.0. It's set just before the first send attempt.
- **In-place edit:** while `sendAttemptStarted` is false, editing a pending text message replaces its text and keeps the nonce. Receivers only see the final text, without an "Edited" marker. Once sending has started, the normal edit is used, or an alert is shown if the edit races with the send.
- **Local delete:** while `sendAttemptStarted` is false, a new pending text message can be deleted ("Delete for Me"). It's removed locally only, since nobody else has it.

Edits and deletes of pending messages run on the sync context, which is also where the strategy sets `sendAttemptStarted`, so they can't race with a send.

Ephemeral messages and assets keep today's behaviour.

**Known limitations / follow-ups**
- **Not yet:** pending messages don't yet stay at the bottom of the conversation when newer messages arrive (PRD M0 note). This will come in a follow-up PR.
- **Editing on a flaky network:** if the device looks online but requests fail, `sendAttemptStarted` is already set, so the message can no longer be edited or deleted in place.
- **Duplicate deliveries:** a resent message has the same nonce, so receivers deduplicate it. The iOS notification extension may still show a second banner. We still need to confirm with the Android, Web and MLS owners that their dedup works the same way.
- **Schema version:** the schema bump uses 2.145.0. I moved the planned `commitPendingProposalDate` removal entry to 2.146.0. Whichever of the two lands second has to renumber.

### Testing

Turn on Developer settings → `offlinePendingMessages` and restart the app. Use a second account to receive.

1. Offline: send a message and wait more than 1 minute. It stays pending. Go back online and it's delivered once, without tapping Retry.
2. Offline: send several messages more than 3 minutes apart. After reconnecting they arrive in order.
3. Offline: edit a pending message. After reconnecting the receiver only sees the new text, with no "Edited" marker.
4. Offline: edit a message that was already delivered, then edit it again. The receiver sees the final text with the "Edited" marker.
5. Offline: kill and relaunch the app. The message is still pending and is sent after reconnecting.
6. Offline: send, then lock the phone and reconnect. The message is delivered, either in the background or when the app is opened.
7. Offline: delete a pending message ("Delete for Me"). The receiver never sees it.
8. Self-deleting messages, and everything with the flag off, behave as before.

Unit tests:
- `ClientMessageRequestStrategyTests`
- `OTREntityTests_Dependency`
- `ZMClientMessageTests_PendingText`
- the database migration tests for 2.145.0

---

### Checklist

- [x] Title contains a reference JIRA issue number like `[WPB-XXX]`.
- [x] Description is filled and free of optional paragraphs.
- [x] Adds/updates automated tests.

---

### UI accessibility checklist

- [x] Make sure you use the API for UI elements that support large fonts.
- [x] All colors are taken from WireDesign.ColorTheme or constructed using WireDesign.BaseColorPalette.
- [x] New UI elements have Accessibility strings for VoiceOver.

The only new UI is two system alerts (`UIAlertController`).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_0126T3TR7JLgpH6bwpF2wAWp
