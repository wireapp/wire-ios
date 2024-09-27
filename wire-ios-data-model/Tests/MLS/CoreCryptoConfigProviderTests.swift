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
import XCTest
@testable import WireDataModel

// MARK: - MockCoreCryptoKeyProvider

class MockCoreCryptoKeyProvider: CoreCryptoKeyProvider {
    enum MockError: Error {
        case unmockedMethodCalled
        case coreCryptoKeyError
    }

    typealias CoreCryptoKeyMock = () throws -> Data

    var coreCryptoKeyMock: CoreCryptoKeyMock?

    override func coreCryptoKey(createIfNeeded: Bool) throws -> Data {
        guard let mock = coreCryptoKeyMock else {
            throw MockError.unmockedMethodCalled
        }
        return try mock()
    }
}

// MARK: - CoreCryptoConfigProviderTests

class CoreCryptoConfigProviderTests: ZMConversationTestsBase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        mockCoreCryptoKeyProvider = MockCoreCryptoKeyProvider()
        sut = CoreCryptoConfigProvider(coreCryptoKeyProvider: mockCoreCryptoKeyProvider)
    }

    override func tearDown() {
        mockCoreCryptoKeyProvider = nil
        super.tearDown()
    }

    // MARK: - Core crypto configuration

    func test_itReturnsInitialCoreCryptoConfiguration() throws {
        try syncMOC.performGroupedAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            // mock core crypto key
            let key = Data([1, 2, 3])
            self.mockCoreCryptoKeyProvider.coreCryptoKeyMock = {
                key
            }

            // WHEN
            let configuration = try self.sut.createInitialConfiguration(
                sharedContainerURL: OtrBaseTest.sharedContainerURL,
                userID: selfUser.remoteIdentifier,
                createKeyIfNeeded: true
            )

            // THEN
            XCTAssertEqual(configuration.key, key.base64EncodedString())
            XCTAssertEqual(configuration.path, self.expectedPath(selfUser))
        }
    }

    func test_itReturnsFullCoreCryptoConfiguration() throws {
        try syncMOC.performGroupedAndWait {
            // GIVEN
            // create self client and self user
            self.createSelfClient()
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.domain = "example.domain.com"

            // mock core crypto key
            let key = Data([1, 2, 3])
            self.mockCoreCryptoKeyProvider.coreCryptoKeyMock = {
                key
            }

            // WHEN
            let configuration = try self.sut.createFullConfiguration(
                sharedContainerURL: OtrBaseTest.sharedContainerURL,
                selfUser: selfUser,
                createKeyIfNeeded: true
            )

            // THEN
            XCTAssertEqual(configuration.key, key.base64EncodedString())
            XCTAssertEqual(configuration.path, self.expectedPath(selfUser))
            XCTAssertEqual(configuration.clientID, try self.expectedClientID(selfUser))
        }
    }

    func test_itThrows_FailedToGetQualifiedClientID() {
        syncMOC.performAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.domain = "example.domain.com"

            // we're not creating the self client

            // THEN
            assertItThrows(error: CoreCryptoConfigProvider.ConfigurationSetupFailure.failedToGetClientId) {
                // WHEN
                _ = try sut.createFullConfiguration(
                    sharedContainerURL: OtrBaseTest.sharedContainerURL,
                    selfUser: selfUser,
                    createKeyIfNeeded: true
                )
            }
        }
    }

    func test_itThrows_FailedToGetCoreCryptoKey() {
        syncMOC.performAndWait {
            // GIVEN
            // create self client and set self user
            createSelfClient()
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.domain = "example.domain.com"

            // set the core crypto key provider mock
            mockCoreCryptoKeyProvider.coreCryptoKeyMock = {
                throw MockCoreCryptoKeyProvider.MockError.coreCryptoKeyError
            }

            // THEN
            assertItThrows(error: CoreCryptoConfigProvider.ConfigurationSetupFailure.failedToGetCoreCryptoKey) {
                // WHEN
                _ = try sut.createFullConfiguration(
                    sharedContainerURL: OtrBaseTest.sharedContainerURL,
                    selfUser: selfUser,
                    createKeyIfNeeded: true
                )
            }
        }
    }

    // MARK: - Client ID

    func test_itReturnsClientIDForSelfUser() throws {
        try syncMOC.performGroupedAndWait {
            // GIVEN
            self.createSelfClient()
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.domain = "example.domain.com"

            // WHEN
            let id = try self.sut.clientID(of: selfUser)

            // THEN
            XCTAssertEqual(id, try self.expectedClientID(selfUser))
        }
    }

    func test_itThrows_WhenFailedToGetClientID() {
        syncMOC.performAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.domain = "example.domain.com"

            let expectedError = CoreCryptoConfigProvider.ConfigurationSetupFailure.failedToGetClientId

            // THEN
            assertItThrows(error: expectedError) {
                // WHEN
                _ = try sut.clientID(of: selfUser)
            }
        }
    }

    // MARK: Private

    private var mockCoreCryptoKeyProvider: MockCoreCryptoKeyProvider!
    private var sut: CoreCryptoConfigProvider!

    // MARK: - Helpers

    private func expectedClientID(_ selfUser: ZMUser) throws -> String {
        try XCTUnwrap(MLSClientID(user: selfUser)).rawValue
    }

    private func expectedPath(_ selfUser: ZMUser) -> String {
        let accountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: selfUser.remoteIdentifier,
            applicationContainer: OtrBaseTest.sharedContainerURL
        )
        return accountDirectory.appendingPathComponent("corecrypto").path
    }
}
