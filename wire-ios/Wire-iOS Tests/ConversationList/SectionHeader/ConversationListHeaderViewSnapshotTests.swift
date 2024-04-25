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

import SnapshotTesting
import XCTest
@testable import Wire

final class ConversationListHeaderViewSnapshotTests: BaseSnapshotTestCase {

    var sut: ConversationListHeaderView!

    override func setUp() {
        super.setUp()
        sut = setupConversationListHeaderView()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForExpanded() {
        verify(matching: sut)
    }

    func testForCollapsed() {
        sut = setupConversationListHeaderView(isCollapsed: true)
        verify(matching: sut)
    }

    func testForBadgeNumberHitLimit() {
        sut = setupConversationListHeaderView(folderBadge: 999)
        verify(matching: sut)
    }

    func testForBadgeNumberEquals10() {
        sut = setupConversationListHeaderView(folderBadge: 10)
        verify(matching: sut)
    }

    private func setupConversationListHeaderView (
        folderBadge: Int = 0,
        isCollapsed: Bool = false
    ) -> ConversationListHeaderView {
        let view = ConversationListHeaderView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: CGFloat.ConversationListSectionHeader.height)))
        view.title = "THISISAVERYVERYVERYVERYVERYVERYVERYVERYLONGFOLDERNAME"
        view.folderBadge = folderBadge
        view.collapsed = isCollapsed

        return view
    }
}
