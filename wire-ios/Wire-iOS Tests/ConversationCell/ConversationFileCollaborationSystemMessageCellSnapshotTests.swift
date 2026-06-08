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

import WireDesign
import WireMessagingDomain
import WireTestingPackage
import XCTest

@testable import Wire

final class ConversationFileCollaborationSystemMessageCellSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: ConversationFileCollaborationSystemMessageCellDescription!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testFileCollaboration_Editor_Role() {
        let view = makeSut(selfUserRole: .editor)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    func testFileCollaboration_Viewer_Role() {
        let view = makeSut(selfUserRole: .viewer)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    // MARK: - Helpers

    private func makeSut(selfUserRole: WireDriveConversation.Participant.Role) -> UIView {
        sut = ConversationFileCollaborationSystemMessageCellDescription(selfUserRole: selfUserRole)
        let view = sut.makeView()
        view.backgroundColor = ColorTheme.Backgrounds.background
        let wrapperView = UIView(frame: .init(x: 0, y: 0, width: 375, height: 70))
        wrapperView.backgroundColor = ColorTheme.Backgrounds.background
        wrapperView.addSubview(view)
        view.frame = wrapperView.bounds

        return view
    }

}
