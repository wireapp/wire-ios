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

final class DeviceDetailsViewActionsHandlerTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!
    var client: UserClient!
    var mockSession: UserSessionMock!
    var emailCredentials: ZMEmailCredentials!
    let saveFileManager = MockSaveFileManager()
    let mockMLSClientResolver = MockMLSClentResolver()
    override func setUp() {
        super.setUp()
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
            e2eIdentityProvider: MockValidE2eIdentityProvider(),
            saveFileManager: saveFileManager,
            mlsClientResolver: mockMLSClientResolver
        )
        deviceActionHandler.downloadE2EIdentityCertificate(certificate: .mock())
        wait(for: [expectation], timeout: 0.5)
    }

    func testWhenFetchCertificateIsInvokedThenValidCertificateIsReturned() async {
        let e2eIdentityProvider = MockValidE2eIdentityProvider()
        let deviceActionHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            e2eIdentityProvider: e2eIdentityProvider,
            saveFileManager: MockSaveFileManager(),
            mlsClientResolver: mockMLSClientResolver
        )
        let fetchedCertificate = await deviceActionHandler.fetchCertificate()
        XCTAssertNotNil(fetchedCertificate)
        XCTAssertEqual(fetchedCertificate!.certificateDetails, e2eIdentityProvider.certificate.certificateDetails)
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
