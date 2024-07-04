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

final class AppendKnockMessageUseCaseTests: XCTest {

    // MARK: - Properties
    private var mockAnalyticsSessionProtocol: MockAnalyticsSessionProtocol!
    private var mockConversation: MockMessageAppendableConversation!
    private var sut: AppendKnockMessageUseCase!

    // MARK: - setUp

    override func setUp() {
        mockAnalyticsSessionProtocol = .init()
        mockConversation = .init()
        sut = AppendKnockMessageUseCase(analyticsSession: mockAnalyticsSessionProtocol)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockConversation = nil
        mockAnalyticsSessionProtocol = nil
    }

    func testInvoke_AppendKnockMessage_TracksEventCorrectly() throws {
        // GIVEN
        mockConversation.conversationType = .group
        mockConversation.localParticipants = []

        mockConversation.appendKnock_MockMethod = { _ in
            MockZMConversationMessage()
        }

        mockAnalyticsSessionProtocol.trackEvent_MockMethod = { _ in }

        // WHEN
        try sut.invoke(
            in: mockConversation
        )

        XCTAssertEqual(mockConversation.appendKnock_Invocations.count, 1)

        XCTAssertNil(mockConversation.draftMessage)

        XCTAssertEqual(mockAnalyticsSessionProtocol.trackEvent_Invocations.count, 1)
        let trackEventInvocation = try XCTUnwrap(mockAnalyticsSessionProtocol.trackEvent_Invocations.first as? ContributedEvent)
        XCTAssertEqual(trackEventInvocation.contributionType, .pingMessage)
        XCTAssertEqual(trackEventInvocation.conversationType, .group)

    }

}
