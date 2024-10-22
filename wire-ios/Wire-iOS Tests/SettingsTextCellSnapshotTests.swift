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

final class SettingsTextCellSnapshotTests: CoreDataSnapshotTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var sut: SettingsTextCell!
    private var settingsCellDescriptorFactory: SettingsCellDescriptorFactory!

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        sut = SettingsTextCell()

        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart")
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: SessionManager.shared?.activeUserSession, trackingManager: nil, selfUser: selfUser)

        settingsCellDescriptorFactory = SettingsCellDescriptorFactory(
            settingsPropertyFactory: settingsPropertyFactory,
            userRightInterfaceType: UserRight.self
        )
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    func testForNameElementWithALongName() {
        let cellDescriptor = settingsCellDescriptorFactory.nameElement()
        sut.descriptor = cellDescriptor
        cellDescriptor.featureCell(sut)

        let mockTableView = sut.wrapInTableView()
        sut.overrideUserInterfaceStyle = .dark

        XCTAssert(sut.textInput.isEnabled)

        snapshotHelper.verify(matching: mockTableView)
    }

    func testThatTextFieldIsDisabledWhenEnabledFlagIsFalse() {
        // GIVEN
        let cellDescriptor = settingsCellDescriptorFactory.nameElement(enabled: false)

        // WHEN
        cellDescriptor.featureCell(sut)

        // THEN
        XCTAssertFalse(sut.textInput.isEnabled)
    }
}
