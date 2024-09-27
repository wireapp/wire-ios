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

final class TopPeopleCellSnapshotTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = TopPeopleCell(frame: CGRect(x: 0, y: 0, width: 56, height: 78))
        sut.user = MockUserType.createDefaultOtherUser()
        sut.backgroundColor = SemanticColors.View.backgroundDefault
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Test

    func testForInitState() {
        snapshotHelper.verify(matching: sut)
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: TopPeopleCell!
}
