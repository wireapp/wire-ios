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
import WireDataModelSupport
@testable import WireRequestStrategy

final class GetE2eIdentityCertificatesUseCaseTests: XCTestCase {

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()

    private var sut: GetE2eIdentityCertificatesUseCase!
    private var coreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var safeCoreCrypto: MockSafeCoreCrypto!
    private var coreCrypto: MockCoreCryptoProtocol!

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        coreCrypto = MockCoreCryptoProtocol()
        safeCoreCrypto = MockSafeCoreCrypto(coreCrypto: coreCrypto)
        coreCryptoProvider = MockCoreCryptoProviderProtocol()
        coreCryptoProvider.coreCryptoRequireMLS_MockValue = safeCoreCrypto
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        coreCrypto = nil
        safeCoreCrypto = nil
        coreCryptoProvider = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func testGetCertificates() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let clientIDs = [MLSClientID.random(), .random()]

        // Mock
        coreCrypto.getDeviceIdentitiesConversationIdDeviceIds_MockMethod = { _, _ in
            return [
                .init(
                    clientId: "client1",
                    handle: "@foo",
                    displayName: "Ms Foo ",
                    domain: "local domain",
                    certificate: "???",
                    status: .valid,
                    thumbprint: "???"
                )
            ]
        }

        // When
        let certificates = try await sut.invoke(
            mlsGroupId: groupID,
            clientIds: clientIDs
        )

        // Then
        

        // first cert is valid
        // second cert is not valid
    }

    // test get identities for some clients returns certificates

    // test identites that don't match user name and or handle are invalid.

}
