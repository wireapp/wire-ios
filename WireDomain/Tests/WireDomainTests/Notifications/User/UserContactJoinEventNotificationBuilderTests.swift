//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class UserContactJoinEventNotificationBuilderTests: XCTestCase {
    private var sut: UserContactJoinEventNotificationBuilder!

    func testGenerateUserContactJoinEventNotification() async throws {

        // Mock

        sut = UserContactJoinEventNotificationBuilder(
            name: Scaffolding.contactName
        )

        let shouldBuildNotification = await sut.shouldBuildNotification()
        XCTAssertEqual(shouldBuildNotification, true)

        let userNotification = await sut.buildContent()

        try await internalTest_assertNotificationContent(
            userNotification
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
    }

}
