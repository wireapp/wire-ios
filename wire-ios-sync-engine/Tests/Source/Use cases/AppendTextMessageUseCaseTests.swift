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

import WireAnalyticsSupport
import WireDataModel
import XCTest

@testable import WireSyncEngine

final class AppendTextMessageUseCaseTests: XCTestCase {

    private var mockAnalyticsSessionProtocol: MockAnalyticsSessionProtocol!
    private var conversation: MockConversation!
    private var sut: AppendTextMessageUseCase<MockConversation>!

    override func setUp() {
        mockAnalyticsSessionProtocol = .init()
        conversation = .init()
        sut = AppendTextMessageUseCase(analyticsSession: mockAnalyticsSessionProtocol)
    }

    override func tearDown() {
        sut = nil
        conversation = nil
        mockAnalyticsSessionProtocol = nil
    }

    func testExample() throws {

        // Given
        // ?

        // When
        try sut.invoke(
            text: "some message",
            mentions: [],
            replyingTo: .none,
            in: conversation,
            fetchLinkPreview: false
        )

        // Then
        // TODO: assert the code worked correctly
        // e.g. check draftMessage has become nil
    }
}

// MARK: - MockConversation

private final class MockConversation: MessageAppendableConversation {

    var conversationType = ZMConversationType.oneOnOne

    var localParticipants = Set<ZMUser>()

    var draftMessage: DraftMessage?

    func appendText(content: String, mentions: [WireDataModel.Mention], replyingTo quotedMessage: (any WireDataModel.ZMConversationMessage)?, fetchLinkPreview: Bool, nonce: UUID) throws -> any WireDataModel.ZMConversationMessage {
        // fatalError("TODO")
    }
}
