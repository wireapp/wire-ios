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

import WireSystemSupport
import XCTest

@testable import Wire

final class ConversationCellBurstTimestampViewTests: XCTestCase {

    private var sut: ConversationCellBurstTimestampView!
    private var userSession: UserSessionMock!

    override func setUp() {
        super.setUp()

        userSession = UserSessionMock()
        sut = ConversationCellBurstTimestampView()
    }

    override func tearDown() {
        sut = nil
        userSession = nil

        super.tearDown()
    }

    // MARK: - Unread Indicator

    func testUnreadIndicatorJustNow() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-30), // 30s ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "Just now")
    }

    func testUnreadIndicator25minAgo() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-25 * 60), // 25 min ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "25 minutes ago")
    }

    func testUnreadIndicatorToday() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-45 * 60), // 45 min ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "Today")
    }

    func testUnreadIndicatorYesterday() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-10 * 3600), // before midnight
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "Yesterday")
    }

    func testUnreadIndicatorWed13() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-3 * 24 * 3600), // 3d ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "Friday, January 3")
    }

    func testUnreadIndicatorSameYear() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: ISO8601DateFormatter().date(from: "2025-01-03T00:44:10+01:00")!,
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "January 3")
    }

    func testUnreadIndicatorLastYear() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: ISO8601DateFormatter().date(from: "2024-12-31T00:44:10+01:00")!,
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "December 31, 2024")
    }

    // MARK: - Time Divider

    func testTimeDividerToday() {
        // Given
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // When
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-30), // 30s ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: false,
            accentColor: userSession.selfUser.accentColor
        )

        // Then
        XCTAssertEqual(sut.label.text, "Today")
    }

}
