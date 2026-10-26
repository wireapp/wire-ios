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

@testable import WireCommonComponents

final class ExtensionSettingsTests: XCTestCase {

    var defaults: UserDefaults!
    var settings: ExtensionSettings!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: name)
        settings = ExtensionSettings(defaults: defaults, isLinkPreviewGenerationEnabled: { true })
    }

    override func tearDown() {
        settings.reset()
        settings = nil
        defaults = nil
        super.tearDown()
    }

    func testThatItEnablesLinkPreviewsByDefault() {
        XCTAssertFalse(settings.disableLinkPreviews)
    }

    func testThatItDisablesLinkPreviewsBeforeTheAppLaunchesWhenTheFlagIsDisabled() {
        settings = ExtensionSettings(defaults: defaults, isLinkPreviewGenerationEnabled: { false })

        XCTAssertTrue(settings.disableLinkPreviews)
    }

    func testThatTheDisabledFlagOverridesBothStoredPreferences() {
        settings = ExtensionSettings(defaults: defaults, isLinkPreviewGenerationEnabled: { false })

        for preference in [false, true] {
            settings.disableLinkPreviews = preference

            XCTAssertTrue(settings.disableLinkPreviews)
        }
    }

    func testThatTheFlagDoesNotOverwriteTheStoredPreference() {
        var isEnabled = true
        settings = ExtensionSettings(defaults: defaults, isLinkPreviewGenerationEnabled: { isEnabled })

        for preference in [false, true] {
            settings.disableLinkPreviews = preference
            isEnabled = false

            XCTAssertTrue(settings.disableLinkPreviews)
            XCTAssertEqual(defaults.bool(forKey: "disableLinkPreviews"), preference)

            isEnabled = true

            XCTAssertEqual(settings.disableLinkPreviews, preference)
            let reloadedSettings = ExtensionSettings(defaults: defaults, isLinkPreviewGenerationEnabled: { true })
            XCTAssertEqual(reloadedSettings.disableLinkPreviews, preference)
        }
    }

    func testThatItHandlesLinkPreviewPreferenceChange() {
        XCTAssertFalse(settings.disableLinkPreviews)

        settings.disableLinkPreviews = true
        XCTAssertTrue(settings.disableLinkPreviews)

        settings.disableLinkPreviews = false
        XCTAssertFalse(settings.disableLinkPreviews)
    }
}
