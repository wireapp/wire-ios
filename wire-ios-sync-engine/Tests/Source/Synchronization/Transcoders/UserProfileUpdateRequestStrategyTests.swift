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

import XCTest
@testable import WireSyncEngine

class UserProfileUpdateRequestStrategyTests: MessagingTest {
    var sut: UserProfileUpdateRequestStrategy!
    var userProfileUpdateStatus: TestUserProfileUpdateStatus!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        userProfileUpdateStatus = TestUserProfileUpdateStatus(
            managedObjectContext: uiMOC,
            analytics: MockAnalytics()
        )
        sut = UserProfileUpdateRequestStrategy(
            managedObjectContext: uiMOC,
            applicationStatus: mockApplicationStatus,
            userProfileUpdateStatus: userProfileUpdateStatus
        )
    }

    override func tearDown() {
        sut = nil
        userProfileUpdateStatus = nil
        mockApplicationStatus = nil
        super.tearDown()
    }
}

// MARK: - Request generation

extension UserProfileUpdateRequestStrategyTests {
    func testThatItDoesNotCreateAnyRequestWhenIdle() {
        // GIVEN
        // already authenticated in setup

        // THEN
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItCreatesARequestToUpdatePassword() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/self/password", method: .put, payload: [
            "new_password": credentials.password!,
        ] as NSDictionary, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToChangeEmail() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        let newEmail = "mario@example.com"
        try! userProfileUpdateStatus.requestEmailChange(email: newEmail)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)

        // THEN
        XCTAssertEqual(request?.path, "/access/self/email")
        XCTAssertEqual(request?.method, .put)
        XCTAssertEqual(request?.needsCookie, true)
        let emailInPayload = request?.payload?.asDictionary()?["email"] as? String
        XCTAssertEqual(emailInPayload, newEmail)
    }

    func testThatItCreatesARequestToUpdateEmailAfterUpdatingPassword() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/access/self/email", method: .put, payload: [
            "email": credentials.email!,
        ] as NSDictionary, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToCheckHandleAvailability() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(
            path: "/users/handles/\(handle)",
            method: .head,
            payload: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToSetHandle() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)

        // THEN
        let payload: NSDictionary = ["handle": handle]
        let expected = ZMTransportRequest(
            path: "/self/handle",
            method: .put,
            payload: payload,
            apiVersion: APIVersion.v0.rawValue
        )
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToFindHandleSuggestion() {
        // GIVEN
        userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        guard let handles = userProfileUpdateStatus.suggestedHandlesToCheck else {
            XCTFail()
            return
        }

        // WHEN
        let possibleRequest = sut.nextRequest(for: .v0)

        // THEN
        guard let request = possibleRequest else {
            XCTFail()
            return
        }

        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.path, "/users/handles")
        guard let payloadDictionary = request.payload?.asDictionary(),
              let payloadHandles = payloadDictionary["handles"] as? [String]
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(payloadHandles, handles)
        XCTAssertEqual(payloadDictionary["return"] as? Int, 1)
    }
}

// MARK: - Parsing response

extension UserProfileUpdateRequestStrategyTests {
    // MARK: - Setting email and password

