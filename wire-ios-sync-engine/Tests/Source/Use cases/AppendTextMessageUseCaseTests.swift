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
import XCTest

@testable import WireSyncEngine

class AppendTextMessageUseCaseTests: XCTestCase {

    var mockAnalyticsSession: MockAnalyticsSessionProtocol!
    var useCase: AppendTextMessageUseCase!

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()
    private var mockConversation: ZMConversation!
    private var mockSelfUser: ZMUser!

    override func setUp() {
        super.setUp()
        mockAnalyticsSession = MockAnalyticsSessionProtocol()
        useCase = AppendTextMessageUseCase(analyticsSession: mockAnalyticsSession)
    }

    override func tearDown() {
        mockAnalyticsSession = nil
        useCase = nil
        super.tearDown()
    }

    func testInvoke_AppendsTextMessageAndTracksEvent() {
        // Arrange
        let conversation = ZMConversation()
        let text = "Hello, World!"
        let mentions: [Mention] = []
        let replyingTo: ZMConversationMessage? = nil
        let fetchLinkPreview = false

        // Act
        XCTAssertNoThrow(try useCase.invoke(
            text: text,
            mentions: mentions,
            replyingTo: replyingTo,
            in: conversation,
            fetchLinkPreview: fetchLinkPreview
        ))

        // Assert
        XCTAssertTrue(conversation.draftMessage == nil)
        XCTAssertEqual(mockAnalyticsSession.trackEvent_Invocations.count, 1)

        if let event = mockAnalyticsSession.trackEvent_Invocations.first as? ContributedEvent {
            XCTAssertEqual(event.contributionType, .textMessage)
            XCTAssertEqual(event.conversationType, ConversationType(conversation.conversationType))
            XCTAssertEqual(event.conversationSize, UInt(conversation.localParticipants.count))
        } else {
            XCTFail("Expected ContributedEvent to be tracked")
        }
    }
}
