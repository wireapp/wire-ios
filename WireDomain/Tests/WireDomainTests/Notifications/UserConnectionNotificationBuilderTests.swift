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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class UserConnectionNotificationBuilderTests: XCTestCase {
    private var sut: UserConnectionNotificationBuilder!

    func testGenerateUserConnectionNotifications() async {

        let connectionStatuses: [UserConnectionNotificationBuilder.ConnectionStatus] = [
            .joined
        ]

        for connectionStatus in connectionStatuses {
            sut = UserConnectionNotificationBuilder(
                connectionStatus: connectionStatus,
                username: Scaffolding.username
            )

            let notification = await sut.buildContent()

            switch connectionStatus {
            case .joined:
                XCTAssertEqual(notification.title, "")
                XCTAssertEqual(notification.body, "\(Scaffolding.username) just joined Wire")
                XCTAssertEqual(notification.sound, UNNotificationSound(named: .init("default")))
                XCTAssertEqual(notification.categoryIdentifier, NotificationCategory.nonActionable.rawValue)

            case .pending:
                fatalError()

            case .accepted:
                fatalError()
            }
        }
    }

    private enum Scaffolding {
        static let username = "username1"
    }

}
