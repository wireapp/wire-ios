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

import WireAnalytics
import WireDataModel
import WireDataModelSupport
import WireFoundation
import WireFoundationSupport
import WireSyncEngineSupport
import XCTest

@testable import WireSyncEngine

final class ToggleMessageReactionUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var analyticsEventTracker: AnalyticsEventTrackerProtocolMock!
    private var sut: ToggleMessageReactionUseCase!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var coreDataStack: CoreDataStack!
    private let modelHelper = ModelHelper()

    private var conversation: ZMConversation!
    private var firstMessage: ZMMessage!

    // MARK: - setUp

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()

        analyticsEventTracker = AnalyticsEventTrackerProtocolMock()
        analyticsEventTracker.trackEventEventAnalyticsEventVoidClosure = { _ in }

        sut = ToggleMessageReactionUseCase(analyticsEventTracker: analyticsEventTracker)

        (conversation, firstMessage) = try await setupConversationWithMessage()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        analyticsEventTracker = nil
        coreDataStack = nil
        coreDataStackHelper = nil
        conversation = nil
        firstMessage = nil
    }

    // MARK: - Helper Methods

    private func setupConversationWithMessage() async throws -> (conversation: ZMConversation, message: ZMMessage) {
        try await coreDataStack.viewContext.perform { [self] in
            let conversation = modelHelper.createGroupConversation(in: coreDataStack.viewContext)
            let selfUser = modelHelper.createSelfUser(in: coreDataStack.viewContext)
            let messages = try modelHelper.addTextMessages(
                to: conversation,
                messagePrefix: "Hello",
                sender: selfUser,
                count: 1,
                in: coreDataStack.viewContext
            )

            let firstMessage = try XCTUnwrap(messages.first)
            firstMessage.markAsSent()
            return (conversation, firstMessage)
        }
    }

    // MARK: - Unit Tests

    func testToggleMessageReaction_AddLikeReaction() throws {
        // GIVEN

        // WHEN
        sut.invoke("❤️", for: firstMessage, in: conversation)

        // THEN
        XCTAssertTrue(firstMessage.usersReaction.keys.contains("❤️"), "Expected the first message to have a ❤️ reaction.")

        XCTAssertEqual(
            analyticsEventTracker.trackEventEventAnalyticsEventVoidReceivedInvocations,
            [
                AnalyticsEvent.Contributed.conversationContribution(
                    .likeMessage,
                    conversationType: .group,
                    conversationSize: 0
                )
            ]
        )
    }

    func testToggleMessageReaction_RemoveLikeReaction() throws {
        // GIVEN
        ZMMessage.addReaction("❤️", to: firstMessage)

        // WHEN
        sut.invoke("❤️", for: firstMessage, in: conversation)

        // THEN
        XCTAssertFalse(
            firstMessage.usersReaction.keys.contains("❤️"),
            "Expected the ❤️ reaction to be removed from the first message."
        )
        XCTAssertEqual(
            analyticsEventTracker.trackEventEventAnalyticsEventVoidReceivedInvocations.count,
            0,
            "Removing reactions should not trigger analytics events."
        )
    }

    func testToggleMessageReaction_MultipleReactions() throws {
        // GIVEN & WHEN
        sut.invoke("❤️", for: firstMessage, in: conversation)
        sut.invoke("👍", for: firstMessage, in: conversation)
        sut.invoke("😮", for: firstMessage, in: conversation)

        // THEN
        XCTAssertTrue(firstMessage.usersReaction.keys.contains("❤️"), "Expected the message to have a ❤️ reaction.")
        XCTAssertTrue(firstMessage.usersReaction.keys.contains("👍"), "Expected the message to have a 👍 reaction.")
        XCTAssertTrue(firstMessage.usersReaction.keys.contains("😮"), "Expected the message to have a 😮 reaction.")

        XCTAssertEqual(
            analyticsEventTracker.trackEventEventAnalyticsEventVoidReceivedInvocations,
            [
                AnalyticsEvent.Contributed.conversationContribution(
                    .likeMessage,
                    conversationType: .group,
                    conversationSize: 0
                )
            ]
        )
    }
}
