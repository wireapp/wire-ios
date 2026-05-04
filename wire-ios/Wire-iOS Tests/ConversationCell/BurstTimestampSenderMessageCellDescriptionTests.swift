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

import WireFoundationSupport
import XCTest

@testable import Wire
@testable import WireMessagingUI

final class BurstTimestampSenderMessageCellDescriptionTests: XCTestCase {

    typealias SUT = BurstTimestampSenderMessageCellDescription

    // MARK: - Unread Indicator

    func testUnreadIndicatorJustNow() async {
        // Given
        let sut = createSUT(
            now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
            targetDate: { now in now.addingTimeInterval(-30) }, // 30s ago,
            isFirstMessageOfTheDay: false,
            showUnreadDot: true
        )

        // When
        let model = await TimeDividerModel(sut.conversationCellModel)

        // Then
        XCTAssertEqual(model?.text, "Just now")
    }

    func testUnreadIndicator25minAgo() async {
        // Given
        let sut = createSUT(
            now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
            targetDate: { now in now.addingTimeInterval(-25 * 60) }, // 25 min ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true
        )

        // When
        let model = await TimeDividerModel(sut.conversationCellModel)

        // Then
        XCTAssertEqual(model?.text, "25 minutes ago")
    }

    func testUnreadIndicatorToday() async {
        // Given
        let sut = createSUT(
            now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
            targetDate: { now in now.addingTimeInterval(-45 * 60) }, // 45 min ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true
        )

        // When
        let model = await TimeDividerModel(sut.conversationCellModel)

        // Then
        XCTAssertEqual(model?.text, "Today")
    }

    func testUnreadIndicatorYesterday() async {
        // Given
        let sut = createSUT(
            now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
            targetDate: { now in now.addingTimeInterval(-24 * 3600) }, // 1d ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true
        )

        // When
        let model = await TimeDividerModel(sut.conversationCellModel)

        // Then
        XCTAssertEqual(model?.text, "Yesterday")
    }

    func testUnreadIndicatorThreeDaysAgo() async {
        // Given
        let sut = createSUT(
            now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
            targetDate: { now in now.addingTimeInterval(-3 * 24 * 3600) }, // 3d ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true
        )

        // When
        let model = await TimeDividerModel(sut.conversationCellModel)

        // Then
        XCTAssertEqual(model?.text, "Sunday, Mar 16")
    }

    func testUnreadIndicatorSameYear() async {
        // Given
        let sut = createSUT(
            now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
            targetDate: { _ in ISO8601DateFormatter().date(from: "2025-01-03T00:44:10+01:00")! },
            isFirstMessageOfTheDay: false,
            showUnreadDot: true
        )

        // When
        let model = await TimeDividerModel(sut.conversationCellModel)

        // Then
        XCTAssertEqual(model?.text, "Jan 3")
    }

    func testUnreadIndicatorLastYear() async {
        // Given
        let sut = createSUT(
            now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
            targetDate: { _ in ISO8601DateFormatter().date(from: "2024-12-31T00:44:10+01:00")! },
            isFirstMessageOfTheDay: false,
            showUnreadDot: true
        )

        // When
        let model = await TimeDividerModel(sut.conversationCellModel)

        // Then
        XCTAssertEqual(model?.text, "Dec 31, 2024")
    }

    // MARK: - Time Divider

    func testTimeDividerToday() async {
        // When
        for flag in [true, false] {
            // Given
            // unread indicators have the same text as time dividers when they're for the first message of a day
            let sut = createSUT(
                now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
                targetDate: { now in now.addingTimeInterval(-45 * 60) }, // 45 min ago
                isFirstMessageOfTheDay: flag,
                showUnreadDot: flag
            )

            // When
            let model = await TimeDividerModel(sut.conversationCellModel)

            // Then
            XCTAssertEqual(model?.text, "Today")
        }
    }

    func testTimeDividerSameYear() async {
        for flag in [true, false] {
            // Given
            let sut = createSUT(
                now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
                targetDate: { _ in ISO8601DateFormatter().date(from: "2025-01-19T09:44:10+01:00")! },
                isFirstMessageOfTheDay: flag,
                showUnreadDot: flag
            )

            // When
            let model = await TimeDividerModel(sut.conversationCellModel)

            // Then
            XCTAssertEqual(model?.text, "Sunday, Jan 19")
        }
    }

    func testTimeDividerLastYear() async {
        for flag in [true, false] {
            // Given
            let sut = createSUT(
                now: ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00"),
                targetDate: { _ in ISO8601DateFormatter().date(from: "2024-12-19T09:44:10+01:00")! },
                isFirstMessageOfTheDay: flag,
                showUnreadDot: flag
            )

            // When
            let model = await TimeDividerModel(sut.conversationCellModel)

            // Then
            XCTAssertEqual(model?.text, "Thursday, Dec 19, 2024")
        }
    }

    // MARK: - Helpers

    private func createSUT(
        now: Date!,
        targetDate: (_ now: Date) -> Date,
        isFirstMessageOfTheDay: Bool,
        showUnreadDot: Bool
    ) -> SUT {

        let currentDateProvider = CurrentDateProvidingMock()
        currentDateProvider.now = now

        return BurstTimestampSenderMessageCellDescription(
            configuration: BurstTimestampSenderMessageCell.Configuration(
                date: targetDate(now),
                isFirstMessageOfTheDay: isFirstMessageOfTheDay,
                showUnreadDot: showUnreadDot,
                accentColor: .systemPink
            ),
            currentDateProvider: currentDateProvider
        )
    }
}

private extension TimeDividerModel {

    init?(_ model: ConversationCellModel?) {
        guard case let .timeDivider(model) = model else {
            XCTFail("unexpected conversation cell model: " + String(describing: model))
            return nil
        }
        self = model
    }
}
