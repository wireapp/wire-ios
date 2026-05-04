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

import XCTest

@testable import Wire
@testable import WireCommonComponents

final class SettingsPropertyTests: XCTestCase {

    var userDefaults: UserDefaults!
    var userSession: UserSessionMock!

    override func setUp() {
        super.setUp()
        userDefaults = .standard
        userSession = UserSessionMock()
    }

    override func tearDown() {
        userDefaults = nil
        userSession = nil

        super.tearDown()
    }

    func saveAndCheck<T>(
        _ property: SettingsProperty,
        value: T,
        file: String = #filePath,
        line: UInt = #line
    ) throws where T: Equatable {
        var property = property
        try property << value
        if let readValue: T = property.rawValue() as? T {
            if value != readValue {
                recordFailure(
                    withDescription: "Wrong property value, read \(readValue) but expected \(value)",
                    inFile: file,
                    atLine: Int(line),
                    expected: true
                )
            }
        } else {
            recordFailure(
                withDescription: "Unable to read property value",
                inFile: file,
                atLine: Int(line),
                expected: true
            )
        }
    }

    // User defaults

    func testThatIntegerUserDefaultsSettingSave() {
        // given
        let property = SettingsUserDefaultsProperty(
            propertyName: SettingsPropertyName.darkMode,
            userDefaultsKey: SettingKey.colorScheme.rawValue,
            userDefaults: userDefaults
        )
        // when & then
        try! saveAndCheck(property, value: "light")
    }

    func testThatBoolUserDefaultsSettingSave() {
        // given
        let property = SettingsUserDefaultsProperty(
            propertyName: SettingsPropertyName.chatHeadsDisabled,
            userDefaultsKey: SettingKey.chatHeadsDisabled.rawValue,
            userDefaults: userDefaults
        )
        // when & then
        try! saveAndCheck(property, value: NSNumber(value: true))
    }

    func testThatNamePropertySetsValue() {
        // given
        let selfUser = MockZMEditableUser()
        let mediaManager = ZMMockAVSMediaManager()
        let trackingManager = MockTrackingInterface()

        let factory = SettingsPropertyFactory(
            userDefaults: userDefaults,
            mediaManager: mediaManager,
            userSession: userSession,
            selfUser: selfUser,
            trackingManager: trackingManager
        )

        let property = factory.property(SettingsPropertyName.profileName)
        // when & then
        try! saveAndCheck(property, value: "Test")
    }

    private var settingsPropertyFactory: SettingsPropertyFactory {
        let selfUser = MockZMEditableUser()
        let mediaManager = ZMMockAVSMediaManager()
        let trackingManager = MockTrackingInterface()

        return SettingsPropertyFactory(
            userDefaults: userDefaults,
            mediaManager: mediaManager,
            userSession: userSession,
            selfUser: selfUser,
            trackingManager: trackingManager
        )
    }

    func testThatDarkThemePropertySetsValue() {
        // given
        let factory = settingsPropertyFactory

        let property = factory.property(SettingsPropertyName.darkMode)
        // when & then
        try! saveAndCheck(property, value: 2)
    }

    func testThatSoundLevelPropertySetsValue() {
        // given
        let factory = settingsPropertyFactory

        let property = factory.property(SettingsPropertyName.soundAlerts)
        // when & then
        try! saveAndCheck(property, value: 1)
    }

    func testThatIntegerBlockSettingSave() {
        // given
        let selfUser = MockZMEditableUser()
        let mediaManager = ZMMockAVSMediaManager()
        let trackingManager = MockTrackingInterface()

        let factory = SettingsPropertyFactory(
            userDefaults: userDefaults,
            mediaManager: mediaManager,
            userSession: userSession,
            selfUser: selfUser,
            trackingManager: trackingManager
        )

        let property = factory.property(SettingsPropertyName.soundAlerts)
        // when & then
        try! saveAndCheck(property, value: 1)
    }

    func testThatItCanSetAIntegerUserDefaultsSettingsPropertyLargerThanOne() {
        // given
        let factory = SettingsPropertyFactory(
            userDefaults: userDefaults,
            mediaManager: ZMMockAVSMediaManager(),
            userSession: userSession,
            selfUser: MockZMEditableUser(),
            trackingManager: MockTrackingInterface()
        )

        let property = factory.property(.browserOpeningOption)
        // when & then
        try? saveAndCheck(property, value: 2)
    }

    // MARK: - Accounts

    func testThatIntegerUserDefaultsSettingForAccountSave() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = SettingKey.blackListDownloadInterval
        XCTAssertNil(settings.value(for: key, in: account) as Int?)

        // when
        settings.setValue(42, settingKey: key, in: account)

        // then
        let result: Int? = settings.value(for: key, in: account)
        XCTAssertEqual(result, 42)
    }

    func testThatBoolUserDefaultsSettingForAccountSave() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = SettingKey.disableMarkdown
        XCTAssertNil(settings.value(for: key, in: account) as Bool?)

        // when
        settings.setValue(true, settingKey: key, in: account)

        // then
        let result: Bool? = settings.value(for: key, in: account)
        XCTAssertEqual(result, true)
    }

    func testThatSharedSettingIsMigratedToAccount() {
        // given
        let settings = Settings()
        let account = Account(userName: "bob", userIdentifier: UUID())
        let key = SettingKey.blackListDownloadInterval
        let value = 42
        settings[key] = value

        // when & then
        let result: Int? = settings.value(for: key, in: account)
        let settingVal: Int? = settings[key]
        XCTAssertNil(settingVal)
        XCTAssertEqual(result, value)
    }
}
