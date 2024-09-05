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
import WireDataModelSupport
import WireSyncEngineSupport
import WireTesting
import XCTest

@testable import WireSyncEngine

final class GetUserClientFingerprintUseCaseTests: MessagingTest {
    var sut: GetUserClientFingerprintUseCase!

    var mockProteusService: MockProteusServiceInterface!
    var mockProteusProvider: MockProteusProvider!
    var mockSessionEstablisher: MockSessionEstablisherInterface!

    let fingerprint = "1234"

    override func setUp() {
        DeveloperFlag.storage = .temporary()
        mockProteusService = MockProteusServiceInterface()
        mockSessionEstablisher = MockSessionEstablisherInterface()
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        mockProteusService = nil
        mockProteusProvider = nil
        mockSessionEstablisher = nil
        super.tearDown()
        DeveloperFlag.storage = .standard
    }

    // MARK: - invoke() establishSession

    func test_invoke_ShouldEstablishSession_IfNoSessionEstablished() async {
        await internalTestEstablishSession(sessionEstablished: false)
    }

    func test_invoke_ShouldNotEstablishSession_IfSessionEstablished() async {
        await internalTestEstablishSession(sessionEstablished: true)
    }

    func internalTestEstablishSession(sessionEstablished: Bool) async {
        // GIVEN
        // we force the flag on here,
        // since ProteusProvider is created on the fly when accessed by managedObjectContext
        // when checking the hasSessionWithSelfClient
        DeveloperFlag.proteusViaCoreCrypto.enable(true)
        syncMOC.performAndWait {
            syncMOC.proteusService = mockProteusService
        }
        sut = createSut(proteusEnabled: true)

        mockProteusService.sessionExistsId_MockValue = sessionEstablished
        var userClient: UserClient!
        await syncMOC.perform {
            userClient = self.createSelfClient()
            userClient.user?.domain = "example.com"
        }

        let expectation = XCTestExpectation(description: "should call establishSession")
        expectation.isInverted = sessionEstablished
        mockSessionEstablisher.establishSessionWithApiVersion_MockMethod = { _, _ in
            expectation.fulfill()
        }

        // WHEN
        let result = await sut.invoke(userClient: userClient)

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(result, fingerprint.data(using: .utf8))
    }

    // MARK: - fetchRemoteFingerprint

    func test_fetchRemoteFingerprint_with_Cryptobox() async {
        // GIVEN
        sut = createSut(proteusEnabled: false)

        var userClient: UserClient!
        await syncMOC.perform {
            userClient = self.createSelfClient()
        }

        // WHEN
        _ = await sut.fetchRemoteFingerprint(for: userClient)

        // THEN
        XCTAssertEqual(mockProteusProvider.mockKeyStore.accessEncryptionContextCount, 1)
    }

    func test_fetchRemoteFingerprint_ProteusViaCoreCryptoFlagEnabled() async {
        // GIVEN
        sut = createSut(proteusEnabled: true)

        var userClient: UserClient!
        await syncMOC.perform {
            userClient = self.createSelfClient()
        }

        // WHEN
        let result = await sut.fetchRemoteFingerprint(for: userClient)

        // THEN
        XCTAssertEqual(mockProteusProvider.mockKeyStore.accessEncryptionContextCount, 0)
        XCTAssertEqual(result, fingerprint.data(using: .utf8))
    }

    // MARK: - localFingerprint

    func test_itLoadsLocalFingerprint_ProteusViaCoreCryptoFlagEnabled() async {

        // GIVEN
        sut = createSut(proteusEnabled: true)

        await syncMOC.perform {
            _ = self.createSelfClient()
        }

        // WHEN
        guard let result = await sut.localFingerprint() else {
            XCTFail("missing expected data")
            return
        }

        // THEN
        XCTAssertEqual(String(decoding: result, as: UTF8.self), fingerprint)
    }

    func test_itLoadsLocalFingerprint_ProteusViaCoreCryptoFlagDisabled() async {
        // GIVEN
        sut = createSut(proteusEnabled: false)

        // WHEN
        _ = await sut.localFingerprint()

        // THEN
        XCTAssertEqual(mockProteusProvider.mockKeyStore.accessEncryptionContextCount, 1)
    }

    // MARK: - Helpers

    private func createSut(proteusEnabled: Bool) -> GetUserClientFingerprintUseCase {
        mockProteusProvider = MockProteusProvider(mockProteusService: mockProteusService,
                                                  useProteusService: proteusEnabled)
        mockProteusProvider.mockProteusService.localFingerprint_MockMethod = {
            return self.fingerprint
        }
        mockProteusProvider.mockProteusService.remoteFingerprintForSession_MockMethod = { _ in
            return self.fingerprint
        }

        return GetUserClientFingerprintUseCase(proteusProvider: mockProteusProvider,
                                               sessionEstablisher: mockSessionEstablisher,
                                               managedObjectContext: syncMOC)
    }

}
