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
@testable import Wire
import WireSyncEngineSupport

final class DeviceDetailsViewActionsHandlerTests: XCTestCase, CoreDataFixtureTestHelper {

    var coreDataFixture: CoreDataFixture!
    var client: UserClient!
    var mockSession: UserSessionMock!
    var emailCredentials: ZMEmailCredentials!

    let saveFileManager = MockSaveFileManager()
    let mockMLSClientResolver = MockMLSClientResolver()
    let mockGetIsE2eIdentityEnabled = MockGetIsE2EIdentityEnabledUsecaseProtocol()
    let mockGetE2eIdentityCertificates = MockGetE2eIdentityCertificatesUsecaseProtocol()

    override func setUp() {
        super.setUp()
        DeveloperDeviceDetailsSettingsSelectionViewModel.isE2eIdentityViewEnabled = false
        coreDataFixture = CoreDataFixture()
        client = mockUserClient()
        mockSession = UserSessionMock(mockUser: .createSelfUser(name: "Joe"))
        emailCredentials = ZMEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")
    }

    func testGivenCertificateWhenDownladActionIsInvokedThenSaveFileManagerSaveFileIsCalled() {
        let expectation = expectation(description: "Save file should be called")
        saveFileManager.saveValueIsCalled = { _, _, _ in
            expectation.fulfill()
        }
        let deviceActionHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            conversationId: Data(),
            saveFileManager: saveFileManager,
            mlsClientResolver: mockMLSClientResolver,
            getE2eIdentityEnabled: mockGetIsE2eIdentityEnabled,
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates
        )
        deviceActionHandler.downloadE2EIdentityCertificate(certificate: .mock())
        wait(for: [expectation], timeout: 0.5)
    }

    func testWhenFetchCertificateIsInvokedThenValidCertificateIsReturned() async throws {
        let deviceActionHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            conversationId: Data(),
            saveFileManager: MockSaveFileManager(),
            mlsClientResolver: mockMLSClientResolver,
            getE2eIdentityEnabled: mockGetIsE2eIdentityEnabled,
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates
        )
        let returnedCertificate: E2eIdentityCertificate = .mock()
        mockGetE2eIdentityCertificates.invokeConversationIdClientIds_MockMethod = { _, _ in
            return [returnedCertificate]
        }
        let fetchedCertificate = await deviceActionHandler.getCertificate()
        XCTAssertEqual(fetchedCertificate, returnedCertificate)
    }

}

extension E2eIdentityCertificate {

    static func mock(
        with certificateDetails: String = .mockCertificate(),
        status: E2EIdentityCertificateStatus = .valid,
        notValidBefore: Date = .now - .oneDay,
        expiryDate: Date = .now,
        sertialNumber: String = .mockSerialNumber
    ) -> E2eIdentityCertificate {
        return .init(
            certificateDetails: certificateDetails,
            mlsThumbprint: .mockMlsThumbprint,
            notValidBefore: notValidBefore,
            expiryDate: expiryDate,
            certificateStatus: status,
            serialNumber: sertialNumber
        )
    }

}
