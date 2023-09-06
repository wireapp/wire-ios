//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import SnapshotTesting
@testable import Wire

final class ConversationCellBurstTimestampViewSnapshotTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: ConversationCellBurstTimestampView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        sut = ConversationCellBurstTimestampView()
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 40))
        sut.unreadDot.backgroundColor = .red
        sut.backgroundColor = SemanticColors.View.backgroundConversationView
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForInitState() {
        verify(matching: sut)
    }

    func testForIncludeDayOfWeekAndDot() {
        // GIVEN & WHEN
        sut.configure(
            with: Date(timeIntervalSinceReferenceDate: 0),
            includeDayOfWeek: true,
            showUnreadDot: true
        )

        // THEN
        verify(matching: sut)
    }

    func testForNotIncludeDayOfWeekAndDot() {
        // GIVEN & WHEN
        sut.configure(
            with: Date(timeIntervalSinceReferenceDate: 0),
            includeDayOfWeek: false,
            showUnreadDot: false
        )

        // THEN
        verify(matching: sut)
    }

    func testForJustNowAndNotIncludeDayOfWeekAndDot() {
        // GIVEN & WHEN
        sut.configure(
            with: Date(timeIntervalSinceNow: 5),
            includeDayOfWeek: false,
            showUnreadDot: false
        )

        // THEN
        verify(matching: sut)
    }
}
