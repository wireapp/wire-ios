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
@testable import Wire

final class DeviceInfoViewModelTests: XCTestCase {
    let mockDeviceActionsHandler = MockDeviceDetailsViewActions()
    let mockConversationUserClientDetailsActions = MockConversationUserClientDetailsActions()
    var deviceInfoViewModel: DeviceInfoViewModel!

    override func setUp() {
        super.setUp()

        setup(e2eIdentityCertificate: .mockExpired)
    }

    func setup(
        e2eIdentityCertificate: E2eIdentityCertificate,
        isFromConversation: Bool = false,
        isSelfClient: Bool = false
    ) {
        let userClient = MockUserClient()
        userClient.e2eIdentityCertificate = e2eIdentityCertificate
        userClient.verified = true

        deviceInfoViewModel = DeviceInfoViewModel(
            title: "",
            addedDate: "",
            proteusID: "",
            userClient: userClient,
            isSelfClient: isSelfClient,
            gracePeriod: 0,
            mlsCiphersuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
            isFromConversation: isFromConversation,
            actionsHandler: mockDeviceActionsHandler,
            conversationClientDetailsActions: mockConversationUserClientDetailsActions
        )
    }

    func test_actionButtonsWhenCertStateIsValid() {
        showViewAlwaysAndUpdateWhenIsSelfClient_HideGetAllways(.mockValid, isFromConversation: false)
    }

    func test_actionButtonsWhenCertStateIsValidAndFromConversation() {
        showViewAlwaysAndUpdateWhenIsSelfClient_HideGetAllways(.mockValid, isFromConversation: true)
    }

    func test_actionButtonsWhenCertStateIsInvalid() {
        showViewAlwaysAndUpdateWhenIsSelfClient_HideGetAllways(.mockInvalid, isFromConversation: false)
    }

    func test_actionButtonsWhenCertStateIsInvalidAndFromConversation() {
        showViewAlwaysAndUpdateWhenIsSelfClient_HideGetAllways(.mockValid, isFromConversation: true)
    }

    func test_actionButtonsWhenCertStateNotActivated() {
        showGetWhenIsSelfClient(.mockNotActivated, isFromConversation: false)
    }

    func test_actionButtonsWhenCertStateNotActivatedAndFromConversation() {
        showGetWhenIsSelfClient(.mockNotActivated, isFromConversation: false)
    }

    func test_actionButtonsWhenCertStateIsRevoked() {
        showViewAlwaysAndUpdateWhenIsSelfClient_HideGetAllways(.mockRevoked, isFromConversation: false)
    }

    func test_actionButtonsWhenCertStateIsExpired() {
        showViewAlwaysAndUpdateWhenIsSelfClient_HideGetAllways(.mockExpired, isFromConversation: false)
    }

    func testThatItCallsShowMyDeviceMethodInConversationUserClientDetailsActionsHandler_WhenOnShowMyDeviceTappedIsCalled(
    ) {
        let expectation = expectation(description: "copy value should be called")

        mockConversationUserClientDetailsActions.showMyDevice_MockMethod = {
            expectation.fulfill()
        }
        deviceInfoViewModel.onShowMyDeviceTapped()
        wait(for: [expectation])
    }

    func testThatItCallsHowToDoThatMethodInConversationUserClientDetailsActionsHandler_WhenOnHowToDoThatTappedIsCalled(
    ) {
        let expectation = expectation(description: "copy value should be called")

        mockConversationUserClientDetailsActions.howToDoThat_MockMethod = {
            expectation.fulfill()
        }
        deviceInfoViewModel.onHowToDoThatTapped()
        wait(for: [expectation])
    }

    func testThatItCallsDownloadCertificateMethodInDeviceActionsHandler_WhenDownloadCertificateIsCalled() {
        let expectation = expectation(description: "copy value should be called")

        mockDeviceActionsHandler.downloadE2EIdentityCertificateCertificate_MockMethod = { [weak self] value in
            XCTAssertEqual(self?.deviceInfoViewModel.e2eIdentityCertificate, value)
            expectation.fulfill()
        }
        deviceInfoViewModel.downloadE2EIdentityCertificate()
        wait(for: [expectation])
    }

