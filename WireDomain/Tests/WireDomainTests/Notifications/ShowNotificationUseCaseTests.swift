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
import WireFoundation
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
    private var displayedNotification: UNNotificationContent?

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        databaseSaver = MockDatabaseSaverProtocol()

        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = applicationSupport.appendingPathComponent(
            "ShowNotificationUseCaseTests"
        )

        sut = ShowNotificationUseCase(
            contentHandler: {
                self.didDisplayNotification = true
                self.displayedNotification = $0
            },
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
        displayedNotification = nil
        databaseSaver = nil
    }

    func testProcess_It_Invokes_Notification_Content_Handler() async throws {

        // Mock

        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound(named: .init("default"))
        let userNotifications: [UserNotification] = [.text(content)]

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
        XCTAssertEqual(displayedNotification?.sound, UNNotificationSound(named: .init("new_message.caf")))
    }

    func testProcessUsesSelectedSystemDefaultSound() async throws {
        sut = ShowNotificationUseCase(
            contentHandler: { self.displayedNotification = $0 },
            conversationLocalStore: conversationLocalStore,
            selectedAccount: Account(userName: .init(), userIdentifier: .mockID1),
            accountManager: try AccountManager(
                currentAppVersion: "1.0.0",
                directory: FileManager.default.temporaryDirectory,
                defaults: .temporary()
            ),
            databaseSaver: databaseSaver,
            notificationSoundPreference: .systemDefault
        )
        conversationLocalStore.unreadConversationCount_MockValue = 1
        databaseSaver.save_MockMethod = {}

        try await sut.invoke(userNotifications: [.text(UNMutableNotificationContent())])

        XCTAssertEqual(displayedNotification?.sound, UNNotificationSound.default)
    }

    func testProcessPreservesDedicatedPingSound() async throws {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound(named: .init(NotificationSound.ping.rawValue))
        conversationLocalStore.unreadConversationCount_MockValue = 1
        databaseSaver.save_MockMethod = {}

        try await sut.invoke(userNotifications: [.text(content)])

        XCTAssertEqual(
            displayedNotification?.sound,
            UNNotificationSound(named: .init(NotificationSound.ping.rawValue))
        )
    }

}
