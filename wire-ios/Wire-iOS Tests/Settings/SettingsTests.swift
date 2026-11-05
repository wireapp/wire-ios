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

import WireCommonComponents
import XCTest

@testable import Wire

final class SettingsTests: XCTestCase {

    override static func tearDown() {
        Settings.shared.reset()
    }

    func testThatInitializationPreservesDisabledLinkPreviews() throws {
        try XCTSkipUnless(SecurityFlags.generateLinkPreviews.isEnabled)
        let previousPreference = ExtensionSettings.shared.disableLinkPreviews
        defer { ExtensionSettings.shared.disableLinkPreviews = previousPreference }
        ExtensionSettings.shared.disableLinkPreviews = true

        _ = Settings()

        XCTAssertTrue(ExtensionSettings.shared.disableLinkPreviews)
        XCTAssertTrue(Settings.disableLinkPreviews)
    }

    func testThatEnumCanBeWrittenAndReturnAnEnum() {
        // GIVEN
        let settingsCamera: SettingsCamera = .back

        // WHEN
        Settings.shared[.preferredCamera] = settingsCamera

        // THEN
        XCTAssertEqual(settingsCamera, Settings.shared[.preferredCamera])
    }
}
