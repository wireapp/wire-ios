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
            e2eIdentityProvider: MockE2eIdentityProvider(),
            mlsProvider: MockMLSProvider(isMLSEnbaled: false),
            saveFileManager: saveFileManager
        )
        deviceActionHandler.downloadE2EIdentityCertificate(certificate: .mock())
        wait(for: [expectation], timeout: 0.5)
    }

    func testWhenFetchCertificateIsInvokedThenValidCertificateIsReturned() async {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let deviceActionHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            e2eIdentityProvider: e2eIdentityProvider,
            mlsProvider: MockMLSProvider(isMLSEnbaled: false),
            saveFileManager: MockSaveFileManager()
        )
        let fetchedCertificate = await deviceActionHandler.fetchCertificate()
        XCTAssertNotNil(fetchedCertificate)
        XCTAssertEqual(fetchedCertificate!.certificateDetails, e2eIdentityProvider.certificate.certificateDetails)
    }
}

private extension E2eIdentityCertificate {

    static func mock(
        with certificateDetails: String = .random(length: 100),
        status: String = "valid",
        expiryDate: Date = .now,
        sertialNumber: String = .random(length: 16)
    ) -> E2eIdentityCertificate {
        return .init(
            certificateDetails: certificateDetails,
            expiryDate: expiryDate,
            certificateStatus: status,
            serialNumber: sertialNumber
        )
    }

}
