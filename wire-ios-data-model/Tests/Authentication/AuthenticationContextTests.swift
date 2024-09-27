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

import LocalAuthentication
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

final class AuthenticationContextTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        mockStorage = MockLAContextStorable()
    }

    override func tearDown() {
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testEvaluatedPolicyDomainState_givenInit_thenIsNil() {
        // given
        let context = makeContext()

        // when
        // then
        XCTAssertNil(context.evaluatedPolicyDomainState)
    }

    func testEvaluatedPolicyDomainState_givenNotEvaluatedLAContext_thenIsNil() {
        // given
        mockStorage.context = LAContext()

        let context = makeContext()

        // when
        // then
        XCTAssertNil(context.evaluatedPolicyDomainState)
    }

    func testEvaluatedPolicyDomainState_givenEvaluatedLAContext_thenIsNotNil() {
        // given
        let context = makeContext()

        // when
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)

        // then
        XCTAssertNotNil(context.evaluatedPolicyDomainState)
    }

    func testCanEvaluatePolicy_givenPolicyDeviceOwnerAuthentication_thenIsSuccessful() {
        // given
        var expectedError: NSError?
        let context = makeContext()

        // when
        let success = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &expectedError)

        // then
        XCTAssertTrue(success)
        XCTAssertNil(expectedError)
    }

    // MARK: Private

    // Executing `evaluatePolicy` triggers authentication prompt to the user
    // so we do not test the behavior in this unit test.

    private var mockStorage: MockLAContextStorable!

    // MARK: - Helpers

    private func makeContext() -> AuthenticationContext {
        AuthenticationContext(storage: mockStorage)
    }
}
