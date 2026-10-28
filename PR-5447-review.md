# PR #5447 review

PR: [feat: keep messages pending while offline - WPB-25320](https://github.com/wireapp/wire-ios/pull/5447)

Reviewed commit: `3ec088a4194aea9f1d36fc06476253662b6eac98`

## Findings

### [P1] bug: Offline waits block session teardown

Location: `wire-ios-request-strategy/Sources/Request Strategies/Client Message/ClientMessageRequestStrategy.swift:215–217`

The send task enters the sync context’s primary dispatch group before reaching the indefinite reachability wait. `ZMOperationLoop.tearDown()` waits synchronously for that group to empty, and session close runs teardown on the sync context’s queue.

Closing a session with an offline pending message therefore stalls teardown. Reconnecting cannot finish the task because its next `context.perform` is queued behind teardown.

The wait needs a cancellation path that releases the group before session shutdown.

### [P1] bug: Restored messages retain their expiration deadline

Location: `wire-ios-request-strategy/Sources/Request Strategies/Client Message/ClientMessageRequestStrategy.swift:129–130`

`MessageSender` persists an `expirationDate` before issuing a request. If the app is killed during that request and relaunched offline after the deadline, bypassing stale-message expiration does not clear that date.

`MessageExpirationTimer` still expires the message during bootstrap, and the retry loop subsequently rejects it as no longer needed.

Clear the persisted expiration and prevent the timer from expiring restored pending messages.

### [P2] bug: Reconnecting during editing can silently discard text

Location: `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:848–852`

Start editing an unsent text message offline, reconnect, then save while its send is still pending. Once `sendAttemptStarted` reaches the UI context, `isEditableInPlace` becomes false and the handler falls through to `editText`.

That method rejects an unsent plain text message because `isSent` is false, silently discarding the edit without showing the new failure alert.

Route this pending state through the sync-context validation or explicitly report the failure.

### [P2] bug: Ordering still excludes older pending messages

Location: `wire-ios-request-strategy/Sources/Helpers/ZMMessage+Dependency.swift:111–115`

Removing the three-minute cutoff does not remove `conversation.lastMessages()`’s default limit of 256 visible messages. After incremental sync brings in a larger backlog, queued messages can fall outside that window.

Their dependency checks then miss earlier pending messages, allowing concurrent sends and out-of-order delivery.

Fetch earlier pending messages independently of the visible-history limit.

## Validation

- All 27 focused tests in `ClientMessageRequestStrategyTests` and `OTREntityTests_Dependency` passed on the iPhone 17 simulator running iOS 26.5.
- `git diff --check` passed for the reviewed PR diff.
- The findings above come from tracing the lifecycle and race conditions in the implementation; the focused tests do not exercise those scenarios.
- No implementation files were changed during the review.
