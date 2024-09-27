//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireTestingPackage
import XCTest
@testable import Wire

final class ConversationCellBurstTimestampViewSnapshotTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: ConversationCellBurstTimestampView!
    private var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        userSession = UserSessionMock()
        sut = ConversationCellBurstTimestampView()
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 40))
        sut.unreadDot.backgroundColor = .red
        sut.backgroundColor = SemanticColors.View.backgroundConversationView
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        userSession = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForInitState() {
        snapshotHelper.verify(matching: sut)
    }

    func testForIncludeDayOfWeekAndDot() {
        // GIVEN & WHEN
        sut.configure(
            with: Date(timeIntervalSinceReferenceDate: 0),
            includeDayOfWeek: true,
            showUnreadDot: true,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testForNotIncludeDayOfWeekAndDot() {
        // GIVEN & WHEN
        sut.configure(
            with: Date(timeIntervalSinceReferenceDate: 0),
            includeDayOfWeek: false,
            showUnreadDot: false,
            accentColor: userSession.selfUser.accentColor
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }
}
