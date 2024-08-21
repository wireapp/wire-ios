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

import WireUITesting
import XCTest

@testable import Wire

final class GroupDetailsNotificationOptionsCellTests: CoreDataSnapshotTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var cell: GroupDetailsNotificationOptionsCell!
    private var conversation: ZMConversation!

    override func setUp() {
        selfUserInTeam = true
        super.setUp()
        snapshotHelper = SnapshotHelper()
        cell = GroupDetailsNotificationOptionsCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
        cell.overrideUserInterfaceStyle = .light
        conversation = self.createGroupConversation()
    }

    override func tearDown() {
        snapshotHelper = nil
        cell = nil
        conversation = nil
        super.tearDown()
    }

    func testThatItDisplaysCell_NoMuted() {
        update(.none)
        snapshotHelper.verify(matching: cell)
    }

    func testThatItDisplaysCell_NonMentionsMuted() {
        update(.regular)
        snapshotHelper.verify(matching: cell)
    }

    func testThatItDisplaysCell_AllMuted() {
        update(.all)
        snapshotHelper.verify(matching: cell)
    }

    func testThatItDisplaysCell_Dark() {
        cell.overrideUserInterfaceStyle = .dark
        update(.all)
        snapshotHelper.verify(matching: cell)
    }

    private func update(_ newValue: MutedMessageTypes) {
        conversation.mutedMessageTypes = newValue
        cell.configure(with: conversation)
    }

}
