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

import WireTestingPackage
import XCTest

@testable import Wire

final class CallSystemMessageTests: XCTestCase, CoreDataFixtureTestHelper {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper_!
    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        snapshotHelper = nil
        _ = waitForGroupsToBeEmpty([coreDataFixture.dispatchGroup])
        coreDataFixture = nil
        super.tearDown()
    }

    // MARK: - Missed Call

    func testThatItRendersMissedCallFromSelfUser() {
        let missedCell = missedCallCell(fromSelf: true)
        snapshotHelper.verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromOtherUser() {
        let missedCell = missedCallCell(fromSelf: false)
        snapshotHelper.verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromSelfUserInGroup() {
        let missedCell = missedCallCell(fromSelf: true, inGroup: true)
        snapshotHelper.verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromOtherUserInGroup() {
        let missedCell = missedCallCell(fromSelf: false, inGroup: true)
        snapshotHelper.verify(matching: missedCell)
    }

    // MARK: - Helper

    private func missedCallCell(fromSelf: Bool, inGroup: Bool = false) -> UITableViewCell {
        let message = systemMessage(in: .insertNewObject(in: uiMOC), from: fromSelf ? selfUser : otherUser, inGroup: inGroup)
        let cell = createCell(for: message)

        return cell
    }

    private func systemMessage(
        in conversation: ZMConversation,
        from user: ZMUser,
        inGroup: Bool
    ) -> ZMSystemMessage {
        let date = Date(timeIntervalSince1970: 123456879)

        if inGroup {
            conversation.conversationType = .group
        }
        return conversation.appendMissedCallMessage(fromUser: user, at: date)
    }

    private func createCell(for systemMessage: ZMSystemMessage) -> UITableViewCell {
        let description = ConversationMissedCallSystemMessageCellDescription(message: systemMessage, data: systemMessage.systemMessageData!)

        let cell = ConversationMessageCellTableViewAdapter<ConversationMissedCallSystemMessageCellDescription>(style: .default, reuseIdentifier: nil)
        cell.cellDescription = description
        cell.configure(with: description.configuration, fullWidth: description.isFullWidth, topMargin: description.topMargin)

        cell.frame = CGRect(origin: .zero, size: CGSize(width: CGSize.iPhoneSize.iPhone4.width, height: 32.5))

        cell.backgroundColor = .white

        return cell
    }

}
