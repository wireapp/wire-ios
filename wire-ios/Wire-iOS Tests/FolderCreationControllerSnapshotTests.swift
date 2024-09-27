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
import WireTestingPackage
import XCTest
@testable import Wire

final class FolderCreationControllerSnapshotTests: XCTestCase, CoreDataFixtureTestHelper {
    // MARK: Internal

    var sut: FolderCreationController!
    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        coreDataFixture = CoreDataFixture()

        let convo = createTeamGroupConversation()
        let conversationDirectory = coreDataFixture.uiMOC.conversationListDirectory()
        sut = FolderCreationController(conversation: convo, directory: conversationDirectory)
        accentColor = .purple
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        coreDataFixture = nil
        super.tearDown()
    }

    func testForEditingTextField() {
        sut.loadViewIfNeeded()
        sut.beginAppearanceTransition(false, animated: false)
        sut.endAppearanceTransition()

        sut.viewDidAppear(false)

        snapshotHelper.verify(matching: sut)
    }

    // MARK: Private

    private var snapshotHelper: SnapshotHelper!
}
