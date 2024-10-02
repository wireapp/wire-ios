//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireAnalyticsSupport
import WireDataModel
import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import WireSyncEngine
final class ToggleMessageReactionUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var mockAnalyticsSessionProtocol: MockAnalyticsSessionProtocol!
    private var sut: ToggleMessageReactionUseCase!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var coreDataStack: CoreDataStack!

    let modelHelper = ModelHelper()

    // MARK: - setUp

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()

        mockAnalyticsSessionProtocol = .init()
        sut = ToggleMessageReactionUseCase(analyticsSession: mockAnalyticsSessionProtocol)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockAnalyticsSessionProtocol = nil
        coreDataStack = nil
        coreDataStackHelper = nil

        super.tearDown()
    }

    func testInvoke_ToggleMessageReaction_TracksEventCorrectly() throws {
        // GIVEN
        let convo = modelHelper.createGroupConversation(in: coreDataStack.viewContext)
        let selfUser = modelHelper.createSelfUser(in: coreDataStack.viewContext)

        let messages = try modelHelper.addTextMessages(
            to: convo,
            messagePrefix: "Hello",
            sender: selfUser,
            count: 3,
            in: coreDataStack.viewContext
        )

        mockAnalyticsSessionProtocol.trackEvent_MockMethod = { _ in }

        let firstMessage = messages.first as! ZMConversationMessage

        // WHEN
        sut.invoke("❤️", for: firstMessage, in: convo)

        // THEN
        let userReactions = firstMessage.usersReaction

        XCTAssert(userReactions.keys.contains("❤️"), "Expected the first message to have a ❤️ reaction.")
        XCTAssertEqual(mockAnalyticsSessionProtocol.trackEvent_Invocations.count, 1)
        let trackEventInvocation = try XCTUnwrap(mockAnalyticsSessionProtocol.trackEvent_Invocations.first as? ConversationContributionAnalyticsEvent)
        XCTAssertEqual(trackEventInvocation.contributionType, .likeMessage)
    }

}
