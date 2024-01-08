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

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        client = mockUserClient()
        mockSession = UserSessionMock(mockUser: .createSelfUser(name: "Joe"))
        emailCredentials = ZMEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")
    }

    func testWhenDownladActionIsInvokedThenDownloadFileManagerDownloadFileIsCalled() {
        let expectation = expectation(description: "Download file should be called")
        let downloadFileManager = MockDownloadFileManager()
        downloadFileManager.downloadValueIsCalled = { _, _, _ in
            expectation.fulfill()
        }
        let deviceActionHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            e2eIdentityProvider: MockE2eIdentityProvider(),
            mlsProvider: MockMLSProvider(isMLSEnbaled: false),
            downloadFileManager: downloadFileManager
        )
        deviceActionHandler.downloadE2EIdentityCertificate()
        wait(for: [expectation])
    }

    func testWhenFetchCertificateIsInvokedThenValidCertificateIsReturned() async {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let deviceActionHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            e2eIdentityProvider: e2eIdentityProvider,
            mlsProvider: MockMLSProvider(isMLSEnbaled: false),
            downloadFileManager: MockDownloadFileManager()
        )
        let fetchedCertificate = await deviceActionHandler.fetchCertificate()
        XCTAssertNotNil(fetchedCertificate)
        XCTAssertEqual(fetchedCertificate!.certificateDetails, e2eIdentityProvider.certificate.certificateDetails)
    }
}
