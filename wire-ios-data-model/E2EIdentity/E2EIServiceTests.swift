//
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
import WireCoreCrypto
@testable import WireDataModel
@testable import WireRequestStrategy

class E2EIServiceTests: ZMConversationTestsBase {

    var sut: E2EIService!
    var mockCoreCrypto: MockCoreCrypto!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var e2eiClientId: E2EIClientID!
    var qualifiedClientID: QualifiedClientID!

    override func setUp() {
        super.setUp()

        mockCoreCrypto = MockCoreCrypto()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)

        // create self client and self user
        self.createSelfClient()
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.domain = "example.domain.com"
        selfUser.name = "Monica"
        selfUser.handle = "@monica"

        self.createSelfClient()

        guard let userName = selfUser.name,
              let handle = selfUser.handle,
              let domain = selfUser.domain,
              let selfClientId = selfUser.selfClient()?.remoteIdentifier
        else {
            return
        }

        qualifiedClientID = QualifiedClientID(userID: selfUser.remoteIdentifier,
                                              domain: domain,
                                              clientID: selfClientId)
        e2eiClientId = E2EIClientID(qualifiedClientID: qualifiedClientID)

        sut = E2EIService(coreCrypto: mockSafeCoreCrypto,
                          e2eiClientId: e2eiClientId,
                          userName: userName,
                          handle: handle)

    }

    override func tearDown() {
        sut = nil
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        e2eiClientId = nil
        qualifiedClientID = nil

        super.tearDown()
    }

    func testThatItContainsCorrectAcmeDirectoryInTheResponse() async throws {
        // Expectation
        let expectedacmeDirectory = AcmeDirectory(newNonce: "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
                                                  newAccount: "https://acme.elna.wire.link/acme/defaultteams/new-account",
                                                  newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order")

        // Given
        var mockDirectoryResponseCount = 0

        let acmeResponse = AcmeDirectoriesResponse(newNonce: "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
                                                   newAccount: "https://acme.elna.wire.link/acme/defaultteams/new-account",
                                                   newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order",
                                                   revokeCert: "https://acme.elna.wire.link/acme/defaultteams/revoke-cert",
                                                   keyChange: "https://acme.elna.wire.link/acme/defaultteams/key-change")
        let acmeResponseData = try JSONEncoder.defaultEncoder.encode(acmeResponse)

        // Mock
        let mockE2eIdentity = MockWireE2eIdentity()
        mockE2eIdentity.mockDirectoryResponse = { _ in
            mockDirectoryResponseCount += 1
            return expectedacmeDirectory
        }
        sut.e2eIdentity = mockE2eIdentity

        // When
        let acmeDirectory = try await sut.directoryResponse(directoryData: acmeResponseData)

        // Then
        XCTAssertEqual(mockDirectoryResponseCount, 1)
        XCTAssertEqual(acmeDirectory, expectedacmeDirectory)
    }

    func test1() async throws {
        // Given

        // When
        let acmeDirectory = try await sut.getNewAccountRequest(previousNonce: "")

        // Then

    }

    func test2() async throws {
        // Given

        // When
         try await sut.setAccountResponse(accountData: Data())

        // Then

    }

    func test3() async throws {
        // Given

        // When
        let acmeDirectory = try await sut.getNewOrderRequest(nonce: "")

        // Then

    }

    func test4() async throws {
        // Given

        // When
        try await sut.setOrderResponse(order: Data())

        // Then

    }

    func test5() async throws {
        // Given

        // When
        let acmeDirectory = try await sut.getNewAuthzRequest(url: "", previousNonce: "")

        // Then

    }

    func test6() async throws {
        // Given

        // When
        try await sut.setAuthzResponse(authz: Data())

        // Then

    }

}
