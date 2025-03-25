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

import WireDesign
import WireSystemSupport
import WireTestingPackage
import XCTest

@testable import Wire
@testable import WireConversationUI

final class TimeDividerContentViewSnapshotTests: XCTestCase {
    typealias SUT = ConversationCell<TimeDividerModel>

    private var snapshotHelper: SnapshotHelper!
    private var sut: SUT!
    private var userSession: UserSessionMock!

    override func setUp() {
        super.setUp()

        snapshotHelper = SnapshotHelper()
        userSession = UserSessionMock()
        sut = SUT(style: .default, reuseIdentifier: "sut")
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 40))
//        sut.unreadDot.backgroundColor = .red
//        sut.backgroundColor = SemanticColors.View.backgroundConversationView
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        userSession = nil

        super.tearDown()
    }

    // MARK: -
/*
    #Preview("with unread indicator") {
        let model = TimeDividerModel(
            text: "Friday Lorem Ipsum Dolor",
            isUnreadIndicatorVisible: true
        )
        TimeDividerContentView(model: model)
    }

    #Preview("without unread indicator") {
        let model = TimeDividerModel(
            text: "Friday Lorem Ipsum Dolor",
            isUnreadIndicatorVisible: false
        )
        TimeDividerContentView(model: model)
    }

    #Preview("no text") {
        let model = TimeDividerModel()
        TimeDividerContentView(model: model)
    }

    #Preview("no text but unread indicator") {
        let model = TimeDividerModel(
            text: "",
            isUnreadIndicatorVisible: true
        )
        TimeDividerContentView(model: model)
    }

*/
    func testWithUnreadIndicator() {
        // When
        sut.model = TimeDividerModel(
            text: "Friday Lorem Ipsum Dolor",
            isUnreadIndicatorVisible: true
        )

        // Then
        snapshotHelper.verify(matching: sut)
    }
    /*
    func testForNotIncludeDayOfWeekAndDot() {
        // GIVEN & WHEN
        sut.configure(
            timestamp: Date(timeIntervalSinceReferenceDate: 0),
            isFirstMessageOfTheDay: false,
            showUnreadDot: false,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testYesterdayNoUnread() {
        // GIVEN
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-20T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // WHEN
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-24 * 3600), // 24h ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: false,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testYesterdayWithUnread() {
        // WHEN
        sut.configure(
            timestamp: .now.addingTimeInterval(-24 * 3600), // 24h ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testYesterdayWithUnreadAndFirstMessageOfToday() {
        // GIVEN
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-20T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // WHEN
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-24 * 3600), // 24h ago
            isFirstMessageOfTheDay: true,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testLastYearNoUnread() {
        // GIVEN
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // WHEN
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-365 * 24 * 3600), // 1y ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: false,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testLastYearWithUnread() {
        // GIVEN
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // WHEN
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-365 * 24 * 3600), // 1y ago
            isFirstMessageOfTheDay: false,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testLastYearWithUnreadAndFirstMessageOfToday() {
        // GIVEN
        let mockedNow = ISO8601DateFormatter().date(from: "2025-03-19T09:44:10+01:00")!
        let currentDateProvider = MockCurrentDateProviding()
        currentDateProvider.now = mockedNow
        sut.currentDateProvider = currentDateProvider

        // WHEN
        sut.configure(
            timestamp: mockedNow.addingTimeInterval(-365 * 24 * 3600), // 1y ago
            isFirstMessageOfTheDay: true,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }
*/
}
