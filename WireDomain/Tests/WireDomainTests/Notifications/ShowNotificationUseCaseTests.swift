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
import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ShowNotificationUseCaseTests: XCTestCase {
    private var sut: ShowNotificationUseCase!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var databaseSaver: MockDatabaseSaverProtocol!
    private var didDisplayNotification = false

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        databaseSaver = MockDatabaseSaverProtocol()

        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = applicationSupport.appendingPathComponent(
            "ShowNotificationUseCaseTests"
        )

        sut = ShowNotificationUseCase(
            contentHandler: { _ in self.didDisplayNotification = true },
            conversationLocalStore: conversationLocalStore,
            selectedAccount: Account(userName: .init(), userIdentifier: .mockID1),
            accountManager: try AccountManager(
                currentAppVersion: "1.0.0",
                directory: url,
                defaults: .temporary()
            ),
            databaseSaver: databaseSaver
        )
    }

    override func tearDown() async throws {
        sut = nil
        conversationLocalStore = nil
        didDisplayNotification = false
        databaseSaver = nil
    }

    func testProcess_It_Invokes_Notification_Content_Handler() async throws {

        // Mock

        let userNotifications: [UserNotification] = [
            .text(UNMutableNotificationContent())
        ]

        conversationLocalStore.unreadConversationCount_MockValue = 1
        databaseSaver.save_MockMethod = {}

        // When
        try await sut.invoke(
            userNotifications: userNotifications
        )

        // Then
        XCTAssertEqual(didDisplayNotification, true)
        XCTAssertEqual(databaseSaver.save_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.unreadConversationCount_Invocations.count, 1)
    }

}
