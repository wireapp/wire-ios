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

import XCTest
@testable import WireDomain
@testable import WireNetwork

final class UserContactJoinEventNotificationBuilderTests: XCTestCase {
    private var sut: UserContactJoinEventNotificationBuilder!

    func testGenerateUserContactJoinEventNotification() async throws {

        // Mock

        sut = UserContactJoinEventNotificationBuilder(
            context: .init(),
            validator: .init()
        )

        // When
        let userNotification = await sut.buildContent(
            event: Scaffolding.userContactJoinEvent
        )

        // Then
        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification)
        )
    }

    private func internalTest_assertNotificationContent(
        _ userNotification: UserNotification
    ) async throws {

        guard case let .text(notificationContent) = userNotification else {
            return XCTFail()
        }

        // Title
        XCTAssertTrue(notificationContent.title.isEmpty)

        // Body
        XCTAssertEqual(
            notificationContent.body,
            "\(Scaffolding.contactName) just joined Wire"
        )

        // Category
        XCTAssertEqual(
            notificationContent.categoryIdentifier,
            NotificationCategory.nonActionable.rawValue
        )

        // Sound
        XCTAssertEqual(
            notificationContent.sound,
            UNNotificationSound(named: .init("default"))
        )
    }

    private enum Scaffolding {
        static let contactName = "User1"
        static let userContactJoinEvent = UserContactJoinEvent(name: contactName)
    }

}
