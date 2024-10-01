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
    private var mockConversation: MockMessageAppendableConversation!
    private var sut: ToggleMessageReactionUseCase!
    private var message: MockZMConversationMessage!
    
    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockAnalyticsSessionProtocol = .init()
        mockConversation = .init()
        sut = ToggleMessageReactionUseCase(analyticsSession: mockAnalyticsSessionProtocol)
        message = MockZMConversationMessage()
        message.senderUser = UserType

        // create coredatastack with CoreDataStackHelper

        // add create message in ModelHelper -> ZMMessage
        // modelhelper gives you an user, a conversation
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockConversation = nil
        mockAnalyticsSessionProtocol = nil
        message = nil
    }

    func testInvoke_ToggleMessageReaction_TracksEventCorrectly() throws {
        // GIVEN
        mockConversation.conversationType = .group
        mockConversation.localParticipants = []

        // WHEN
        sut.invoke("❤️", for: message, in: mockConversation)

        // THEN
        // Assert that add reaction from ZMMessage has been invoked
        let senderUser = try XCTUnwrap(message.senderUser)
        XCTAssert(message.usersReaction, ["❤️", senderUser])
        XCTAssertEqual(mockAnalyticsSessionProtocol.trackEvent_Invocations.count, 1)
        let trackEventInvocation = try XCTUnwrap(mockAnalyticsSessionProtocol.trackEvent_Invocations.first as? ConversationContributionAnalyticsEvent)
        XCTAssertEqual(trackEventInvocation.contributionType, .reaction)
        XCTAssertEqual(trackEventInvocation.conversationType, .group)

    }


    func testInvoke_ToggleMessageReaction_DoesNotTrackEvent() {
        // GIVEN
        mockConversation.conversationType = .group
        mockConversation.localParticipants = []
        mockConversation.



        // WHEN
        sut.invoke("😧", for: message, in: mockConversation)

        // THEN
        // Assert that add reaction from ZMMessage has been invoked
        // Assert that trackEventInvocation has not invoked for the analytic event
    }

}
