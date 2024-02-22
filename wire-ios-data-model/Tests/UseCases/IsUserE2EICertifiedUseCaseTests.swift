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

final class IsUserE2EICertifiedUseCaseTests: ZMBaseManagedObjectTest {

    private var sut: IsUserE2EICertifiedUseCase!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockSafeCoreCrypto: MockSafeCoreCrypto!
    private var selfUser: ZMUser!
    private var mlsSelfConversation: ZMConversation!

    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        super.setUp()

        setupUsersClientsAndConversation()
        let mockCoreCrypto = MockCoreCryptoProtocol()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        sut = .init(schedule: .immediate, coreCryptoProvider: mockCoreCryptoProvider)
    }

    override func tearDown() {
        sut = nil
        mockCoreCryptoProvider = nil
        mockSafeCoreCrypto = nil
        selfUser = nil
        mlsSelfConversation = nil

        super.tearDown()
    }

    func testExpiredCertificateForSelfUserResultsInFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { conversationID, userIDs in
            XCTAssertEqual(conversationID, .init(base64Encoded: "qE4EdglNFI53Cm4soIFZ/rUMVL4JfCgcE4eo86QVxSc=")!)
            // eventually a userID will have the suffix "@example.com", but it's low prio on the Core Crypto team
            XCTAssertEqual(userIDs, ["36dfe52f-157d-452b-a9c1-98f7d9c1815d"])
            return [userIDs[0]: [.withStatus(.valid), .withStatus(.expired)]]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertFalse(isCertified)
    }

    func testRevokedCertificateResultsInFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { _, userIDs in
            [userIDs[0]: [.withStatus(.valid), .withStatus(.revoked)]]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertFalse(isCertified)
    }

    func testValidCertificatesResultsInTrue() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { _, userIDs in
            [userIDs[0]: [.withStatus(.valid), .withStatus(.valid)]]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertTrue(isCertified)
    }

    func testEmptyResultEvaluatesToFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { _, _ in
            [:]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertFalse(isCertified)
    }

    func testEmptyIdentitiesEvaluatesToFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { _, userIDs in
            [userIDs[0]: []]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertFalse(isCertified)
    }

    // TODO: test selfUser <> selfConversation check
    // TODO: test for other users

    // MARK: - Helpers

    private func setupUsersClientsAndConversation() {
        context.performAndWait {
            let helper = ModelHelper()
            mlsSelfConversation = helper.createMLSSelfConversation(
                id: .init(uuidString: "11AE029E-AFFA-4B81-9095-497797C0C0FA")!,
                mlsGroupID: .init(base64Encoded: "qE4EdglNFI53Cm4soIFZ/rUMVL4JfCgcE4eo86QVxSc="),
                in: context
            )
            selfUser = helper.createSelfUser(
                id: .init(uuidString: "36DFE52F-157D-452B-A9C1-98F7D9C1815D")!,
                domain: "example.com",
                in: context
            )
            helper.createSelfClient(in: context)
            helper.createClient(for: .selfUser(in: context))
        }
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
            thumbprint: "F",
            serialNumber: "G",
            notBefore: 0,
            notAfter: 0
        )
    }
}
