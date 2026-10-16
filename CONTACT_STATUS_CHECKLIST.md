# Contact status implementation checklist

Temporary working checklist for branch `chore/connect-status-WPB-25316`.

Goal: disable the start-conversation action for explicitly non-contactable users in the profile and the profile opened from search. Keep the action visible and show “You can communicate with [name] once they are set up.” below the avatar.

## 1. Networking — implemented

- [x] Check the API v17 schema: optional `contact_status`, with required `state` of `contactable` or `non-contactable` when present.
- [x] Expose optional `WireNetwork.User.contactStatus`.
- [x] Decode the status for `GET /users/{domain}/{id}`, `POST /list-users`, and `GET /teams/{id}/apps` in v17 and later.
- [x] Mark the added property in `UserResponseV17` with an introduction-version comment.
- [x] Remove the initializer default and update existing call sites with explicit status arguments.
- [x] Add networking tests for both states, missing/null status, required state, older-version compatibility, and 404 handling.
- [x] Commit parsing and initializer cleanup separately (`636a3e8bd9`, `b3490abac8`).
- [x] Add an explicit `includeContactStatus` argument to bulk user lookup; append `include-contact-status=true` only when requested on v17 and later.
- [x] Add request tests covering opt-in, opt-out, and older API versions; update callers and mock usages.
- [ ] Run the networking tests; tests were left for manual execution.

## 2. Confirm behavior and the backend update contract

- [x] Scope confirmed: implement the profile reached through contact-list plus → select a user. Separate search-row actions are outside this step.
- [ ] Confirm how the restriction applies to the separate “Connect” action, pending requests, and accepting requests.
- [x] Preserve existing behavior for unknown status (older APIs or an omitted field); loading also preserves current behavior.
- [x] Preserve access to existing conversations; restrict the “Start conversation” action in this step.
- [ ] Confirm with the backend whether changing contactability emits an event, including its type, payload, recipients, and federation behavior.
- [ ] Record the agreed refresh behavior. Do not assume a live update event exists: the current client `user.update` decoder has no contact-status field, and the supplied schema does not establish an event contract.

## 3. Pass status through without persistence or shared caching

Decision: keep contact status in screen/view-model state for this iteration. Do not add a Core Data attribute or migration, or store status on shared/cached `ZMUser` / `ZMSearchUser` objects.

- [x] Pass contactability as `Bool?` through an injected fetch closure: nil is unknown. No additional domain model is needed for this screen.
- [x] Inject a fetch closure that calls `/list-users` with `includeContactStatus: true` for the displayed user, without persisting or caching the profile.
- [x] Wire the fetch closure at profile construction using the session component’s existing users API.
- [x] Pass the result to the profile view model, including profiles opened from search. Keep the status only for that screen's lifetime.
- [ ] Where an existing full-profile lookup supplies the initial status after explicitly opting in, pass it explicitly as screen input rather than storing it on the cached search user.
- [x] Update affected protocols, mocks, and constructor call sites.

## 4. Fetching and freshness

- [x] Fetch status when opening a profile, including profiles of search-only users and users already present locally.
- [x] Use a separate fetch instead of `ZMSearchUser.refreshData()`, which only forwards to an attached `ZMUser`.
- [ ] If search rows need the restriction before profile opening, fetch profiles for the relevant results through `/list-users` and keep results in the search screen's state. `/search/contacts` does not return contact status. The opt-in is documented on `/list-users`, not on single-user lookup; use the bulk endpoint with `includeContactStatus: true`.
- [x] Keep status fetching independent of missing image assets and existing search-user caches.
- [x] Refresh on profile reappearance and when returning to the foreground with that profile visible.
- [ ] Distinguish loading, fetch failure, and a successful response with unknown status; agree on initial button behavior during loading.
- [x] Preserve a known restriction within the current screen if a refresh fails. Discard screen state when the screen is closed.
- [x] Cancel fetches on disappearance and reject cancelled or superseded results.
- [x] Without a confirmed backend event, changes are discovered on refresh. Polling is not part of this iteration.

## 5. UI

- [x] Update the profile details and footer directly from `ProfileViewControllerViewModel` after fetching, without Core Data notifications.
- [x] Add contactability state to `ProfileFooterView` and apply it when actions are configured.
- [x] Disable the visible “Start conversation” action when status is explicitly non-contactable.
- [ ] Apply the agreed behavior to any equivalent “Connect” entry points without hiding the intended disabled action.
- [x] Guard the footer tap and conversation-start handler while the current screen knows the user is non-contactable.
- [x] Re-enable the action after a successful refresh reports contactable status, while retaining existing permission checks.
- [x] Reset enabled state when configuring the profile footer.
- [ ] Verify disabled styling and VoiceOver's disabled-state announcement; preserve accessibility identifiers.

## 6. Validation and completion

- [x] Add focused tests for restricted/unknown status, re-enabling, refresh failure, cancellation, handler guards, footer reuse, existing-conversation access, and the hint text/accessibility. These have not been executed.

- [ ] Test direct API-to-domain status mapping without writes to local user storage.
- [ ] Test profile and search flows for users with and without an attached local user.
- [ ] Test that status fetching is independent of profile images and cached search users.
- [ ] Test action state for contactable, non-contactable, unknown, loading, and fetch failure.
- [ ] Test both status transitions after refresh and retention of a known restriction on refresh failure within the same screen.
- [ ] Test cancellation/stale responses and fresh fetching after closing and reopening a screen.
- [ ] Test handler guards, existing-conversation access, and the agreed behavior of connection-request actions.
- [ ] Run relevant networking, domain, and UI tests for the changed paths. Test execution remains with the user in this session.
- [ ] Manually verify profile and search flows, foreground refresh, disabled appearance, and accessibility.
- [x] Run formatting, lint, syntax parsing, and diff checks; tests and simulator verification remain with the user.
- [ ] Remove this temporary checklist before the final PR, or move remaining work into tracked follow-up issues.

## Profile hint — implemented

- [x] Use the requested hint text below the profile header, including profiles opened from search.
- [x] Add the localized hint using a Dynamic Type label with an accessibility identifier.
- [x] Drive the hint from the same screen/view-model status as the button.

## Follow-up: live updates and broader reuse

- [ ] If the backend confirms a status-change event, route it to visible screens and refresh or update their state without requiring persistence.
- [ ] Revisit shared caching or persistence only if later requirements need offline status or reuse across screens; localized hints alone do not require it.

## Networking test command

Run from the repository root:

```sh
bundle exec fastlane ios test_only_frameworks \
  folders:WireNetwork \
  only_testing:"WireNetworkTests/ContactStatusAPITests,WireNetworkTests/UsersAPITests,WireNetworkTests/TeamsAPITests"
```

## Profile test command

Run from the repository root:

```sh
bundle exec fastlane ios test_only_frameworks \
  folders:wire-ios \
  only_testing:"Wire-iOS-Tests/ProfileViewControllerViewModelTests,Wire-iOS-Tests/ProfileViewControllerTests,Wire-iOS-Tests/ProfileFooterViewTests,Wire-iOS-Tests/ProfileDetailsViewControllerTests"
```
