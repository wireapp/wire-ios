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
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var databaseSaver: MockDatabaseSaverProtocol!
    private var displayedContent: UNNotificationContent?

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        userLocalStore.fetchSelfUserAvailability_MockValue = .available
        databaseSaver = MockDatabaseSaverProtocol()

        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = applicationSupport.appendingPathComponent(
            "ShowNotificationUseCaseTests"
        )

        sut = ShowNotificationUseCase(
            contentHandler: { self.displayedContent = $0 },
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore,
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
        userLocalStore = nil
        displayedContent = nil
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
        XCTAssertNotNil(displayedContent)
        XCTAssertEqual(databaseSaver.save_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.unreadConversationCount_Invocations.count, 1)
    }

    func testItFiltersMeetingAlertsFromMixedBatchWhileAway() async throws {
        userLocalStore.fetchSelfUserAvailability_MockValue = .away
        conversationLocalStore.unreadConversationCount_MockValue = 1
        databaseSaver.save_MockMethod = {}

        let categories: [NotificationCategory] = [
            .meetingInvitation, .meetingUpdate, .meetingCancellation, .unmutedConversation
        ]
        let notifications = categories.map { category in
            let content = UNMutableNotificationContent()
            content.categoryIdentifier = category.rawValue
            content.body = category.rawValue
            return UserNotification.text(content)
        }

        try await sut.invoke(userNotifications: notifications)

        XCTAssertEqual(displayedContent?.body, NotificationCategory.unmutedConversation.rawValue)
        XCTAssertEqual(displayedContent?.categoryIdentifier, NotificationCategory.unmutedConversation.rawValue)
    }

    func testItDisplaysMeetingAlertWhileBusy() async throws {
        userLocalStore.fetchSelfUserAvailability_MockValue = .busy
        conversationLocalStore.unreadConversationCount_MockValue = 1
        databaseSaver.save_MockMethod = {}
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = NotificationCategory.meetingInvitation.rawValue
        content.body = "Meeting invitation"

        try await sut.invoke(userNotifications: [.text(content)])

        XCTAssertEqual(displayedContent?.body, content.body)
        XCTAssertEqual(displayedContent?.categoryIdentifier, content.categoryIdentifier)
    }

}
