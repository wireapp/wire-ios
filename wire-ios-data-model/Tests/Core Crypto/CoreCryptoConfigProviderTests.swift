//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundationSupport
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

class MockCoreCryptoKeyProvider: CoreCryptoKeyProvider {

    enum MockError: Swift.Error {
        case unmockedMethodCalled
        case coreCryptoKeyError
    }

    typealias CoreCryptoKeyMock = () throws -> Data

    var coreCryptoKeyMock: CoreCryptoKeyMock?

    override func coreCryptoKey(allowCreation: Bool, path: String) async throws -> Data {
        guard let mock = coreCryptoKeyMock else { throw MockError.unmockedMethodCalled }
        return try mock()
    }
}

class CoreCryptoConfigProviderTests: ZMConversationTestsBase {

    private var mockCoreCryptoKeyProvider: MockCoreCryptoKeyProvider!
    private var sut: CoreCryptoConfigProvider!
    private var mockCoreCryptoKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
    private var sharedContainerURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sharedContainerURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        mockCoreCryptoKeyProvider =
            MockCoreCryptoKeyProvider(
                coreCryptoKeyMigrationManager: mockCoreCryptoKeyMigrationManager,
                userID: UUID(),
                storage: UserDefaultsProtocolMock(),
                staleKeysTracker: MockStaleCoreCryptoKeysTrackerProtocol()
            )
        sut = CoreCryptoConfigProvider(coreCryptoKeyProvider: mockCoreCryptoKeyProvider)
    }

    override func tearDown() {
        mockCoreCryptoKeyProvider = nil
        sharedContainerURL = nil
        super.tearDown()
    }

    // MARK: - Core crypto configuration

    func test_itReturnsInitialCoreCryptoConfiguration() async throws {
        // GIVEN
        let selfUserID: UUID = syncMOC.performAndWait { [syncMOC] in
            let user = ZMUser.selfUser(in: syncMOC)
            user.remoteIdentifier = UUID.create()
            return user.remoteIdentifier
        }

        // mock core crypto key
        let key = Data([1, 2, 3])
        mockCoreCryptoKeyProvider.coreCryptoKeyMock = {
            key
        }

        // WHEN
        let configuration = try await sut.createInitialConfiguration(
            sharedContainerURL: sharedContainerURL,
            userID: selfUserID,
            allowKeyCreation: true
        )

        // THEN
        XCTAssertEqual(configuration.key, key)
        XCTAssertEqual(configuration.path, expectedPath(selfUserID))
    }

    func test_itThrows_FailedToGetCoreCryptoKey() async {
        // GIVEN
        let selfUserID: UUID = syncMOC.performAndWait { [syncMOC] in
            let user = ZMUser.selfUser(in: syncMOC)
            user.remoteIdentifier = UUID.create()
            return user.remoteIdentifier
        }

        // set the core crypto key provider mock
        mockCoreCryptoKeyProvider.coreCryptoKeyMock = {
            throw MockCoreCryptoKeyProvider.MockError.coreCryptoKeyError
        }

        // THEN
        await assertItThrows(error: CoreCryptoConfigProvider.ConfigurationSetupFailure.failedToGetCoreCryptoKey) {
            // WHEN
            _ = try await sut.createInitialConfiguration(
                sharedContainerURL: sharedContainerURL,
                userID: selfUserID,
                allowKeyCreation: true
            )
        }
    }

    // MARK: - Helpers

    private func expectedPath(_ selfUserId: UUID) -> String {
        let accountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: selfUserId,
            applicationContainer: sharedContainerURL
        )
        return accountDirectory.appendingPathComponent("corecrypto").path
    }
}
