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

import WireDataModel
import WireDataModelSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class GenerateNotificationUseCaseTests: XCTestCase {
    private var sut: GenerateNotificationUseCase!
    private var conversationEventBuilder: MockConversationEventNotificationBuilderProtocol!
    private var userEventBuilder: MockUserEventNotificationBuilderProtocol!

    override func setUp() async throws {
        conversationEventBuilder = MockConversationEventNotificationBuilderProtocol()
        userEventBuilder = MockUserEventNotificationBuilderProtocol()

        sut = GenerateNotificationUseCase(
            conversationEventBuilder: conversationEventBuilder,
            userEventBuilder: userEventBuilder,
            eventID: .mockID1
        )
    }

    override func tearDown() async throws {
        sut = nil
        conversationEventBuilder = nil
        userEventBuilder = nil
    }

    func testProcess_It_Invokes_Notification_Content_Handler() async throws {
        // Mock

        conversationEventBuilder.buildContentEvent_MockValue = [.text(UNMutableNotificationContent())]
        userEventBuilder.buildContentEvent_MockValue = .text(UNMutableNotificationContent())

        let asyncStream = AsyncStream<[UpdateEvent]> {
            $0.yield([Scaffolding.userPushRemoveEvent, Scaffolding.conversationRenameEvent])
            $0.finish()
        }

        // When
        let userNotifications = try await sut.invoke(updateEvents: asyncStream)

        // Then
        XCTAssertEqual(userNotifications.count, 2)
        XCTAssertEqual(conversationEventBuilder.buildContentEvent_Invocations.count, 1)
        XCTAssertEqual(userEventBuilder.buildContentEvent_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let conversationID = WireNetwork.QualifiedID(id: .mockID2, domain: "domain.com")
        static let userID = UserID(id: .mockID3, domain: "domain.com")
        static let userPushRemoveEvent = UpdateEvent.user(.pushRemove)
        static let conversationRenameEvent = UpdateEvent.conversation(
            .rename(
                .init(
                    conversationID: conversationID,
                    senderID: userID,
                    timestamp: .now,
                    newName: "test"
                )
            )
        )
    }

}
