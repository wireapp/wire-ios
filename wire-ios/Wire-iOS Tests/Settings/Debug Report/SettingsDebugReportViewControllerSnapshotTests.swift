// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import XCTest
@testable import Wire

final class SettingsDebugReportViewControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: SettingsDebugReportViewController!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        accentColor = .strongBlue
        sut = SettingsDebugReportViewController(viewModel: MockSettingsDebugReportViewModelProtocol())
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Test

    func disable_testForInitState() {
        // disabling this test for the release/cycle-3.112 branch because SnapshotHelper doesn't support `UIViewController` yet
        // it should be reenabled when merging with develop
    }

}
