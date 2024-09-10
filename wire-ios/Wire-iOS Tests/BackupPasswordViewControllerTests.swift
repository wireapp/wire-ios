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

final class BackupPasswordViewControllerTests: XCTestCase {
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    func testDefaultState() {
        // GIVEN
        let sut = makeViewController()

        // WHEN & THEN
        snapshotHelper.verify(matching: sut.view)
    }

    func testThatItCallsTheCallback() {
        // GIVEN
        let validPassword = "Password123!"
        let expectation = self.expectation(description: "Callback called")
        let sut = makeViewController()
        sut.onCompletion = { password in
            XCTAssertEqual(password, validPassword)
            expectation.fulfill()
        }

        // WHEN
        XCTAssertTrue(
            sut.textField(
                UITextField(),
                shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                replacementString: validPassword
            )
        )
        XCTAssertFalse(
            sut.textField(
                UITextField(),
                shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                replacementString: "\n"
            )
        )

        // THEN
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testThatWhitespacesPasswordIsNotGood() {
        // GIVEN
        let sut = makeViewController()
        sut.onCompletion = { _ in
            XCTFail("Sut is nil")
        }

        // WHEN
        XCTAssertFalse(sut.textField(UITextField(), shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "              "))
        XCTAssertFalse(sut.textField(UITextField(), shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "\n"))
    }

    // MARK: - Helpers

    private func makeViewController() -> BackupPasswordViewController {
        BackupPasswordViewController()
    }
}