    func testThatCallsDidUpdatePasswordSuccessfully() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: successResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidUpdatePasswordSuccessfully, 1)
    }

    func testThatCallsDidUpdatePasswordSuccessfullyOn403() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: invalidCredentialsResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidUpdatePasswordSuccessfully, 1)
    }

    func testThatCallsDidFailPasswordUpdateOn400() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: errorResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailPasswordUpdate, 1)
    }

    func testThatItCallsDidUpdateEmailSuccessfullyWhenSettingEmailAndPassword() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: successResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidUpdateEmailSuccessfully, 1)
    }

    func testThatItCallsDidFailEmailUpdateWithInvalidEmail() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: invalidEmailResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailEmailUpdate.count, 1)
        guard let error = userProfileUpdateStatus.recordedDidFailEmailUpdate.first else { return }
        XCTAssertEqual((error as NSError).code, UserSessionErrorCode.invalidEmail.rawValue)
    }

    func testThatItCallsDidFailEmailUpdateWithDuplicatedEmail() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: keyExistsResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailEmailUpdate.count, 1)
        guard let error = userProfileUpdateStatus.recordedDidFailEmailUpdate.first else { return }
        XCTAssertEqual((error as NSError).code, UserSessionErrorCode.emailIsAlreadyRegistered.rawValue)
    }

    func testThatItCallsDidFailEmailUpdateWithUnknownError() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "mario@example.com", password: "princess")
        try! userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: errorResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailEmailUpdate.count, 1)
        guard let error = userProfileUpdateStatus.recordedDidFailEmailUpdate.first else { return }
        XCTAssertEqual((error as NSError).code, UserSessionErrorCode.unknownError.rawValue)
    }

    // MARK: - Email change

    func testThatItCallsDidUpdateEmailSuccessfullyWhenChangingEmail() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        try! userProfileUpdateStatus.requestEmailChange(email: "mario@example.com")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: successResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidUpdateEmailSuccessfully, 1)
    }

    // MARK: - Check handle availability

    func testThatItCallsDidFetchHandle() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: successResponse(path: request?.path))

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFetchHandle, [handle])
    }

    func testThatItCallsDidNotFindHandle() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: notFoundResponse(path: request!.path))

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidNotFindHandle, [handle])
    }

    func testThatItCallsFailedToCheckHandleAvailability() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: errorResponse(path: request?.path))

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailRequestToFetchHandle, [handle])
    }

    // MARK: - Setting handle

    func testThatItCallsSuccessSetHandle() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: successResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidSetHandle, 1)
    }

    func testThatItCallsFailedToSetHandle() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: errorResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailToSetHandle, 1)
    }

    func testThatItCallsFailedToSetHandleBecauseExisting() {
        // GIVEN
        let handle = "martha"
        userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: handleExistsResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailToSetAlreadyExistingHandle, 1)
    }

    // MARK: - Suggesting handles

    func testThatItCallsDidFinddHandleSuggestion() {
        // GIVEN
        userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        guard let handles = userProfileUpdateStatus.suggestedHandlesToCheck, handles.count > 10 else {
            XCTFail()
            return
        }
        let expectedHandle = handles[5]

        // WHEN
        let request = sut.nextRequest(for: .v0)
        let handlesInResponse = [handles[5], handles[9], handles[10]]
        request?.complete(with: ZMTransportResponse(
            payload: handlesInResponse as NSArray,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        ))

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFindHandleSuggestion, [expectedHandle])
    }

    func testThatItCallsFailedToFindHandleSuggestionIfNoHandlesAreReturned() {
        // GIVEN
        userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = sut.nextRequest(for: .v0)
        request?.complete(with: ZMTransportResponse(
            payload: [] as NSArray,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        ))

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidNotFindAvailableHandleSuggestion, 1)
    }

    func testThatItCallsFailedToFindHandleSuggestionInCaseOfError() {
        // GIVEN
        userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        guard let request = sut.nextRequest(for: .v0) else {
            XCTFail()
            return
        }
        request.complete(with: errorResponse())

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileUpdateStatus.recordedDidFailToFindHandleSuggestion, 1)
    }
}

// MARK: - Helpers

