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

import WireDataModelSupport
import WireRequestStrategySupport
import WireSyncEngineSupport
import XCTest
@testable import Wire

// MARK: - DeviceDetailsViewActionsHandlerTests

final class DeviceDetailsViewActionsHandlerTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!
    var client: UserClient!
    var mockSession: UserSessionMock!
    var emailCredentials: UserEmailCredentials!

    var saveFileManager: MockSaveFileManager!
    var mockGetIsE2eIdentityEnabled: MockGetIsE2EIdentityEnabledUseCaseProtocol!
    var mockGetE2eIdentityCertificates: MockGetE2eIdentityCertificatesUseCaseProtocol!
    var mockGetProteusFingerprint: MockGetUserClientFingerprintUseCaseProtocol!
    var mockContextProvider: MockContextProvider!
    var mockEnrollE2eICertificateUseCase: EnrollE2EICertificateUseCaseProtocol!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        client = mockUserClient()
        mockSession = UserSessionMock(mockUser: .createSelfUser(name: "Joe"))
        emailCredentials = UserEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")
        saveFileManager = MockSaveFileManager()
        mockGetIsE2eIdentityEnabled = MockGetIsE2EIdentityEnabledUseCaseProtocol()
        mockGetE2eIdentityCertificates = MockGetE2eIdentityCertificatesUseCaseProtocol()
        mockGetProteusFingerprint = MockGetUserClientFingerprintUseCaseProtocol()
        mockContextProvider = MockContextProvider()
        mockEnrollE2eICertificateUseCase = MockEnrollE2EICertificateUseCaseProtocol()
    }

    override func tearDown() {
        coreDataFixture = nil
        client = nil
        mockSession = nil
        emailCredentials = nil
        saveFileManager = nil
        mockGetIsE2eIdentityEnabled = nil
        mockGetE2eIdentityCertificates = nil
        mockGetProteusFingerprint = nil
        mockContextProvider = nil
        mockEnrollE2eICertificateUseCase = nil
        super.tearDown()
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
            saveFileManager: saveFileManager,
            getProteusFingerprint: mockGetProteusFingerprint,
            contextProvider: mockContextProvider,
            e2eiCertificateEnrollment: mockEnrollE2eICertificateUseCase
        )
        deviceActionHandler.downloadE2EIdentityCertificate(certificate: .mock())
        wait(for: [expectation], timeout: 0.5)
    }

    func testThatItReturnsFingerPrint_WhenGetFingerPrintIsInvoked() async throws {
        let deviceActionHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            saveFileManager: MockSaveFileManager(),
            getProteusFingerprint: mockGetProteusFingerprint,
            contextProvider: mockContextProvider,
            e2eiCertificateEnrollment: mockEnrollE2eICertificateUseCase
        )
        let testFingerPrint = String.randomAlphanumerical(length: 16)
        mockGetProteusFingerprint.invokeUserClient_MockMethod = { _ in
            testFingerPrint.data(using: .utf8)
        }
        let fingerPrint = await deviceActionHandler.getProteusFingerPrint()
        XCTAssertEqual(fingerPrint, testFingerPrint.splitStringIntoLines(charactersPerLine: 16).uppercased())
    }
}

extension E2eIdentityCertificate {
    static func mock(
        with certificateDetails: String = .mockCertificate,
        status: E2EIdentityCertificateStatus = .valid,
        notValidBefore: Date = .now - .oneDay,
        expiryDate: Date = .now,
        sertialNumber: String = .mockSerialNumber
    ) -> E2eIdentityCertificate {
        .init(
            clientId: "sdjksksd",
            certificateDetails: certificateDetails,
            mlsThumbprint: .mockMlsThumbprint,
            notValidBefore: notValidBefore,
            expiryDate: expiryDate,
            certificateStatus: status,
            serialNumber: sertialNumber
        )
    }
}
