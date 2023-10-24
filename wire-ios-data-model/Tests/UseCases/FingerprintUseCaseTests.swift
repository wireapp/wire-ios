////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import XCTest
@testable import WireDataModel

class FingerprintUseCaseTests: ZMBaseManagedObjectTest {
    var sut: FingerprintUseCase!
    var mockProteusProvider: MockProteusProvider!

    override func setUp() {
        DeveloperFlag.storage = .random()!
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
        DeveloperFlag.storage = .standard
    }

    // MARK: - fetchRemoteFingerprint

    func test_fetchRemoteFingerprint_with_Cryptobox() async {
        // GIVEN
        sut = createSut(proteusEnabled: false)

        var userClient: UserClient!
        syncMOC.performAndWait {
            userClient = self.createSelfClient(onMOC: syncMOC)
        }

        // WHEN
        let result = await sut.fetchRemoteFingerprint(for: userClient)

        // THEN
        XCTAssertEqual(mockProteusProvider.mockKeyStore.accessEncryptionContextCount, 1)
    }

    func test_fetchRemoteFingerprint_ProteusViaCoreCryptoFlagEnabled() async {
        // GIVEN
        sut = createSut(proteusEnabled: true)

        var userClient: UserClient!
        syncMOC.performAndWait {
            userClient = self.createSelfClient(onMOC: syncMOC)
        }
        let fingerprint = "test"
        mockProteusProvider.mockProteusService.remoteFingerprintForSession_MockValue = fingerprint

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

        let localFingerprint: String = "test"

        syncMOC.performAndWait {
            _ = self.createSelfClient(onMOC: syncMOC)
        }

        mockProteusProvider.mockProteusService.localFingerprint_MockValue = localFingerprint

        // WHEN
        guard let result = await sut.localFingerprint() else {
            XCTFail("missing expected data")
            return
        }

        // THEN
        XCTAssertEqual(String(data: result, encoding: .utf8), localFingerprint)
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

    private func createSut(proteusEnabled: Bool) -> FingerprintUseCase {
        mockProteusProvider = MockProteusProvider(mockKeyStore: self.spyForTests(), useProteusService: proteusEnabled)
        return FingerprintUseCase(proteusProvider: mockProteusProvider, managedObjectContext: syncMOC)
    }

}
