//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import Wire

final class SettingsTableViewControllerSnapshotTests: ZMSnapshotTestCase {

    // MARK: - Properties

    var sut: SettingsTableViewController!
    var settingsCellDescriptorFactory: SettingsCellDescriptorFactory!
    var settingsPropertyFactory: SettingsPropertyFactory!
    var userSession: UserSessionMock!
    var selfUser: MockZMEditableUser!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        selfUser = MockZMEditableUser()

        selfUser.teamName = "Wire"
        selfUser.handle = "johndoe"
        selfUser.name = "John Doe"
        selfUser.domain = "wire.com"
        selfUser.emailAddress = "john.doe@wire.com"
        selfUser.remoteIdentifier = UUID(uuidString: "AFBDFB29-AA40-4444-94D2-F484D0A44600")

        userSession = UserSessionMock(mockUser: selfUser)

        SelfUser.provider = SelfProvider(providedSelfUser: selfUser)

        settingsPropertyFactory = SettingsPropertyFactory(userSession: userSession, selfUser: selfUser)

        settingsCellDescriptorFactory = SettingsCellDescriptorFactory(
            settingsPropertyFactory: settingsPropertyFactory,
            userRightInterfaceType: MockUserRight.self
        )

        MockUserRight.isPermitted = true
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        settingsCellDescriptorFactory = nil
        settingsPropertyFactory = nil

        userSession = nil
        selfUser = nil
        SelfUser.provider = nil
        Settings.shared.reset()
        BackendInfo.storage = .standard
        BackendInfo.isFederationEnabled = false
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForSettingGroup() throws {
        // prevent app crash when checking Analytics.shared.isOptout
        Analytics.shared = Analytics(optedOut: true)
        let group = settingsCellDescriptorFactory.settingsGroup(isTeamMember: true, userSession: userSession)
        try verify(group: group)
    }

    private func testForAccountGroup(
        federated: Bool,
        disabledEditing: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) throws {
        BackendInfo.storage = UserDefaults(suiteName: UUID().uuidString)!
        BackendInfo.isFederationEnabled = federated

        MockUserRight.isPermitted = !disabledEditing
        let group = settingsCellDescriptorFactory.accountGroup(isTeamMember: true, userSession: userSession)
        try verify(group: group, file: file, testName: testName, line: line)
    }

    func testForAccountGroup_Federated() throws {
        try testForAccountGroup(federated: true)
    }

    func testForAccountGroup_NotFederated() throws {
        try testForAccountGroup(federated: false)
    }

    func testForAccountGroupWithDisabledEditing_Federated() throws {
        try testForAccountGroup(federated: true, disabledEditing: true)
    }

    func testForAccountGroupWithDisabledEditing_NotFederated() throws {
        try testForAccountGroup(federated: false, disabledEditing: true)
    }

    // MARK: - options

    func testForOptionsGroup() throws {
        Settings.shared[.chatHeadsDisabled] = false
        let group = settingsCellDescriptorFactory.optionsGroup
        try verify(group: group)
    }

    func testForOptionsGroupFullTableView() {
        setToLightTheme()
        userSession.isAppLockAvailable = true

        let group = settingsCellDescriptorFactory.optionsGroup
        sut = SettingsTableViewController(group: group as! SettingsInternalGroupCellDescriptorType)

        sut.view.backgroundColor = .black
        sut.view.overrideUserInterfaceStyle = .dark

        // set the width of the VC, to calculate the height on content size
        sut.view.frame = CGRect(origin: .zero, size: CGSize.iPhoneSize.iPhone4_7)
        sut.view.layoutIfNeeded()

        verify(matching: sut, customSize: CGSize(width: CGSize.iPhoneSize.iPhone4_7.width, height: sut.tableView.contentSize.height))
    }

    func testThatApplockIsAvailableInOptionsGroup_WhenIsAvailable() {
        // given
        userSession.isAppLockAvailable = true

        settingsPropertyFactory = .init(userSession: userSession, selfUser: selfUser)
        settingsCellDescriptorFactory = .init(settingsPropertyFactory: settingsPropertyFactory,
                                              userRightInterfaceType: MockUserRight.self)

        // then
        XCTAssertTrue(settingsCellDescriptorFactory.isAppLockAvailable)
    }

    func testThatApplockIsNotAvailableInOptionsGroup_WhenIsNotAvailable() {
        // given
        userSession.isAppLockAvailable = false

        settingsPropertyFactory = .init(userSession: userSession, selfUser: selfUser)
        settingsCellDescriptorFactory = .init(settingsPropertyFactory: settingsPropertyFactory,
                                              userRightInterfaceType: MockUserRight.self)

        // then
        XCTAssertFalse(settingsCellDescriptorFactory.isAppLockAvailable)
    }

    // MARK: - dark theme

    func testForDarkThemeOptionsGroup() throws {
        setToLightTheme()

        let group = SettingsCellDescriptorFactory.darkThemeGroup(for: settingsPropertyFactory.property(.darkMode))
        try verify(group: group)
    }

    private func verify(
        group: Any,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) throws {
        let group = try XCTUnwrap(group as? SettingsInternalGroupCellDescriptorType)
        sut = SettingsTableViewController(group: group)

        sut.view.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark

        verify(matching: sut, file: file, testName: testName, line: line)
    }

    // MARK: - advanced

    func testForAdvancedGroup() throws {
        let group = settingsCellDescriptorFactory.advancedGroup(userSession: userSession)
        try verify(group: group)
    }

    // MARK: - data usage permissions

    func testForDataUsagePermissionsForTeamMember() throws {
        let group = settingsCellDescriptorFactory.dataUsagePermissionsGroup(isTeamMember: true)
        try verify(group: group)
    }
}
