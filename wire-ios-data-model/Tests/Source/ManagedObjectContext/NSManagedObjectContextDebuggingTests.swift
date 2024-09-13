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

import Foundation

final class NSManagedObjectContextDebuggingTests: ZMBaseManagedObjectTest {
    func testThatItInvokesCallbackWhenFailedToSave() {
        // GIVEN
        makeChangeThatWillCauseRollback()
        let expectation = customExpectation(description: "callback invoked")
        uiMOC.errorOnSaveCallback = { moc, error in
            XCTAssertEqual(moc, self.uiMOC)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        // WHEN
        performIgnoringZMLogError {
            self.uiMOC.saveOrRollback()
        }

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK: - Helper

private let longString = (0 ..< 50)
    .reduce(into: "") { partialResult, _ in
        partialResult.append("AaAaAaAaAa")
    }

extension NSManagedObjectContextDebuggingTests {
    func makeChangeThatWillCauseRollback() {
        let user = ZMUser.selfUser(in: uiMOC)
        // this user name is too long and will fail validation
        user.name = longString
    }
}
