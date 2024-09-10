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
@testable import WireSyncEngine

class RegistrationCredentialVerificationStrategyTests: MessagingTest {
    var registrationStatus: TestRegistrationStatus!
    var sut: WireSyncEngine.RegistationCredentialVerificationStrategy!

    override func setUp() {
        super.setUp()
        registrationStatus = TestRegistrationStatus()
        sut = WireSyncEngine.RegistationCredentialVerificationStrategy(
            groupQueue: self.syncMOC,
            status: registrationStatus
        )
    }

    override func tearDown() {
        sut = nil
        registrationStatus = nil

        super.tearDown()
    }

    // MARK: - nil request tests

    func testThatItDoesNotReturnRequestIfThePhaseIsNone() {
        let request = sut.nextRequest(for: .v0)
        XCTAssertNil(request)
    }

    // MARK: - Send activation code tests

    func testThatItReturnsARequestWhenStateIsSendActivationCode() {
        // given
        let email = "john@smith.com"
        let path = "/activate/send"
        let payload = [
            "email": email,
            "locale": NSLocale.formattedLocaleIdentifier()!,
        ]

        let transportRequest = ZMTransportRequest(
            path: path,
            method: .post,
            payload: payload as ZMTransportData,
            apiVersion: APIVersion.v0.rawValue
        )
        registrationStatus.phase = .sendActivationCode(unverifiedEmail: email)

        // when

        let request = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request)
        XCTAssertEqual(request, transportRequest)
    }

    func testThatItNotifiesStatusAfterSuccessfulResponseToSendingActivationCode() {
        // given
        let email = "john@smith.com"
        registrationStatus.phase = .sendActivationCode(unverifiedEmail: email)
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        XCTAssertEqual(registrationStatus.successCalled, 0)
        sut.didReceive(response, forSingleRequest: sut.codeSendingSync)

        // then
        XCTAssertEqual(registrationStatus.successCalled, 1)
    }

    // MARK: - Check activation code tests

    func testThatItReturnsARequestWhenStateIsCheckActivationCode() {
        // given
        let email = "john@smith.com"
        let code = "123456"
        let path = "/activate"
        let payload = [
            "email": email,
            "code": code,
            "dryrun": true,
        ] as [String: Any]

        let transportRequest = ZMTransportRequest(
            path: path,
            method: .post,
            payload: payload as ZMTransportData,
            apiVersion: APIVersion.v0.rawValue
        )
        registrationStatus.phase = .checkActivationCode(unverifiedEmail: email, code: code)

        // when

        let request = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request)
        XCTAssertEqual(request, transportRequest)
    }

    func testThatItNotifiesStatusAfterSuccessfulResponseToCheckActivationCode() {
        // given
        let email = "john@smith.com"
        let code = "123456"
        registrationStatus.phase = .checkActivationCode(unverifiedEmail: email, code: code)
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        XCTAssertEqual(registrationStatus.successCalled, 0)
        sut.didReceive(response, forSingleRequest: sut.codeSendingSync)

        // then
        XCTAssertEqual(registrationStatus.successCalled, 1)
    }
}

extension RegistrationCredentialVerificationStrategyTests: RegistrationStatusStrategyTestHelper {
    func handleResponse(response: ZMTransportResponse) {
        sut.didReceive(response, forSingleRequest: sut.codeSendingSync)
    }

    // MARK: - error tests for verification

    func testThatItNotifiesStatusAfterErrorToEmailVerify_BlacklistEmail() {
        checkSendingCodeResponseError(code: .blacklistedEmail, errorLabel: "blacklisted-email", httpStatus: 403)
    }

    func testThatItNotifiesStatusAfterErrorToEmailVerify_EmailExists() {
        checkSendingCodeResponseError(code: .emailIsAlreadyRegistered, errorLabel: "key-exists", httpStatus: 409)
    }

    func testThatItNotifiesStatusAfterErrorToEmailVerify_InvalidEmail() {
        checkSendingCodeResponseError(code: .invalidEmail, errorLabel: "invalid-email", httpStatus: 400)
    }

    func testThatItNotifiesStatusAfterErrorToEmailVerify_OtherError() {
        checkSendingCodeResponseError(code: .unknownError, errorLabel: "not-clear-what-happened", httpStatus: 414)
    }

    func testThatItNotifiesStatusAfterErrorToEmailVerify_DomainBlocked() {
        checkSendingCodeResponseError(
            code: .domainBlocked,
            errorLabel: "domain-blocked-for-registration",
            httpStatus: 451
        )
    }

    // MARK: - error tests for activation

    func testThatItNotifiesStatusAfterErrorToEmailActivate_InvalidCode() {
        checkActivationResponseError(code: .invalidActivationCode, errorLabel: "invalid-code", httpStatus: 404)
    }

    func testThatItNotifiesStatusAfterErrorToEmailActivation_OtherError() {
        checkActivationResponseError(code: .unknownError, errorLabel: "not-clear-what-happened", httpStatus: 414)
    }

    // MARK: - Helpers

    func checkSendingCodeResponseError(
        code: UserSessionErrorCode,
        errorLabel: String,
        httpStatus: NSInteger,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // given
        let email = "john@smith.com"
        let phase: RegistrationPhase = .sendActivationCode(unverifiedEmail: email)

        // when & then
        checkResponseError(with: phase, code: code, errorLabel: errorLabel, httpStatus: httpStatus)
    }

    func checkActivationResponseError(
        code: UserSessionErrorCode,
        errorLabel: String,
        httpStatus: NSInteger,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // given
        let email = "john@smith.com"
        let activationCode = "123456"
        let phase: RegistrationPhase = .checkActivationCode(unverifiedEmail: email, code: activationCode)

        // when & then
        checkResponseError(with: phase, code: code, errorLabel: errorLabel, httpStatus: httpStatus)
    }
}
