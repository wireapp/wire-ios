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

import WireCoreCrypto
import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

final class IsSelfUserE2EICertifiedUseCaseTests: ZMBaseManagedObjectTest {

    private var sut: IsSelfUserE2EICertifiedUseCase!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockSafeCoreCrypto: MockSafeCoreCrypto!

    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        super.setUp()

        setupUsersClientsAndConversation()
        let mockCoreCrypto = MockCoreCryptoProtocol()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCryptoRequireMLS_MockValue = mockSafeCoreCrypto
        sut = .init(context: context, coreCryptoProvider: mockCoreCryptoProvider)
    }

    override func tearDown() {
        sut = nil
        mockCoreCryptoProvider = nil
        mockSafeCoreCrypto = nil

        super.tearDown()
    }

    func testExpiredCertificateResultsToFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { conversationID, userIDs in
            XCTAssertEqual(conversationID, .init(base64Encoded: "qE4EdglNFI53Cm4soIFZ/rUMVL4JfCgcE4eo86QVxSc=")!)
            XCTAssertEqual(userIDs, ["36dfe52f-157d-452b-a9c1-98f7d9c1815d@example.com"])
            return [userIDs[0]: [.withStatus(.valid), .withStatus(.expired)]]
        }

        // When
        let isCertified = try await sut.invoke()

        // Then
        XCTAssertFalse(isCertified)
    }

    func testRevokedCertificateResultsToFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { _, userIDs in
            [userIDs[0]: [.withStatus(.valid), .withStatus(.revoked)]]
        }

        // When
        let isCertified = try await sut.invoke()

        // Then
        XCTAssertFalse(isCertified)
    }

    func testValidCertificatesResultsToTrue() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { _, userIDs in
            [userIDs[0]: [.withStatus(.valid), .withStatus(.valid)]]
        }

        // When
        let isCertified = try await sut.invoke()

        // Then
        XCTAssertTrue(isCertified)
    }

    // MARK: - Helpers

    private func setupUsersClientsAndConversation() {
        context.performAndWait {
            setupMLSSelfConversation()
            setupSelfUser()
            setupClients()
        }
    }

    private func setupMLSSelfConversation() {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = .init(uuidString: "11AE029E-AFFA-4B81-9095-497797C0C0FA")
        conversation.mlsGroupID = .init(base64Encoded: "qE4EdglNFI53Cm4soIFZ/rUMVL4JfCgcE4eo86QVxSc=")
        conversation.messageProtocol = .mls
        conversation.mlsStatus = .ready
        conversation.conversationType = .`self`
    }

    private func setupSelfUser() {
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = .init(uuidString: "36DFE52F-157D-452B-A9C1-98F7D9C1815D")
        selfUser.domain = "example.com"
    }

    private func setupClients() {
        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = UUID.create().uuidString
        selfClient.user = .selfUser(in: context)
        context.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: ZMPersistedClientIdKey)

        let otherClient = UserClient.insertNewObject(in: context)
        otherClient.remoteIdentifier = UUID.create().uuidString
        otherClient.user = .selfUser(in: context)
    }
}

extension WireIdentity {

    fileprivate static func withStatus(_ status: DeviceStatus) -> Self {
        .init(
            clientId: "A",
            handle: "B",
            displayName: "C",
            domain: "D",
            certificate: "E",
            status: status,
            thumbprint: "F"
        )
    }
}