extension UserProfileUpdateRequestStrategyTests {
    func errorResponse(path: String? = nil) -> ZMTransportResponse {
        if let url = path.flatMap(URL.init) {
            return ZMTransportResponse(originalUrl: url, httpStatus: 400, error: nil)
        }

        return ZMTransportResponse(
            payload: nil,
            httpStatus: 400,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func notFoundResponse(path: String? = nil) -> ZMTransportResponse {
        if let url = path.flatMap(URL.init) {
            return ZMTransportResponse(originalUrl: url, httpStatus: 404, error: nil)
        }

        return ZMTransportResponse(
            payload: nil,
            httpStatus: 404,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func badRequestResponse() -> ZMTransportResponse {
        ZMTransportResponse(
            payload: ["label": "bad-request"] as NSDictionary,
            httpStatus: 400,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func handleExistsResponse() -> ZMTransportResponse {
        ZMTransportResponse(
            payload: ["label": "handle-exists"] as NSDictionary,
            httpStatus: 409,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func keyExistsResponse() -> ZMTransportResponse {
        ZMTransportResponse(
            payload: ["label": "key-exists"] as NSDictionary,
            httpStatus: 409,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func invalidPhoneNumberResponse() -> ZMTransportResponse {
        ZMTransportResponse(
            payload: ["label": "invalid-phone"] as NSDictionary,
            httpStatus: 400,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func lastIdentityResponse() -> ZMTransportResponse {
        ZMTransportResponse(
            payload: ["label": "last-identity"] as NSDictionary,
            httpStatus: 403,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func invalidEmailResponse() -> ZMTransportResponse {
        ZMTransportResponse(
            payload: ["label": "invalid-email"] as NSDictionary,
            httpStatus: 400,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func invalidCredentialsResponse() -> ZMTransportResponse {
        ZMTransportResponse(
            payload: ["label": "invalid-credentials"] as NSDictionary,
            httpStatus: 403,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    func successResponse(path: String? = nil) -> ZMTransportResponse {
        if let url = path.flatMap(URL.init) {
            return ZMTransportResponse(originalUrl: url, httpStatus: 200, error: nil)
        }
        return ZMTransportResponse(
            payload: nil,
            httpStatus: 200,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }
}

extension ZMTransportResponse {
    convenience init(originalUrl: URL, httpStatus: Int, error: Error?) {
        let headers = ["Content-Type": "application/json"]
        let httpResponse = HTTPURLResponse(
            url: originalUrl,
            statusCode: httpStatus,
            httpVersion: nil,
            headerFields: headers
        )
        self.init(httpurlResponse: httpResponse!, data: nil, error: error, apiVersion: APIVersion.v0.rawValue)
    }
}

class TestUserProfileUpdateStatus: UserProfileUpdateStatus {
    var recordedDidFailEmailUpdate: [Error] = []
    var recordedDidUpdateEmailSuccessfully = 0
    var recordedDidChangePhoneSuccesfully = 0
    var recordedDidFailPasswordUpdate = 0
    var recordedDidUpdatePasswordSuccessfully = 0
    var recordedDidFailChangingPhone: [Error] = []
    var recordedDidFetchHandle: [String] = []
    var recordedDidFailRequestToFetchHandle: [String] = []
    var recordedDidNotFindHandle: [String] = []
    var recordedDidSetHandle = 0
    var recordedDidFailToSetHandle = 0
    var recordedDidFailToSetAlreadyExistingHandle = 0
    var recordedDidFailToFindHandleSuggestion = 0
    var recordedDidNotFindAvailableHandleSuggestion = 0
    var recordedDidFindHandleSuggestion: [String] = []

    override func didFailEmailUpdate(error: Error) {
        recordedDidFailEmailUpdate.append(error)
        super.didFailEmailUpdate(error: error)
    }

    override func didUpdateEmailSuccessfully() {
        recordedDidUpdateEmailSuccessfully += 1
        super.didUpdateEmailSuccessfully()
    }

    override func didFailPasswordUpdate() {
        recordedDidFailPasswordUpdate += 1
        super.didFailPasswordUpdate()
    }

    override func didUpdatePasswordSuccessfully() {
        recordedDidUpdatePasswordSuccessfully += 1
        super.didUpdatePasswordSuccessfully()
    }

    override func didFetchHandle(handle: String) {
        recordedDidFetchHandle.append(handle)
        super.didFetchHandle(handle: handle)
    }

    override func didFailRequestToFetchHandle(handle: String) {
        recordedDidFailRequestToFetchHandle.append(handle)
        super.didFailRequestToFetchHandle(handle: handle)
    }

    override func didNotFindHandle(handle: String) {
        recordedDidNotFindHandle.append(handle)
        super.didNotFindHandle(handle: handle)
    }

    override func didSetHandle() {
        recordedDidSetHandle += 1
        super.didSetHandle()
    }

    override func didFailToSetHandle() {
        recordedDidFailToSetHandle += 1
        super.didFailToSetHandle()
    }

    override func didFailToSetAlreadyExistingHandle() {
        recordedDidFailToSetAlreadyExistingHandle += 1
        super.didFailToSetAlreadyExistingHandle()
    }

    override func didNotFindAvailableHandleSuggestion() {
        recordedDidNotFindAvailableHandleSuggestion += 1
        super.didNotFindAvailableHandleSuggestion()
    }

    override func didFailToFindHandleSuggestion() {
        recordedDidFailToFindHandleSuggestion += 1
        super.didFailToFindHandleSuggestion()
    }

    override func didFindHandleSuggestion(handle: String) {
        recordedDidFindHandleSuggestion.append(handle)
        super.didFindHandleSuggestion(handle: handle)
    }
}
