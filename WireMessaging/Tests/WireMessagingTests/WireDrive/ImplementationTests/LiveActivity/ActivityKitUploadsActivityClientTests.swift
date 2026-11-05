//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import ActivityKit
import Foundation
import Testing

@testable import WireMessagingDomain

@MainActor
struct ActivityKitUploadsActivityClientTests {

    @Test
    func emptyAccountDoesNotAdoptOrDismissAnotherAccountsUpload() async {
        let uploadingAccount = UUID()
        let activity = FakeUploadsActivity(userID: uploadingAccount)
        let client = ActivityKitUploadsActivityClient(accountInfo: .init(userID: UUID()), activities: { [activity] })
        let controller = WireDriveUploadsLiveActivityController(
            observeUploads: WireDriveObserveDirectUploadsUseCase(),
            client: client
        )

        controller.start()
        await controller.endActivityIfNoUploads()
        await controller.stop()

        #expect(!client.hasActivity)
        #expect(activity.endCount == 0)
        #expect(activity.activityState == .active)
    }

    @Test
    func adoptsAndUpdatesOnlyTheAccountsActivityAfterRelaunch() async {
        let userID = UUID()
        let otherActivity = FakeUploadsActivity(userID: UUID())
        let ownActivity = FakeUploadsActivity(userID: userID, activityState: .stale)
        let client = ActivityKitUploadsActivityClient(
            accountInfo: .init(userID: userID),
            activities: { [otherActivity, ownActivity] }
        )
        let state = makeState(total: 2, progress: 0.5)

        #expect(client.hasActivity)
        await client.update(with: state)

        #expect(ownActivity.updates == [state])
        #expect(ownActivity.endCount == 0)
        #expect(otherActivity.updates.isEmpty)
        #expect(otherActivity.endCount == 0)

        await client.endAll()

        #expect(!client.hasActivity)
        #expect(ownActivity.endCount == 1)
        #expect(otherActivity.endCount == 0)
    }

    @Test
    func newBatchReplacesOnlyTheAccountsPreviousResults() async throws {
        let userID = UUID()
        let otherActivity = FakeUploadsActivity(userID: UUID())
        let previousResult = FakeUploadsActivity(userID: userID, activityState: .ended)
        var requestedActivity: FakeUploadsActivity?
        let state = makeState(total: 1)
        let client = ActivityKitUploadsActivityClient(
            accountInfo: .init(userID: userID, name: "Alice"),
            activities: { [otherActivity, previousResult] },
            requestActivity: { attributes, content in
                #expect(attributes.userID == userID)
                #expect(attributes.accountName == "Alice")
                #expect(content.state == state)
                let activity = FakeUploadsActivity(userID: attributes.userID)
                requestedActivity = activity
                return activity
            }
        )

        try await client.start(with: state)

        #expect(client.hasActivity)
        #expect(previousResult.endCount == 1)
        #expect(otherActivity.endCount == 0)
        #expect(requestedActivity?.attributes.userID == userID)

        await client.endAll()

        #expect(requestedActivity?.endCount == 1)
        #expect(otherActivity.endCount == 0)
    }

    @Test
    func dismissesRetainedResultsWithoutTouchingAnotherAccount() async {
        let userID = UUID()
        let ownActivity = FakeUploadsActivity(userID: userID)
        let otherActivity = FakeUploadsActivity(userID: UUID())
        var activities = [ownActivity, otherActivity]
        let client = ActivityKitUploadsActivityClient(accountInfo: .init(userID: userID), activities: { activities })

        await client.end(with: makeState(.failed), dismissal: .systemDefault)
        // ActivityKit may stop returning an ended activity while its result remains on the lock screen.
        activities = [otherActivity]
        await client.endAll()

        #expect(ownActivity.endCount == 2)
        #expect(otherActivity.endCount == 0)
    }

    @Test
    func legacyActivitiesWithoutAnOwnerAreNotAdoptedOrDismissed() async throws {
        let attributes = try JSONDecoder().decode(WireDriveUploadsActivityAttributes.self, from: Data("{}".utf8))
        let legacyActivity = FakeUploadsActivity(userID: attributes.userID)
        let client = ActivityKitUploadsActivityClient(
            accountInfo: .init(userID: UUID()),
            activities: { [legacyActivity] }
        )

        await client.endAll()

        #expect(attributes.userID == nil)
        #expect(!client.hasActivity)
        #expect(legacyActivity.endCount == 0)
    }

    @Test
    func accountOwnershipSurvivesEncodingAndDecoding() throws {
        let userID = UUID()
        let attributes = WireDriveUploadsActivityAttributes(accountInfo: .init(userID: userID, name: "Alice"))

        let restored = try JSONDecoder().decode(
            WireDriveUploadsActivityAttributes.self,
            from: JSONEncoder().encode(attributes)
        )

        #expect(restored.userID == userID)
        #expect(restored.accountName == "Alice")
    }

    @Test
    func fallsBackToTheHandleWhenTheAccountNameIsMissing() {
        let handleOnly = WireDriveUploadsActivityAttributes(accountInfo: .init(
            userID: UUID(),
            name: "  ",
            handle: " alice "
        ))
        let withName = WireDriveUploadsActivityAttributes(accountInfo: .init(
            userID: UUID(),
            name: " Alice ",
            handle: "alice"
        ))
        #expect(handleOnly.accountName == "@alice")
        #expect(withName.accountName == "Alice")
        #expect(WireDriveUploadsActivityAttributes(accountInfo: .init(userID: UUID(), handle: "@alice"))
            .accountName == "@alice")
    }

}

@MainActor
private final class FakeUploadsActivity: WireDriveUploadsActivity {

    let id = UUID().uuidString
    let attributes: WireDriveUploadsActivityAttributes
    var activityState: ActivityState
    private(set) var updates: [WireDriveUploadsActivityState] = []
    private(set) var endCount = 0

    init(userID: UUID?, accountName: String? = nil, activityState: ActivityState = .active) {
        self.attributes = WireDriveUploadsActivityAttributes(accountInfo: userID.map { .init(
            userID: $0,
            name: accountName
        ) })
        self.activityState = activityState
    }

    func update(_ content: ActivityContent<WireDriveUploadsActivityState>) async {
        updates.append(content.state)
    }

    func end(
        _ content: ActivityContent<WireDriveUploadsActivityState>?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        endCount += 1
        activityState = .ended
    }
}
