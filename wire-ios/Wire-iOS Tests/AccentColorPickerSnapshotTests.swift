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

import SwiftUI
import WireCommonComponents
import WireFoundation
import WireTestingPackage
import XCTest

@testable import Wire

final class AccentColorPickerSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: AccentColorPickerController!
    private var selfUser: MockUserType!
    private var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        selfUser = MockUserType.createDefaultSelfUser()
        selfUser.accentColorValue = AccentColor.default.rawValue
        userSession = UserSessionMock(mockUser: selfUser)

        sut = AccentColorPickerController(selfUser: selfUser, userSession: userSession)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        selfUser = nil
        userSession = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Test

    func testItIsLaidOutCorrectly() {
        // GIVEN && WHEN
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        // THEN
        snapshotHelper.verify(matching: sut.view)
    }

}
