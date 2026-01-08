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
@testable import WireDomainSupport

final class ProcessNotificationUseCaseTests: XCTestCase {
    private var sut: ProcessNotificationRequestUseCase!

    override func setUp() async throws {
        sut = ProcessNotificationRequestUseCase()
    }

    override func tearDown() async throws {
        sut = nil
    }

    func testStartsSync_It_Processes_Notification_Request() async throws {

        // Mock
        let notificationContent = UNMutableNotificationContent()
        notificationContent.userInfo = [
            "data": [
                "user": UUID.mockID1.uuidString,
                "data": [
                    "id": UUID.mockID2.uuidString
                ]
            ]
        ]

        let request = UNNotificationRequest(
            identifier: "id",
            content: notificationContent,
            trigger: nil
        )

        // When
        let payload = try await sut.invoke(request: request)

        // Then
        XCTAssertEqual(payload.userID, .mockID1)
        XCTAssertEqual(payload.eventID, .mockID2)
    }

}
