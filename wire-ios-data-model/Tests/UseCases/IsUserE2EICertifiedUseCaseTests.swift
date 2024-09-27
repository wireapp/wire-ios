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

// MARK: - IsUserE2EICertifiedUseCaseTests

final class IsUserE2EICertifiedUseCaseTests: ZMBaseManagedObjectTest {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        setupUsersAndClients(in: context)
        setupMLSSelfConversations(in: context)
        setupOneOnOneConversations(in: context)
        setupClientIDs(in: context)
        let mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.getClientIdsConversationId_MockValue = clientIDs.compactMap(\.data)
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        mockFeatureRepository = .init()
        mockFeatureRepository.fetchE2EI_MockValue = .init(status: .enabled, config: .init())
        sut = .init(
            schedule: .immediate,
            coreCryptoProvider: mockCoreCryptoProvider,
            featureRepository: mockFeatureRepository,
            featureRepositoryContext: context
        )
    }

    override func tearDown() {
        sut = nil
        mockCoreCryptoProvider = nil
        mockSafeCoreCrypto = nil
        mockFeatureRepository = nil
        clientIDs = nil
        selfUser = nil
        otherUser = nil
        mlsSelfConversation = nil
        oneOnOneConversation = nil

        super.tearDown()
    }

    // MARK: Self User

    func testExpiredCertificateForSelfUserResultsInFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto
            .getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] conversationID, userIDs in
                XCTAssertEqual(conversationID, .init(base64Encoded: "qE4EdglNFI53Cm4soIFZ/rUMVL4JfCgcE4eo86QVxSc=")!)
                // eventually a userID will have the suffix "@example.com", but it's low prio on the Core Crypto team
                XCTAssertEqual(userIDs, ["36dfe52f-157d-452b-a9c1-98f7d9c1815d"])
                return [
                    userIDs[0]: [
                        .with(clientID: clientIDs![0].rawValue, status: .valid),
                        .with(clientID: clientIDs![1].rawValue, status: .expired),
                    ],
                ]
            }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertFalse(isCertified)
    }

    func testRevokedCertificateForSelfUserResultsInFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![0].rawValue, status: .valid),
                    .with(clientID: clientIDs![1].rawValue, status: .revoked),
                ],
            ]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertFalse(isCertified)
    }

    func testValidCertificatesForSelfUserResultsInTrue() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![0].rawValue, status: .valid),
                    .with(clientID: clientIDs![1].rawValue, status: .valid),
                ],
            ]
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
        mockSafeCoreCrypto.coreCrypto.getClientIdsConversationId_MockValue = []
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
        mockSafeCoreCrypto.coreCrypto.getClientIdsConversationId_MockValue = []
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

    // MARK: Other User

    func testRevokedCertificateOfOtherUserResultsInFalse() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![2].rawValue, status: .valid),
                    .with(clientID: clientIDs![3].rawValue, status: .revoked),
                ],
            ]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: oneOnOneConversation,
            user: otherUser
        )

        // Then
        XCTAssertFalse(isCertified)
    }

    func testValidCertificatesForOtherUserResultsInTrue() async throws {
        // Given
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![2].rawValue, status: .valid),
                    .with(clientID: clientIDs![3].rawValue, status: .valid),
                ],
            ]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: oneOnOneConversation,
            user: otherUser
        )

        // Then
        XCTAssertTrue(isCertified)
    }

    // MARK: Edge Cases

    func testPassingSelfConversationFromViewContext() async throws {
        // Given
        setupMLSSelfConversations(in: uiMOC)
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![0].rawValue, status: .valid),
                    .with(clientID: clientIDs![1].rawValue, status: .valid),
                ],
            ]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertTrue(isCertified)
    }

    func testPassingSelfUserFromViewContext() async throws {
        // Given
        setupUsersAndClients(in: uiMOC)
        setupClientIDs(in: uiMOC)
        mockSafeCoreCrypto.coreCrypto.getClientIdsConversationId_MockValue = clientIDs.compactMap(\.data)
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![0].rawValue, status: .valid),
                    .with(clientID: clientIDs![1].rawValue, status: .valid),
                ],
            ]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertTrue(isCertified)
    }

    func testPassingOneOnOneConversationFromViewContext() async throws {
        // Given
        setupMLSSelfConversations(in: uiMOC)
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![0].rawValue, status: .valid),
                    .with(clientID: clientIDs![1].rawValue, status: .valid),
                ],
            ]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: mlsSelfConversation,
            user: selfUser
        )

        // Then
        XCTAssertTrue(isCertified)
    }

    func testPassingOtherUserFromViewContext() async throws {
        // Given
        setupUsersAndClients(in: uiMOC)
        setupClientIDs(in: uiMOC)
        mockSafeCoreCrypto.coreCrypto.getClientIdsConversationId_MockValue = clientIDs.compactMap(\.data)
        mockSafeCoreCrypto.coreCrypto.getUserIdentitiesConversationIdUserIds_MockMethod = { [clientIDs] _, userIDs in
            [
                userIDs[0]: [
                    .with(clientID: clientIDs![2].rawValue, status: .valid),
                    .with(clientID: clientIDs![3].rawValue, status: .valid),
                ],
            ]
        }

        // When
        let isCertified = try await sut.invoke(
            conversation: oneOnOneConversation,
            user: otherUser
        )

        // Then
        XCTAssertTrue(isCertified)
    }

    // MARK: Private

    private var sut: IsUserE2EICertifiedUseCase!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockSafeCoreCrypto: MockSafeCoreCrypto!
    private var mockFeatureRepository: MockFeatureRepositoryInterface!
    private var selfUser: ZMUser!
    private var otherUser: ZMUser!
    private var mlsSelfConversation: ZMConversation!
    private var oneOnOneConversation: ZMConversation!
    private var clientIDs: [MLSClientID]! // first two have the userID of `selfUser`, last two of `otherUser`

    private var context: NSManagedObjectContext { syncMOC }

    // MARK: - Helpers

    private func setupUsersAndClients(
        in context: NSManagedObjectContext
    ) {
        context.performAndWait {
            let helper = ModelHelper()
            selfUser = helper.createSelfUser(
                id: .init(uuidString: "36DFE52F-157D-452B-A9C1-98F7D9C1815D")!,
                domain: "example.com",
                in: context
            )
            helper.createSelfClient(in: context)
            helper.createClient(for: .selfUser(in: context))

            otherUser = helper.createUser(in: context)
            helper.createClient(for: otherUser)
            helper.createClient(for: otherUser)
        }
    }

    private func setupMLSSelfConversations(
        in context: NSManagedObjectContext
    ) {
        context.performAndWait {
            let helper = ModelHelper()
            mlsSelfConversation = helper.createSelfMLSConversation(
                id: .init(uuidString: "11AE029E-AFFA-4B81-9095-497797C0C0FA")!,
                mlsGroupID: .init(base64Encoded: "qE4EdglNFI53Cm4soIFZ/rUMVL4JfCgcE4eo86QVxSc="),
                in: context
            )
        }
    }

    private func setupOneOnOneConversations(
        in context: NSManagedObjectContext
    ) {
        context.performAndWait {
            oneOnOneConversation = ModelHelper().createOneOnOne(with: selfUser, in: context)
            oneOnOneConversation.mlsGroupID = .random()
            oneOnOneConversation.messageProtocol = .mls
            oneOnOneConversation.mlsStatus = .ready
        }
    }

    private func setupClientIDs(
        in context: NSManagedObjectContext
    ) {
        clientIDs = context.performAndWait {
            [selfUser, selfUser, otherUser, otherUser]
                .map { user in
                    var clientID = MLSClientID.random()
                    clientID.userID = user?.remoteIdentifier.transportString() ?? clientID.userID
                    return clientID
                }
        }
    }
}

extension WireIdentity {
    fileprivate static func with(clientID: String, status: DeviceStatus) -> Self {
        .init(
            clientId: clientID,
            status: status,
            thumbprint: "F",
            credentialType: .x509,
            x509Identity: X509Identity(
                handle: "B",
                displayName: "C",
                domain: "D",
                certificate: "E",
                serialNumber: "G",
                notBefore: 0,
                notAfter: 0
            )
        )
    }
}