    func testThatItCallsCopyValueMethodInDeviceActionsHandler_WhenCopyValueMethodIsCalled() {
        let copyValue = String.randomRemoteIdentifier()
        let expectation = expectation(description: "copy value should be called")

        mockDeviceActionsHandler.copyToClipboard_MockMethod = { value in
            XCTAssertEqual(copyValue, value)
            expectation.fulfill()
        }
        deviceInfoViewModel.copyToClipboard(copyValue)
        wait(for: [expectation])
    }

    func testThatItCallsUpdateVerifiedMethodInDeviceActionsHandler_WhenUpdateVerifiedMethodIsCalled() async {
        let isVerfied = false
        let expectation = expectation(description: "update verified should be called")
        mockDeviceActionsHandler.updateVerified_MockMethod = { value in
            XCTAssertEqual(isVerfied, value)
            expectation.fulfill()
            return true
        }
        await deviceInfoViewModel.updateVerifiedStatus(isVerfied)
        await fulfillment(of: [expectation])
    }

    func testThatItCallsRemoveDeviceMethodInDeviceActionsHandler_WhenRemoveDeviceMethodIsCalled() async {
        let expectation = expectation(description: "removeDevice should be called")
        mockDeviceActionsHandler.removeDevice_MockMethod = {
            expectation.fulfill()
            return true
        }
        await deviceInfoViewModel.removeDevice()
        await fulfillment(of: [expectation])
    }

    func testThatItCallsEnrollMethodInDeviceActionsHandler_WhenEnrolClientMethodIsCalled() async {
        let expectation = expectation(description: "enrollClient should be called")
        mockDeviceActionsHandler.enrollClient_MockMethod = {
            expectation.fulfill()
            return ""
        }
        await deviceInfoViewModel.enrollClient()
        await fulfillment(of: [expectation])
    }

    func testThatItCallsshowCertificateUpdateSuccess_WhenEnrolCertificateIsSuccessful() async {
        let expectation = expectation(description: "showCertificateUpdateSuccess should be called")
        mockDeviceActionsHandler.enrollClient_MockValue = ""
        deviceInfoViewModel.showCertificateUpdateSuccess = { _ in
            expectation.fulfill()
        }
        await deviceInfoViewModel.enrollClient()
        await fulfillment(of: [expectation])
    }

    // MARK: - Helpers

    fileprivate func showViewAlwaysAndUpdateWhenIsSelfClient_HideGetAllways(
        _ e2eIdentityCertificate: E2eIdentityCertificate,
        isFromConversation: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for isSelfClient in [true, false] {
            setup(
                e2eIdentityCertificate: e2eIdentityCertificate,
                isFromConversation: isFromConversation,
                isSelfClient: isSelfClient
            )
            XCTAssertEqual(deviceInfoViewModel.showCertificateButtonVisible, true)
            XCTAssertEqual(deviceInfoViewModel.getCertificateButtonVisible, false)
            XCTAssertEqual(deviceInfoViewModel.updateCertificateButtonVisible, isSelfClient)
        }
    }

    fileprivate func showGetWhenIsSelfClient(
        _ e2eIdentityCertificate: E2eIdentityCertificate,
        isFromConversation: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for isSelfClient in [true, false] {
            setup(e2eIdentityCertificate: .mockNotActivated, isFromConversation: true, isSelfClient: isSelfClient)
            XCTAssertEqual(deviceInfoViewModel.showCertificateButtonVisible, false)
            XCTAssertEqual(deviceInfoViewModel.getCertificateButtonVisible, isSelfClient)
            XCTAssertEqual(deviceInfoViewModel.updateCertificateButtonVisible, false)
        }
    }
}
