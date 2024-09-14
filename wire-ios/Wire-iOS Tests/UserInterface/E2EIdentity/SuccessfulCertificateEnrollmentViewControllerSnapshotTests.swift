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

final class SuccessfulCertificateEnrollmentViewControllerSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper_!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    func testThatItShouldShowAppropriateMessage_WhenEnrolE2eIdentityIsSuccessful() {
        let sut = SuccessfulCertificateEnrollmentViewController(isUpdateMode: false)
        snapshotHelper.verify(matching: sut)
    }

    func testThatItShouldShowAppropriateMessage_WhenUpdateE2eIdentityIsSuccessful() {
        let sut = SuccessfulCertificateEnrollmentViewController(isUpdateMode: true)
        snapshotHelper.verify(matching: sut)
    }
}
