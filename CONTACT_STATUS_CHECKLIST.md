# Contact status implementation checklist

Temporary working checklist for branch `chore/connect-status-WPB-25316`.

Goal: disable the start-conversation action for explicitly non-contactable users in the profile and the profile opened from search. Keep the action visible. Explanatory hints are a follow-up.

## 1. Networking — implemented

- [x] Check the API v17 schema: optional `contact_status`, with required `state` of `contactable` or `non-contactable` when present.
- [x] Expose optional `WireNetwork.User.contactStatus`.
- [x] Decode the status for `GET /users/{domain}/{id}`, `POST /list-users`, and `GET /teams/{id}/apps` in v17 and later.
- [x] Mark the added property in `UserResponseV17` with an introduction-version comment.
- [x] Remove the initializer default and update existing call sites with explicit status arguments.
- [x] Add networking tests for both states, missing/null status, required state, older-version compatibility, and 404 handling.
- [x] Commit parsing and initializer cleanup separately (`636a3e8bd9`, `b3490abac8`).
- [ ] Run the networking tests; tests were left for manual execution.

## 2. Confirm behavior and the backend update contract

- [ ] Confirm that the search scope includes the profile opened from search; identify any additional search-row actions that must also be disabled.
- [ ] Confirm how the restriction applies to the separate “Connect” action, pending requests, and accepting requests.
- [ ] Preserve existing behavior for unknown status (older APIs or an omitted field).
- [ ] Preserve access to existing conversations; apply the restriction to initiating a connection/conversation.
- [ ] Confirm with the backend whether changing contactability emits an event, including its type, payload, recipients, and federation behavior.
- [ ] Record the agreed refresh behavior. Do not assume a live update event exists: the current client `user.update` decoder has no contact-status field, and the supplied schema does not establish an event contract.

## 3. Data model and persistence

- [ ] Add a data-model representation of unknown, contactable, and non-contactable status without depending on WireNetwork from the UI.
- [ ] Add an optional persisted contact-status attribute to `ZMUser`, with a typed accessor.
- [ ] Add a Core Data model version and wire it into the repository's migration setup.
- [ ] Verify migration from the previous model; existing users must start with unknown status. Check that lightweight migration is sufficient.
- [ ] Expose contact status through the Objective-C-compatible `UserType` interface.
- [ ] Implement status storage/access for `ZMSearchUser`, including search-only users and users backed by `ZMUser`.
- [ ] Define which value is authoritative when a search user has both a fetched profile and an attached local user.
- [ ] Update user mocks and test fixtures; regenerate mocks where required.

## 4. Carry status through profile processing

- [ ] Extend `NewUserInfo` and the `WireNetwork.User` mapping in `UserModelMappings.swift`.
- [ ] Persist the mapped value in `UserLocalStore.persistUser`.
- [ ] Extend the legacy `Payload.UserProfile` decoder and `UserProfilePayloadProcessor`, which are still used by profile refreshes.
- [ ] On authoritative full-profile responses, update or clear the cached status according to the response.
- [ ] Preserve cached status during unrelated partial updates that omit the field.
- [ ] Extend the `WireNetwork.User → ZMSearchUser` mapping in `SearchTask.swift`.
- [ ] Apply refreshed values to cached search users as well as newly created ones.
- [ ] Ensure team-app profiles carry the status through the same mappings.

## 5. Fetching and freshness

- [ ] Fetch a full profile when opening a user profile, including a profile opened from search.
- [ ] Add an explicit refresh path for search-only users: `ZMSearchUser.refreshData()` currently only forwards to an attached `ZMUser`.
- [ ] If search rows need the restriction before profile opening, enrich the relevant results through `/list-users`; `/search/contacts` does not contain contact status.
- [ ] Do not tie contact-status fetching to missing image assets; the existing asset-enrichment condition is insufficient.
- [ ] Refresh cached values when revisiting the profile and when returning to the foreground with that profile visible.
- [ ] Handle loading and fetch failures explicitly; retain a previously known restriction if a refresh fails.
- [ ] If the backend confirms a change event, implement its decoding, processing, persistence, and UI notification path.
- [ ] Otherwise, document that a change is discovered on refresh. Decide whether live re-enabling while the screen remains open requires polling; avoid adding polling without an agreed requirement.

## 6. Observation and UI

- [ ] Add contact-status change observation for `ZMUser` and `ZMSearchUser`.
- [ ] Extend `UserChangeInfo` or the relevant observation mechanism so consumers can detect the change.
- [ ] Update `ProfileViewControllerViewModel` to recompute action state after a status change.
- [ ] Add enabled state to the profile action/footer configuration; `ProfileFooterView` currently configures actions without this state.
- [ ] Disable the visible “Start conversation” action when status is explicitly non-contactable.
- [ ] Apply the agreed behavior to any equivalent “Connect” entry points without hiding the intended disabled action.
- [ ] Guard action handlers against starting the operation while the user is known to be non-contactable.
- [ ] Re-enable the action after a successful refresh reports contactable status, while retaining existing permission checks.
- [ ] Reset enabled state when configuring/reusing the footer or a search cell.
- [ ] Verify disabled styling and VoiceOver's disabled-state announcement; preserve accessibility identifiers.

## 7. Validation and completion

- [ ] Test persistence and migration, including unknown values for existing users.
- [ ] Test modern and legacy profile processing, including full versus partial updates.
- [ ] Test fresh and cached search users, with and without an attached local user.
- [ ] Test that profile fetching is independent of whether profile images are already available.
- [ ] Test action state for contactable, non-contactable, and unknown status.
- [ ] Test the non-contactable → contactable transition and the reverse transition after refresh.
- [ ] Test refresh failures and preservation of a previously known restriction.
- [ ] Test handler guards, existing-conversation access, and the agreed behavior of connection-request actions.
- [ ] Test the backend event path if one is supported and implemented.
- [ ] Run relevant networking, data-model, request-strategy, domain, sync-engine, and UI tests for the changed paths.
- [ ] Manually verify profile and search flows, foreground refresh, disabled appearance, and accessibility.
- [ ] Run formatting, lint, and diff checks for the final changes.
- [ ] Remove this temporary checklist before the final PR, or move remaining work into tracked follow-up issues.

## Follow-up: explanatory hints

- [ ] Agree on localized hint text and placement in the profile and search UI.
- [ ] Add the hint using dynamic-type-compatible UI and accessible text.
- [ ] Keep the hint synchronized with the same observed contact-status state.

## Networking test command

Run from the repository root:

```sh
bundle exec fastlane ios test_only_frameworks \
  folders:WireNetwork \
  only_testing:"WireNetworkTests/ContactStatusAPITests,WireNetworkTests/UsersAPITests,WireNetworkTests/TeamsAPITests"
```
