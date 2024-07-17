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

@testable import Wire
import WireSyncEngine
import XCTest

class AuthenticationEmailVerificationRequiredErrorHandlerTests: XCTestCase {

    var sut = AuthenticationEmailVerificationRequiredErrorHandler()

    func testThatItHandlesTheEventWhenErrorAndStepAreCorrect() throws {
        // GIVEN
        let email = "test@email.com"
        let password = "12345678"
        let credentials = UserEmailCredentials(email: email, password: password)
        let step = AuthenticationFlowStep.authenticateEmailCredentials(credentials)
        let error = NSError.userSessionError(code: .accountIsPendingVerification, userInfo: nil)

        // WHEN
        let result = sut.handleEvent(currentStep: step, context: error)

        // THEN
        let actions = try XCTUnwrap(result)
        XCTAssertEqual(actions.count, 2)
        guard case .hideLoadingView = try XCTUnwrap(actions.first) else {
            XCTFail("Unexpected value")
            return
        }

        guard case .requestEmailVerificationCode(email: email, password: password) = try XCTUnwrap(actions.last) else {
            XCTFail("Unexpected value")
            return
        }
    }

    func testThatItDoesntHandleTheEventWhenErrorIsNotCorrect() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "test@example.com", password: "12345678")
        let step = AuthenticationFlowStep.registerEmailCredentials(credentials, isResend: false)
        let error = NSError.userSessionError(code: .accessTokenExpired, userInfo: nil)

        // WHEN
        let result = sut.handleEvent(currentStep: step, context: error)

        // THEN
        XCTAssertNil(result)
    }

}
