//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import Foundation
import WireCoreCrypto
import WireFoundation
import WireTesting
import XCTest
@testable import WireNetwork

@testable @preconcurrency import WireDataModel
@testable import WireDataModelSupport

@preconcurrency
final class MLSServiceTests: ZMConversationTestsBase, MLSServiceDelegate {

    var sut: MLSService!
    var mockCoreCrypto: MockCoreCryptoProtocol!
    var mockCoreCryptoContext: MockCoreCryptoContextProtocol!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var mockEncryptionService: MockMLSEncryptionServiceInterface!
    var mockDecryptionService: MockMLSDecryptionServiceInterface!
    var mockMLSActionExecutor: MockMLSActionExecutor!
    var mockActionsProvider: MockMLSActionsProviderProtocol!
    var mockStaleMLSKeyDetector: MockStaleMLSKeyDetectorProtocol!
    var userDefaultsTestSuite: UserDefaults!
    var privateUserDefaults: PrivateUserDefaults<MLSService.Keys>!
    var mockSubconversationGroupIDRepository: MockSubconversationGroupIDRepositoryInterface!
    var mockLegacyFeatureRepository: MockLegacyFeatureRepositoryInterface!
    var resetMLSConversationDelegate = MockResetBrokenMLSConversationDelegate()

    let groupID = MLSGroupID(.init([1, 2, 3]))
    let defaultCipherSuite: Feature.MLS.Config.MLSCipherSuite = .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519

    let localDomain = "example.com"

    override func setUp() {
        super.setUp()

        mockCoreCryptoContext = MockCoreCryptoContextProtocol()
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.mockTransaction(context: mockCoreCryptoContext)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockCoreCrypto
        mockEncryptionService = MockMLSEncryptionServiceInterface()
        mockDecryptionService = MockMLSDecryptionServiceInterface()
        mockMLSActionExecutor = MockMLSActionExecutor()
        mockActionsProvider = MockMLSActionsProviderProtocol()
        mockStaleMLSKeyDetector = MockStaleMLSKeyDetectorProtocol()
        userDefaultsTestSuite = UserDefaults.temporary()
        privateUserDefaults = PrivateUserDefaults(userID: userIdentifier, storage: userDefaultsTestSuite)
        mockSubconversationGroupIDRepository = MockSubconversationGroupIDRepositoryInterface()
        mockLegacyFeatureRepository = MockLegacyFeatureRepositoryInterface()

        mockStaleMLSKeyDetector.keyingMaterialUpdatedFor_MockMethod = { _ in }
        mockCoreCryptoProvider.registerEpochObserver_MockMethod = { _ in }
        mockCoreCryptoContext.e2eiIsEnabledCiphersuite_MockValue = false
        mockCoreCryptoContext.clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod = { _, _ in
            100
        }

        mockActionsProvider.fetchBackendPublicKeysIn_MockValue = BackendMLSPublicKeys()
        mockActionsProvider.claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue = []

        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: defaultCipherSuite)
        )

        mockLegacyFeatureRepository.fetchAllowedGlobalOperations_MockValue = Feature.AllowedGlobalOperations(
            status: .enabled,
            config: .init(mlsConversationReset: true)
        )

        resetMLSConversationDelegate.didCatchBrokenMLSConversationGroupIDEpoch_MockMethod = { _, _ in }

        createSut()
    }

    private func createSut() {
        sut = MLSService(
            context: uiMOC,
            notificationContext: uiMOC.notificationContext,
            coreCryptoProvider: mockCoreCryptoProvider,
            encryptionService: mockEncryptionService,
            decryptionService: mockDecryptionService,
            mlsActionExecutor: mockMLSActionExecutor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            userDefaults: userDefaultsTestSuite,
            actionsProvider: mockActionsProvider,
            delegate: self,
            userID: userIdentifier,
            featureRepository: mockLegacyFeatureRepository,
            subconversationGroupIDRepository: mockSubconversationGroupIDRepository,
            localDomain: localDomain
        )
        sut.setResetBrokenMLSConversationDelegate(resetMLSConversationDelegate)
    }

    override func tearDown() {
        sut = nil
        keyMaterialUpdatedExpectation = nil
        mockCoreCryptoContext = nil
        mockCoreCrypto = nil
        mockEncryptionService = nil
        mockDecryptionService = nil
        mockMLSActionExecutor = nil
        mockActionsProvider = nil
        mockStaleMLSKeyDetector = nil
        mockSubconversationGroupIDRepository = nil
        privateUserDefaults = nil
        userDefaultsTestSuite = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func dummyMemberJoinEvent() -> ZMUpdateEvent {
        let payload: NSDictionary = [
            "type": "conversation.member-join",
            "data": "foo"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
    }

    func dummyMemberLeaveEvent() -> ZMUpdateEvent {
        let payload: NSDictionary = [
            "type": "conversation.member-leave",
            "data": "foo"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
    }

    func createKeyPackage(userID: UUID, domain: String) -> WireDataModel.KeyPackage {
        KeyPackage(
            client: Data.random(byteCount: 32).base64EncodedString(),
            domain: domain,
            keyPackage: Data.random(byteCount: 32).base64EncodedString(),
            keyPackageRef: Data.random(byteCount: 32).base64EncodedString(),
            userID: userID
        )
    }

    // MARK: - mlsServiceDelegate

    var pendingProposalCommitExpectations = [MLSGroupID: XCTestExpectation]()
    var keyMaterialUpdatedExpectation: XCTestExpectation?

    // Since SUT may schedule timers to commit pending proposals, we create expectations
    // and fulfill them when SUT informs us the commit was made.

    func mlsServiceDidCommitPendingProposal(for: MLSGroupID) {
        pendingProposalCommitExpectations[groupID]?.fulfill()
    }

    func mlsServiceDidUpdateKeyMaterialForAllGroups() {
        keyMaterialUpdatedExpectation?.fulfill()
    }

    // MARK: - Conference info

    func test_GenerateConferenceInfo_IsSuccessful() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let secretKey = Data.random()
        let epoch: UInt64 = 1

        let member1 = MLSClientID.random()
        let member2 = MLSClientID.random()
        let member3 = MLSClientID.random()

        var mockExportSecretKeyCount = 0
        mockCoreCryptoContext.exportSecretKeyConversationIdKeyLength_MockMethod = { _, _ in
            mockExportSecretKeyCount += 1
            return .init(bytes: secretKey)
        }

        var mockConversationEpochCount = 0
        mockCoreCryptoContext.conversationEpochConversationId_MockMethod = { _ in
            mockConversationEpochCount += 1
            return epoch
        }

        var mockGetClientIDsCount = 0
        mockCoreCryptoContext.getClientIdsConversationId_MockMethod = { groupID in
            mockGetClientIDsCount += 1

            switch groupID {
            case parentGroupID.conversationId:
                return [member1, member2, member3]
                    .compactMap { WireCoreCryptoUniffi.ClientId(bytes: $0.rawValue.utf8Data!) }

            case subconversationGroupID.conversationId:
                return [member1, member2].compactMap { WireCoreCryptoUniffi.ClientId(bytes: $0.rawValue.utf8Data!) }

            default:
                return []
            }
        }

        // When
        let conferenceInfo = try await sut.generateConferenceInfo(
            parentGroupID: parentGroupID,
            subconversationGroupID: subconversationGroupID
        )

        // Then
        XCTAssertEqual(mockExportSecretKeyCount, 1)
        XCTAssertEqual(mockConversationEpochCount, 1)
        XCTAssertEqual(mockGetClientIDsCount, 2)

        let expectedConferenceInfo = MLSConferenceInfo(
            epoch: epoch,
            keyData: secretKey,
            members: [
                MLSConferenceInfo.Member(id: member1, isInSubconversation: true),
                MLSConferenceInfo.Member(id: member2, isInSubconversation: true),
                MLSConferenceInfo.Member(id: member3, isInSubconversation: false)
            ]
        )

        XCTAssertEqual(conferenceInfo, expectedConferenceInfo)
    }

    typealias ConferenceInfoError = MLSService.MLSConferenceInfoError

    func test_GenerateConferenceInfo_Fails() async {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()

        var mockConversationEpochCount = 0
        mockCoreCryptoContext.conversationEpochConversationId_MockMethod = { _ in
            mockConversationEpochCount += 1
            return 0
        }

        mockCoreCryptoContext.exportSecretKeyConversationIdKeyLength_MockMethod = { _, _ in
            throw CoreCryptoError.Other(msg: "conversation not found")
        }

        // When / Then
        await assertItThrows(error: ConferenceInfoError.failedToGenerateConferenceInfo) {
            _ = try await sut.generateConferenceInfo(
                parentGroupID: parentGroupID,
                subconversationGroupID: subconversationGroupID
            )
        }
    }

    // MARK: - Message Encryption

    func test_Encrypt_UsesEncyptionService() async throws {
        // Given
        let message = "foo"
        let groupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference
        let mockResult = MLSDecryptResult.message(.random(), .randomAlphanumerical(length: 3))

        mockDecryptionService.decryptMessageForSubconversationTypeContext_MockValue = [mockResult]

        // When
        let results = try await sut.decrypt(
            message: message,
            for: groupID,
            subconversationType: subconversationType,
            context: nil
        )

        // Then
        XCTAssertEqual(mockDecryptionService.decryptMessageForSubconversationTypeContext_Invocations.count, 1)
        let invocation = mockDecryptionService.decryptMessageForSubconversationTypeContext_Invocations.first
        XCTAssertEqual(invocation?.message, message)
        XCTAssertEqual(invocation?.groupID, groupID)
        XCTAssertEqual(invocation?.subconversationType, subconversationType)
        XCTAssertEqual(results.first, mockResult)
    }

    // MARK: - Message Decryption

    func test_Decrypt_UsesDecyptionService() async throws {
        // Given
        let message = "foo"
        let groupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference

        let mockResult = MLSDecryptResult.message(.random(), .randomAlphanumerical(length: 3))
        mockDecryptionService.decryptMessageForSubconversationTypeContext_MockValue = [mockResult]

        // When
        let results = try await sut.decrypt(
            message: message,
            for: groupID,
            subconversationType: subconversationType,
            context: nil
        )

        // Then
        XCTAssertEqual(mockDecryptionService.decryptMessageForSubconversationTypeContext_Invocations.count, 1)
        let invocation = mockDecryptionService.decryptMessageForSubconversationTypeContext_Invocations.first
        XCTAssertEqual(invocation?.message, message)
        XCTAssertEqual(invocation?.groupID, groupID)
        XCTAssertEqual(invocation?.subconversationType, subconversationType)
        XCTAssertEqual(results.first, mockResult)
    }

    // MARK: - Create group

    func test_CreateGroup_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let removalKey = Data([1, 2, 3])

        mockActionsProvider.fetchBackendPublicKeysIn_MockValue = .init(
            removal: .init(ed25519: removalKey)
        )
        let expectedConfig = ConversationConfiguration(
            ciphersuite: defaultCipherSuite.coreCryptoCipherSuite,
            externalSenders: [ExternalSenderKey(bytes: removalKey)],
            custom: .init(keyRotationSpan: nil, wirePolicy: nil)
        )

        var mockCreateConversationCount = 0
        mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_MockMethod =
            { conversationID, creatorCredentialType, config in
                mockCreateConversationCount += 1

                XCTAssertEqual(conversationID, groupID.conversationId)
                XCTAssertEqual(creatorCredentialType, .basic)
                XCTAssertEqual(config, expectedConfig)
            }

        // When
        try await _ = sut.createGroup(for: groupID)

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.keyingMaterialUpdatedFor_Invocations, [groupID])
    }

    func test_CreateGroup_ThrowsError() async throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let config = ConversationConfiguration(
            ciphersuite: defaultCipherSuite.coreCryptoCipherSuite,
            externalSenders: [],
            custom: .init(keyRotationSpan: nil, wirePolicy: nil)
        )

        var mockCreateConversationCount = 0
        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = {
            mockCreateConversationCount += 1

            XCTAssertEqual($0, groupID.conversationId)
            XCTAssertEqual($1, .basic)
            XCTAssertEqual($2.ciphersuite, config.ciphersuite)
            XCTAssertEqual($2.custom, config.custom)

            throw CoreCryptoError.Other(msg: "malformed identifier")
        }

        // when / then
        do {
            try await _ = sut.createGroup(for: groupID)
            XCTFail("Unexpected success")
        } catch MLSService.MLSGroupCreationError.failedToCreateGroup {
            // Then
            XCTAssertEqual(mockCreateConversationCount, 1)
        }
    }

    func test_CreateGroup_BackendPublicKeysAreFetched() async throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let backendPublicKeys = BackendMLSPublicKeys(removal: .init(ed25519: .init([1, 2, 3])))

        let fetchBackendPublicKeysExpectation = XCTestExpectation(description: "Fetch backend public keys")
        mockActionsProvider.fetchBackendPublicKeysIn_MockMethod = { _ in
            fetchBackendPublicKeysExpectation.fulfill()
            return backendPublicKeys
        }
        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in }

        // When
        _ = try await sut.createGroup(for: groupID)

        // Then
        await fulfillment(of: [fetchBackendPublicKeysExpectation], timeout: 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.keyingMaterialUpdatedFor_Invocations, [groupID])
    }

    func test_CreateGroup_BackendPublicKeysAreNotFetched() async throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let removalKeys = BackendMLSPublicKeys(removal: .init(ed25519: .init([1, 2, 3])))
        let backendPublicKeys = BackendMLSPublicKeys(removal: .init(ed25519: .init([4, 5, 6])))

        mockActionsProvider.fetchBackendPublicKeysIn_MockMethod = { _ in
            backendPublicKeys
        }
        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in }

        // When
        _ = try await sut.createGroup(for: groupID, removalKeys: removalKeys)

        // Then
        let invocation = mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_Invocations
            .first
        XCTAssertEqual(
            invocation?.config.externalSenders,
            removalKeys.externalSenderKey(for: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )
        XCTAssertEqual(mockStaleMLSKeyDetector.keyingMaterialUpdatedFor_Invocations, [groupID])
    }

    // MARK: - Establish group

    func test_EstablishGroupWithNoUsers_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let removalKey = Data([1, 2, 3])
        let expectedConfig = ConversationConfiguration(
            ciphersuite: defaultCipherSuite.coreCryptoCipherSuite,
            externalSenders: [ExternalSenderKey(bytes: removalKey)],
            custom: .init(keyRotationSpan: nil, wirePolicy: nil)
        )

        mockActionsProvider.fetchBackendPublicKeysIn_MockValue = .init(
            removal: .init(ed25519: removalKey)
        )
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in }

        var mockCreateConversationCount = 0
        mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_MockMethod =
            { conversationID, creatorCredentialType, config in
                mockCreateConversationCount += 1

                XCTAssertEqual(conversationID, groupID.conversationId)
                XCTAssertEqual(creatorCredentialType, .basic)
                XCTAssertEqual(config, expectedConfig)
            }

        // When
        try await _ = sut.establishGroup(for: groupID, with: [])

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.keyingMaterialUpdatedFor_Invocations, [groupID])
    }

    func test_EstablishGroupWithMultipleUsers_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let removalKey = Data([1, 2, 3])
        let users = [
            MLSUser(id: UUID(), domain: "example.com"),
            MLSUser(id: UUID(), domain: "example.com")
        ]
        let expectedConfig = ConversationConfiguration(
            ciphersuite: defaultCipherSuite.coreCryptoCipherSuite,
            externalSenders: [ExternalSenderKey(bytes: removalKey)],
            custom: .init(keyRotationSpan: nil, wirePolicy: nil)
        )

        mockActionsProvider.fetchBackendPublicKeysIn_MockValue = .init(
            removal: .init(ed25519: removalKey)
        )

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in }

        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { _, _, _, _, _ in
                users.map {
                    KeyPackage(
                        client: .randomAlphanumerical(length: 4),
                        domain: $0.domain,
                        keyPackage: .randomAlphanumerical(length: 3),
                        keyPackageRef: .randomAlphanumerical(length: 6),
                        userID: $0.id
                    )
                }
            }
        var mockAddMembersCalled = false
        mockMLSActionExecutor.mockAddMembers = { _, _ in
            mockAddMembersCalled = true
        }

        var mockCreateConversationCount = 0
        mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_MockMethod =
            { conversationID, creatorCredentialType, config in
                mockCreateConversationCount += 1

                XCTAssertEqual(conversationID, groupID.conversationId)
                XCTAssertEqual(creatorCredentialType, .basic)
                XCTAssertEqual(config, expectedConfig)
            }

        // When
        try await _ = sut.establishGroup(for: groupID, with: users)

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.keyingMaterialUpdatedFor_Invocations, [groupID])
        XCTAssertEqual(mockMLSActionExecutor.updateKeyMaterialCount, 0)
        XCTAssertTrue(mockAddMembersCalled)
    }

    private func internalTestReEstablishGroup(epoch: UInt64) async throws {
        // GIVEN
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let conversation = await uiMOC.perform {
            let conversation = self.createConversation(
                outOfSync: false,
                currentEpoch: epoch,
                groupID: groupID
            ).conversation
            conversation.mlsStatus = .pendingJoinAfterReset
            return conversation
        }

        let mlsSelfUser = await uiMOC.perform {
            MLSUser(from: self.selfUser, localDomain: self.localDomain)
        }
        let groupInfo = Data()
        mockActionsProvider
            .fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockMethod = { _, _, _, _ in
                groupInfo
            }
        mockMLSActionExecutor.mockJoinGroup = { mlsGroupID, mlsGroupInfo in
            XCTAssertEqual(mlsGroupID, groupID)
            XCTAssertEqual(mlsGroupInfo, groupInfo)
        }
        mockMLSActionExecutor.mockCommitPendingProposals = { mlsGroupID in
            XCTAssertEqual(mlsGroupID, groupID)
        }
        mockMLSActionExecutor.mockUpdateKeyMaterial = { mlsGroupID in
            XCTAssertEqual(mlsGroupID, groupID)
        }

        mockActionsProvider.syncConversationQualifiedIDContext_MockMethod = { _, _ in }

        // WHEN
        try await sut.reEstablishPendingGroup(groupID: groupID)

        // THEN
        try XCTAssertCount(mockActionsProvider.syncConversationQualifiedIDContext_Invocations, count: 1)
        await uiMOC.perform {
            XCTAssertEqual(conversation.mlsStatus, .ready)
        }
    }

    func test_reEstablishGroup_joinViaExternalCommit() async throws {
        // GIVEN
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = true

        // WHEN
        try await internalTestReEstablishGroup(epoch: 1)

        // THEN
        try XCTAssertCount(
            mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations,
            count: 1
        )
        XCTAssertEqual(mockMLSActionExecutor.mockAddMembersCount, 0)
        XCTAssertEqual(mockMLSActionExecutor.mockJoinGroupCount, 1)
    }

    func test_reEstablishGroup_establishGroup() async throws {
        // GIVEN
        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in }
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = false
        mockActionsProvider.claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue = [KeyPackage(
            client: "123e",
            domain: "qwer",
            keyPackage: "qwer",
            keyPackageRef: "asdf",
            userID: UUID()
        )]
        mockMLSActionExecutor.mockAddMembers = { _, _ in }

        // WHEN
        try await internalTestReEstablishGroup(epoch: 0)

        // THEN
        XCTAssertEqual(mockMLSActionExecutor.mockAddMembersCount, 1)
        XCTAssertEqual(mockMLSActionExecutor.mockJoinGroupCount, 0)
    }

    func test_EstablishGroup_WipesGroupOnError() async throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let removalKey = Data([1, 2, 3])
        let mlsSelfUser = await uiMOC.perform {
            MLSUser(from: self.selfUser, localDomain: self.localDomain)
        }
        let users = [
            MLSUser(id: UUID(), domain: "example.com"),
            MLSUser(id: UUID(), domain: "example.com")
        ]
        let usersIncludingSelf = users + [mlsSelfUser]
        let expectedConfig = ConversationConfiguration(
            ciphersuite: defaultCipherSuite.coreCryptoCipherSuite,
            externalSenders: [ExternalSenderKey(bytes: removalKey)],
            custom: .init(keyRotationSpan: nil, wirePolicy: nil)
        )

        mockActionsProvider.fetchBackendPublicKeysIn_MockValue = .init(
            removal: .init(ed25519: removalKey)
        )

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockError = ClaimMLSKeyPackageAction.Failure
            .emptyKeyPackages

        var mockCreateConversationCount = 0
        mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_MockMethod =
            { conversationID, creatorCredentialType, config in
                mockCreateConversationCount += 1

                XCTAssertEqual(conversationID, groupID.conversationId)
                XCTAssertEqual(creatorCredentialType, .basic)
                XCTAssertEqual(config, expectedConfig)
            }
        mockCoreCryptoContext.wipeConversationConversationId_MockMethod = { _ in }
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = true

        // When

        do {
            try await _ = sut.establishGroup(for: groupID, with: users)
        } catch {
            if case let MLSService.MLSAddMembersError.failedToClaimKeyPackages(users) = error {
                XCTAssertEqual(Set(usersIncludingSelf), Set(users))
            } else {
                XCTFail("unexepected error  \(error)")
            }
        }

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
        XCTAssertEqual(mockCoreCryptoContext.wipeConversationConversationId_Invocations.count, 1)
    }

    // MARK: - Adding participants

    func test_AddingMembersToConversation_Successfully() async throws {
        // Given
        let id = UUID.create()
        let domain = "example.com"
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser = [MLSUser(id: id, domain: domain)]

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock claiming a key package.
        var keyPackage: WireDataModel.KeyPackage!
        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { userID, _, _, _, _ in
                keyPackage = self.createKeyPackage(userID: userID, domain: domain)
                return [keyPackage]
            }

        // Mock adding members to the conversation.
        var mockAddMembersArguments = [([WireDataModel.KeyPackage], MLSGroupID)]()

        mockMLSActionExecutor.mockAddMembers = {
            mockAddMembersArguments.append(($0, $1))
        }

        // When
        try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)

        // Then we added the members.
        XCTAssertEqual(mockAddMembersArguments.count, 1)
        XCTAssertEqual(mockAddMembersArguments.first?.0, [keyPackage])
        XCTAssertEqual(mockAddMembersArguments.first?.1, mlsGroupID)
    }

    func test_ClaimKeyPackagesWithCorrectCipherSuite_BeforeAddingMembersToConversation_Successfully() async throws {
        // Given
        let id = UUID.create()
        let domain = "example.com"
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser = [MLSUser(id: id, domain: domain)]

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock claiming a key package.
        var keyPackage: WireDataModel.KeyPackage!
        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { userID, _, _, _, _ in
                keyPackage = self.createKeyPackage(userID: userID, domain: domain)
                return [keyPackage]
            }

        // Mock adding members to the conversation.
        var mockAddMembersArguments = [([WireDataModel.KeyPackage], MLSGroupID)]()

        mockMLSActionExecutor.mockAddMembers = {
            mockAddMembersArguments.append(($0, $1))
        }

        // When
        try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)

        // Then
        let claimKeyPackagesInvocation = mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_Invocations.first
        XCTAssertEqual(claimKeyPackagesInvocation?.ciphersuite.rawValue, defaultCipherSuite.rawValue)
    }

    func test_CommitPendingProposals_BeforeAddingMembersToConversation_Successfully() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!
        let futureCommitDate = Date().addingTimeInterval(2)

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = futureCommitDate
        }

        // Mock commiting a pending proposal
        var mockCommitPendingProposalsArgument = [MLSGroupID]()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalsArgument.append($0)
        }

        // The user to add.
        let domain = "example.com"
        let id = UUID.create()
        let mlsUser = [MLSUser(id: id, domain: domain)]

        // Mock claiming a key package.
        var keyPackage: WireDataModel.KeyPackage!
        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { userID, _, _, _, _ in
                keyPackage = self.createKeyPackage(userID: userID, domain: domain)
                return [keyPackage]
            }

        // Mock adding members to the conversation.
        var mockAddMembersArguments = [([WireDataModel.KeyPackage], MLSGroupID)]()

        mockMLSActionExecutor.mockAddMembers = {
            mockAddMembersArguments.append(($0, $1))
        }

        // When
        try await sut.addMembersToConversation(with: mlsUser, for: groupID)

        // Then we committed pending proposals.
        XCTAssertEqual(mockCommitPendingProposalsArgument, [groupID])

        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }

        // Then we added the members.
        XCTAssertEqual(mockAddMembersArguments.count, 1)
        XCTAssertEqual(mockAddMembersArguments.first?.0, [keyPackage])
        XCTAssertEqual(mockAddMembersArguments.first?.1, groupID)
    }

    func test_AddingMembersToConversation_ThrowsNoParticipantsToAdd() async {
        // Given
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // when / then
        await assertItThrows(error: MLSService.MLSAddMembersError.noMembersToAdd) {
            try await sut.addMembersToConversation(with: [], for: mlsGroupID)
        }
    }

    func test_AddingMembersToConversation_ThrowsFailedToClaimKeyPackages() async {
        // Given
        let userID1 = UUID.create()
        let domain = "example.com"
        let user1 = MLSUser(id: userID1, domain: domain)
        let user2 = MLSUser(id: .create(), domain: domain)
        let user3 = MLSUser(id: .create(), domain: domain)
        let keyPackage = createKeyPackage(userID: userID1, domain: domain)
        let groupID = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock claiming a key package. Works for user1, throws for user2 and user3
        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { userID, _, _, _, _ in
                if userID == userID1 {
                    return [keyPackage]
                } else {
                    throw ClaimMLSKeyPackageAction.Failure.emptyKeyPackages
                }
            }

        // Then
        await assertItThrows(error: MLSService.MLSAddMembersError.failedToClaimKeyPackages(users: [user2, user3])) {
            // When
            try await sut.addMembersToConversation(with: [user1, user2, user3], for: groupID)
        }
    }

    func test_AddingMembersToConversation_ExecutorFails() async {
        // Given
        let domain = "example.com"
        let id = UUID.create()
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser: [MLSUser] = [MLSUser(id: id, domain: domain)]

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock key package.
        var keyPackage: WireDataModel.KeyPackage!
        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { userID, _, _, _, _ in
                keyPackage = self.createKeyPackage(userID: userID, domain: domain)
                return [keyPackage]
            }

        mockMLSActionExecutor.mockAddMembers = { _, _ in
            throw CoreCryptoError.Mls(mlsError: .StaleCommit)
        }

        // when / then
        await assertItThrows(error: CoreCryptoError.Mls(mlsError: .StaleCommit)) {
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)
        }
    }

    // MARK: - Remove participants

    func test_RemoveMembersFromConversation_IsSuccessful() async throws {
        // Given
        let id = UUID.create().uuidString
        let domain = "example.com"
        let clientID = UUID.create().uuidString
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock removing clients from the group.
        var mockRemoveClientsArguments = [([ClientId], MLSGroupID)]()

        mockMLSActionExecutor.mockRemoveClients = {
            mockRemoveClientsArguments.append(($0, $1))
        }

        // When
        try await sut.removeMembersFromConversation(with: [mlsClientID], for: mlsGroupID)

        // Then we removed the clients.
        let clientIDData = try XCTUnwrap(mlsClientID.rawValue.data(using: .utf8))
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, [ClientId(bytes: clientIDData)])
        XCTAssertEqual(mockRemoveClientsArguments.first?.1, mlsGroupID)
    }

    func test_CommitPendingProposals_BeforeRemoveMembersFromConversation_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!
        let futureCommitDate = Date().addingTimeInterval(2)

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = futureCommitDate
        }

        // Mock commiting a pending proposal.
        var mockCommitPendingProposalsArgument = [MLSGroupID]()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalsArgument.append($0)
        }

        // The user to remove.
        let id = UUID.create().uuidString
        let domain = "example.com"
        let clientID = UUID.create().uuidString
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock removing clients from the group.
        var mockRemoveClientsArguments = [([ClientId], MLSGroupID)]()

        mockMLSActionExecutor.mockRemoveClients = {
            mockRemoveClientsArguments.append(($0, $1))
        }

        // When
        try await sut.removeMembersFromConversation(with: [mlsClientID], for: groupID)

        // Then we committed pending proposals.
        XCTAssertEqual(mockCommitPendingProposalsArgument, [groupID])

        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }

        // Then we removed the clients.
        let clientIDData = try XCTUnwrap(mlsClientID.rawValue.data(using: .utf8))
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, [ClientId(bytes: clientIDData)])
        XCTAssertEqual(mockRemoveClientsArguments.first?.1, groupID)
    }

    func test_RemovingMembersToConversation_ThrowsNoClientsToRemove() async {
        // Given
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // When / Then
        await assertItThrows(error: MLSService.MLSRemoveParticipantsError.noClientsToRemove) {
            try await sut.removeMembersFromConversation(with: [], for: mlsGroupID)
        }
    }

    func test_RemovingMembersToConversation_ExecutorFails() async {
        // Given
        let id = UUID.create().uuidString
        let domain = "example.com"
        let clientID = UUID.create().uuidString
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock executor error.
        mockMLSActionExecutor.mockRemoveClients = { _, _ in
            throw CoreCryptoError.Mls(mlsError: .StaleCommit)
        }

        // When / Then
        await assertItThrows(error: CoreCryptoError.Mls(mlsError: .StaleCommit)) {
            try await sut.removeMembersFromConversation(with: [mlsClientID], for: mlsGroupID)
        }
    }

    // MARK: - Joining conversations

    func test_PerformPendingJoins_It_Establishes_Group_SelfConversation() async throws {
        try await assert_PerformPendingJoins_It_Establishes_Group(
            conversationType: .`self`,
            file: #file,
            line: #line
        )
    }

    func test_PerformPendingJoins_It_Establishes_Group_OneOnOne() async throws {
        try await assert_PerformPendingJoins_It_Establishes_Group(
            conversationType: .oneOnOne,
            file: #file,
            line: #line
        )
    }

    func test_PerformPendingJoins_It_Establishes_Group_Group() async throws {
        try await assert_PerformPendingJoins_It_Establishes_Group(
            conversationType: .group,
            file: #file,
            line: #line
        )
    }

    func assert_PerformPendingJoins_It_Establishes_Group(
        conversationType: ZMConversationType,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // Given
        let groupID = MLSGroupID.random()
        let conversationID = UUID.create()
        let domain = "example.domain.com"
        let conversation = await uiMOC.perform { [uiMOC] in
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.remoteIdentifier = conversationID
            conversation.domain = domain
            conversation.mlsGroupID = groupID
            conversation.messageProtocol = .mls
            conversation.mlsStatus = .pendingJoin
            conversation.conversationType = conversationType

            // Only epoch 0 leads to establishing group
            conversation.epoch = 0

            return conversation
        }

        // mock MLS action executor
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in }

        // mock CC
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = false
        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in }

        // When
        try await sut.performPendingJoins()

        // Then

        // it creates CC conversation
        let createCoreCryptoConversationInvocations = mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_Invocations
        XCTAssertEqual(createCoreCryptoConversationInvocations.count, 1, file: file, line: line)

        // it commits pending proposals
        XCTAssertEqual(mockMLSActionExecutor.commitPendingProposalsCount, 1, file: file, line: line)

        // it updates key material
        XCTAssertEqual(mockMLSActionExecutor.updateKeyMaterialCount, 1, file: file, line: line)

        // it sets conversation state to ready
        let conversationMLSStatus = await uiMOC.perform { conversation.mlsStatus }
        XCTAssertEqual(conversationMLSStatus, .ready, file: file, line: line)
    }

    func test_PerformPendingJoins_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let conversationID = UUID.create()
        let domain = "example.domain.com"
        let publicGroupState = Data()
        let conversation = await uiMOC.perform { [uiMOC] in
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.remoteIdentifier = conversationID
            conversation.domain = domain
            conversation.mlsGroupID = groupID
            conversation.mlsStatus = .pendingJoin
            conversation.messageProtocol = .mls
            return conversation
        }

        // mock fetching group info
        mockActionsProvider
            .fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = publicGroupState

        // mock joining group
        var joinGroupArguments = [(groupID: MLSGroupID, groupState: Data)]()
        mockMLSActionExecutor.mockJoinGroup = {
            joinGroupArguments.append(($0, $1))
        }

        // mock CC conversation exists
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = true

        // When
        try await sut.performPendingJoins()

        // Then

        // it fetches public group state
        let groupStateInvocations = mockActionsProvider
            .fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations
        XCTAssertEqual(groupStateInvocations.count, 1)
        XCTAssertEqual(groupStateInvocations.first?.conversationId, conversationID)
        XCTAssertEqual(groupStateInvocations.first?.domain, domain)

        // it asks executor to join group
        XCTAssertEqual(joinGroupArguments.count, 1)
        XCTAssertEqual(joinGroupArguments.first?.groupID, groupID)
        XCTAssertEqual(joinGroupArguments.first?.groupState, publicGroupState)

        // it sets conversation state to ready
        let conversationMLSStatus = await uiMOC.perform { conversation.mlsStatus }
        XCTAssertEqual(conversationMLSStatus, .ready)
    }

    func test_PerformPendingJoins_Retries() async throws {
        try await test_PerformPendingJoinsRecovery(MLSAPIError.mlsClientMismatch, shouldRetry: true)
    }

    func test_PerformPendingJoins_GivesUp() async throws {
        try await test_PerformPendingJoinsRecovery(MLSAPIError.mlsNotEnabled, shouldRetry: false)
    }

    private func test_PerformPendingJoinsRecovery(
        _ error: MLSAPIError,
        shouldRetry: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        // Given
        let groupID = MLSGroupID.random()
        let conversationID = UUID.create()
        let domain = "example.domain.com"
        let groupInfo = Data()
        let conversation = await uiMOC.perform { [uiMOC] in
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.remoteIdentifier = conversationID
            conversation.domain = domain
            conversation.mlsGroupID = groupID
            conversation.mlsStatus = .pendingJoin
            conversation.messageProtocol = .mls
            return conversation
        }

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = groupInfo

        // mock joining group
        var joinGroupCount = 0
        mockMLSActionExecutor.mockJoinGroup = { _, _ in
            joinGroupCount += 1

            if joinGroupCount == 1 {
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(reason: try error.encodeAsString()))
            }
        }

        // mock CC conversation exists
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = true

        // When
        try await sut.performPendingJoins()

        // Then

        // it fetches group info
        let groupInfoInvocations = mockActionsProvider
            .fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations
        XCTAssertEqual(groupInfoInvocations.count, shouldRetry ? 2 : 1, file: file, line: line)

        // it asks executor to join group
        XCTAssertEqual(joinGroupCount, shouldRetry ? 2 : 1, file: file, line: line)

        // it sets conversation state to ready
        let conversationMLSStatus = await uiMOC.perform { conversation.mlsStatus }
        XCTAssertEqual(conversationMLSStatus, shouldRetry ? .ready : .pendingJoin, file: file, line: line)
    }

    func test_PerformPendingJoins_DoesntJoinGroupNotPending() async throws {
        // Given
        let groupID = MLSGroupID.random()
        await uiMOC.perform { [uiMOC] in
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.remoteIdentifier = UUID.create()
            conversation.domain = "domain.com"
            conversation.mlsStatus = .ready
        }

        // expectation
        let expectation = XCTestExpectation(description: "Send Message")
        expectation.isInverted = true

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()

        // mock joining group
        mockMLSActionExecutor.mockJoinGroup = { _, _ in
            expectation.fulfill()
        }

        // When
        try await sut.performPendingJoins()

        // Then
        await fulfillment(of: [expectation], timeout: 1)

        let groupInfoInvocations = mockActionsProvider
            .fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations
        XCTAssertEqual(groupInfoInvocations.count, 0)
    }

    // MARK: - Handling out of sync conversations

    func test_RepairOutOfSyncConversations_RejoinsOutOfSyncConversations() async throws {
        // GIVEN
        let outOfSyncGroupID1 = MLSGroupID.random()
        let outOfSyncGroupID2 = MLSGroupID.random()
        let inSyncGroupID3 = MLSGroupID.random()
        let currentEpoch: UInt64 = 1

        _ = await uiMOC.perform { [self] in
            [
                createConversation(outOfSync: true, currentEpoch: currentEpoch, groupID: outOfSyncGroupID1),
                createConversation(outOfSync: true, currentEpoch: currentEpoch, groupID: outOfSyncGroupID2),
                createConversation(outOfSync: false, currentEpoch: currentEpoch, groupID: inSyncGroupID3)
            ]
        }

        await uiMOC.perform {
            // mock conversation epoch
            self.mockCoreCryptoContext.conversationEpochConversationId_MockMethod = { groupID in
                let isOutOfSync = (groupID == outOfSyncGroupID1.conversationId) ||
                    (groupID == outOfSyncGroupID2.conversationId)

                return isOutOfSync ? currentEpoch - 1 : currentEpoch
            }
        }

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()

        // mock joining group
        await uiMOC.perform { [self] in
            mockMLSActionExecutor.mockJoinGroup = { groupID, _ in
                XCTAssert(groupID.data.isOne(of: outOfSyncGroupID1.data, outOfSyncGroupID2.data))
                XCTAssertNotEqual(groupID.data, inSyncGroupID3.data)
            }
        }

        // WHEN
        try await sut.repairOutOfSyncConversations()

        // THEN, 2 out-of-sync conversations were repaired
        XCTAssertEqual(mockMLSActionExecutor.mockJoinGroupCount, 2)
    }

    func test_FetchAndRepairConversation_RejoinsOutOfSyncConversation() async throws {
        // GIVEN
        let conversation = await uiMOC.perform { self.createConversation(outOfSync: true).conversation }
        guard let groupID = await uiMOC.perform({ conversation.mlsGroupID }) else {
            XCTFail("missing groupID")
            return
        }

        let expectation = XCTestExpectation(description: "rejoined conversation")

        await uiMOC.perform { [self] in
            setMocksForConversationRepair(
                parentGroupID: groupID,
                epoch: conversation.epoch - 1,
                onJoinGroup: { joinedGroupID in
                    XCTAssertEqual(groupID, joinedGroupID)
                    expectation.fulfill()
                }
            )
        }
        // WHEN
        await sut.fetchAndRepairGroup(with: groupID)

        // THEN
        // Verify expectation that the conversation was rejoined
        await fulfillment(of: [expectation], timeout: 1)
        // Wait for groups that need the current context before its deallocated
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_FetchAndRepairConversation_DoesNothingIfConversationIsNotOutOfSync() async throws {
        // GIVEN
        let conversation = await uiMOC.perform { self.createConversation(outOfSync: true).conversation }
        guard let groupID = await uiMOC.perform({ conversation.mlsGroupID }) else {
            XCTFail("missing groupID")
            return
        }

        let expectation = XCTestExpectation(description: "didn't rejoin conversation")
        expectation.isInverted = true

        await uiMOC.perform { [self] in
            setMocksForConversationRepair(
                parentGroupID: groupID,
                epoch: conversation.epoch,
                onJoinGroup: { _ in
                    expectation.fulfill()
                }
            )
        }
        // WHEN
        await sut.fetchAndRepairGroup(with: groupID)

        // THEN
        // Verify expectation that the conversation was NOT rejoined
        await fulfillment(of: [expectation], timeout: 1)
    }

    func test_FetchAndRepairConversation_RejoinsOutOfSyncSubgroup() async throws {
        // GIVEN
        let conversation = await uiMOC.perform { self.createConversation(outOfSync: true).conversation }
        guard let groupID = await uiMOC.perform({ conversation.mlsGroupID }) else {
            XCTFail("missing groupID")
            return
        }
        let subgroupID = MLSGroupID.random()
        let qualifiedID = await uiMOC.perform { conversation.qualifiedID }

        let subgroup = MLSSubgroup(
            cipherSuite: 0,
            epoch: 1,
            epochTimestamp: Date(),
            groupID: subgroupID,
            members: [],
            parentQualifiedID: try XCTUnwrap(qualifiedID)
        )

        let expectation = XCTestExpectation(description: "rejoined subgroup")
        await uiMOC.perform {
            self.setMocksForConversationRepair(
                parentGroupID: groupID,
                epoch: UInt64(subgroup.epoch - 1),
                subgroup: subgroup,
                onJoinGroup: { joinedGroupID in
                    XCTAssertEqual(subgroupID, joinedGroupID)
                    expectation.fulfill()
                }
            )
        }

        // WHEN
        await sut.fetchAndRepairGroup(with: groupID)

        // THEN
        // Verify expectation that the subgroup was rejoined
        await fulfillment(of: [expectation], timeout: 1)
    }

    func test_FetchAndRepairConversation_DoesNothingIfSubgroupIsNotOutOfSync() async throws {
        // GIVEN
        let conversation = await uiMOC.perform { self.createConversation(outOfSync: true).conversation }
        guard let groupID = await uiMOC.perform({ conversation.mlsGroupID }) else {
            XCTFail("missing groupID")
            return
        }
        let subgroupID = MLSGroupID.random()
        let qualifiedID = await uiMOC.perform { conversation.qualifiedID }

        let subgroup = MLSSubgroup(
            cipherSuite: 0,
            epoch: 1,
            epochTimestamp: Date(),
            groupID: subgroupID,
            members: [],
            parentQualifiedID: try XCTUnwrap(qualifiedID)
        )

        let expectation = XCTestExpectation(description: "didn't rejoin subgroup")
        expectation.isInverted = true

        await uiMOC.perform {
            self.setMocksForConversationRepair(
                parentGroupID: groupID,
                epoch: UInt64(subgroup.epoch),
                subgroup: subgroup,
                onJoinGroup: { _ in
                    expectation.fulfill()
                }
            )
        }

        // WHEN
        await sut.fetchAndRepairGroup(with: groupID)

        // THEN
        // Verify expectation that the subgroup was NOT rejoined
        await fulfillment(of: [expectation], timeout: 1)
    }

    private func setMocksForConversationRepair(
        parentGroupID: MLSGroupID,
        epoch: UInt64,
        subgroup: MLSSubgroup? = nil,
        onJoinGroup: @escaping (MLSGroupID) -> Void
    ) {
        // mock conversation epoch
        mockCoreCryptoContext.conversationEpochConversationId_MockMethod = { _ in
            epoch
        }

        if let subgroup {
            // mock fetching subgroup
            mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockValue = subgroup
            // mock finding parent of subgroup on subconversation repository
            mockSubconversationGroupIDRepository.findSubgroupTypeAndParentIDFor_MockValue = (parentGroupID, .conference)
        } else {
            // mock conversation sync
            mockActionsProvider.syncConversationQualifiedIDContext_MockMethod = { _, _ in
                // do nothing
            }
            // mock finding parent of subgroup on subconversation repository
            mockSubconversationGroupIDRepository.findSubgroupTypeAndParentIDFor_MockValue = .some(nil)
        }

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()

        // mock join group
        mockMLSActionExecutor.mockJoinGroup = { groupID, _ in
            onJoinGroup(groupID)
        }
    }

    private typealias ConversationAndOutOfSyncTuple = (conversation: ZMConversation, isOutOfSync: Bool)

    private func createConversation(
        outOfSync: Bool,
        currentEpoch: UInt64 = 1,
        groupID: MLSGroupID = .random()
    ) -> ConversationAndOutOfSyncTuple {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mlsGroupID = groupID
        conversation.remoteIdentifier = UUID()
        conversation.domain = "domain.com"
        conversation.messageProtocol = .mls
        conversation.epoch = currentEpoch

        return (conversation, outOfSync)
    }

    // MARK: - Wipe Groups

    func test_WipeGroup_IsSuccessfull() async throws {
        // Given
        let groupID = MLSGroupID.random()

        var count = 0
        mockCoreCryptoContext.wipeConversationConversationId_MockMethod = { (id: ConversationId) in
            count += 1
            XCTAssertEqual(id, groupID.conversationId)
        }
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = true

        // When
        try await sut.wipeGroup(groupID)

        // Then
        XCTAssertEqual(count, 1)
    }

    func test_WipeGroup_CoreCryptoWipeConversationNotCalledIfConversationDoesNotExist() async throws {
        let groupID = MLSGroupID.random()

        mockCoreCryptoContext.conversationExistsConversationId_MockValue = false

        // When
        try await sut.wipeGroup(groupID)

        // Then
        XCTAssertEqual(mockCoreCryptoContext.wipeConversationConversationId_Invocations.count, 0)

    }

    // MARK: - Key Packages

    func test_UploadKeyPackages_IsSuccessful() async {
        // Given
        guard let clientID = await uiMOC.perform({ self.createSelfClient(onMOC: self.uiMOC).remoteIdentifier }) else {
            XCTFail("failed to get client id")
            return
        }

        let keyPackages: [WireCoreCryptoUniffi.KeyPackage] = [
            WireCoreCryptoUniffi.KeyPackage(bytes: Data.secureRandomData(length: 1)),
            WireCoreCryptoUniffi.KeyPackage(bytes: Data.secureRandomData(length: 1))
        ]

        // we need more than half the target number to have a sufficient amount
        let unsufficientKeyPackagesAmount = sut.targetUnclaimedKeyPackageCount / 3

        // expectation
        let countUnclaimedKeyPackages = customExpectation(description: "Count unclaimed key packages")
        let uploadKeyPackages = customExpectation(description: "Upload key packages")

        // mock that we queried kp count recently
        userDefaultsTestSuite.set(Date(), forKey: MLSService.Keys.keyPackageQueriedTime.rawValue)

        // mock that we don't have enough unclaimed kp locally
        mockCoreCryptoContext.clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod = { _, _ in
            UInt64(unsufficientKeyPackagesAmount)
        }

        // mock keyPackages returned by core cryto
        var mockClientKeypackagesCount = 0
        mockCoreCryptoContext
            .clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockMethod = { _, _, amountRequested in
                mockClientKeypackagesCount += 1
                XCTAssertEqual(amountRequested, UInt32(self.sut.targetUnclaimedKeyPackageCount))
                return keyPackages
            }

        // mock return value for unclaimed key packages count
        mockActionsProvider.countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockMethod = { _, _, _ in
            countUnclaimedKeyPackages.fulfill()
            return unsufficientKeyPackagesAmount
        }

        mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_MockMethod = { _, _, _ in
            uploadKeyPackages.fulfill()
        }

        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockClientKeypackagesCount, 1)

        let countUnclaimedKeypackagesInvocations = mockActionsProvider
            .countUnclaimedKeyPackagesClientIDCiphersuiteContext_Invocations
        XCTAssertEqual(countUnclaimedKeypackagesInvocations.count, 1)
        XCTAssertEqual(countUnclaimedKeypackagesInvocations.first?.clientID, clientID)

        let uploadKeypackagesInvocations = mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_Invocations
        XCTAssertEqual(uploadKeypackagesInvocations.count, 1)
        XCTAssertEqual(uploadKeypackagesInvocations.first?.clientID, clientID)
        XCTAssertEqual(
            uploadKeypackagesInvocations.first?.keyPackages,
            keyPackages.map { $0.copyBytes().base64EncodedString() }
        )
    }

    func test_UploadKeyPackages_DoesntCountUnclaimedKeyPackages_WhenNotNeeded() async {
        // Given
        await uiMOC.perform { _ = self.createSelfClient(onMOC: self.uiMOC) }

        // expectation
        let countUnclaimedKeyPackages = XCTestExpectation(description: "Count unclaimed key packages")
        countUnclaimedKeyPackages.isInverted = true

        // mock that we queried kp count recently
        privateUserDefaults.set(Date(), forKey: .keyPackageQueriedTime)

        // mock that there are enough kp locally
        mockCoreCryptoContext.clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod = { _, _ in
            UInt64(self.sut.targetUnclaimedKeyPackageCount)
        }

        mockActionsProvider.countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockMethod = { _, _, _ in
            countUnclaimedKeyPackages.fulfill()
            return 0
        }

        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        await fulfillment(of: [countUnclaimedKeyPackages], timeout: 1)
    }

    enum TestError: Error {
        case failedToCountUnclaimedKeyPackages
    }

    func test_CountUnclaimedKeyPackages_DoesNotSetKeyPackageQueriedTime_IfItFails() async {
        // Given
        await uiMOC.perform { _ = self.createSelfClient(onMOC: self.uiMOC) }

        // mock that there are enough kp locally
        mockCoreCryptoContext.clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod = { _, _ in
            UInt64(self.sut.targetUnclaimedKeyPackageCount)
        }

        mockActionsProvider.countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockMethod = { _, _, _ in
            throw TestError.failedToCountUnclaimedKeyPackages
        }

        mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_MockMethod = { _, _, _ in }
        mockCoreCryptoContext.clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockMethod = { _, _, _ in
            [WireCoreCryptoUniffi.KeyPackage(bytes: Data.random())]
        }
        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        XCTAssertNil(privateUserDefaults.date(forKey: .keyPackageQueriedTime))
    }

    func test_CountUnclaimedKeyPackages_SetsKeyPackageQueriedTime_IfItSucceed() async {
        // Given
        await uiMOC.perform { _ = self.createSelfClient(onMOC: self.uiMOC) }

        // mock that there are enough kp locally
        mockCoreCryptoContext.clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod = { _, _ in
            UInt64(self.sut.targetUnclaimedKeyPackageCount)
        }

        mockActionsProvider.countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockMethod = { _, _, _ in
            0
        }

        mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_MockMethod = { _, _, _ in }
        mockCoreCryptoContext.clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockMethod = { _, _, _ in
            [WireCoreCryptoUniffi.KeyPackage(bytes: Data.random())]
        }
        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        XCTAssertNotNil(privateUserDefaults.date(forKey: .keyPackageQueriedTime))
    }

    func test_UploadKeyPackages_DoesntUploadKeyPackages_WhenNotNeeded() async {
        // Given
        await uiMOC.perform { _ = self.createSelfClient(onMOC: self.uiMOC) }

        // we need more than half the target number to have a sufficient amount
        let unsufficientKeyPackagesAmount = sut.targetUnclaimedKeyPackageCount / 3

        // expectation
        let countUnclaimedKeyPackages = XCTestExpectation(description: "Count unclaimed key packages")
        let uploadKeyPackages = XCTestExpectation(description: "Upload key packages")
        uploadKeyPackages.isInverted = true

        // mock that we didn't query kp count recently
        privateUserDefaults.set(Date.distantPast, forKey: .keyPackageQueriedTime)

        // mock that we don't have enough unclaimed kp locally
        mockCoreCryptoContext.clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod = { _, _ in
            UInt64(unsufficientKeyPackagesAmount)
        }

        // mock return value for unclaimed key packages count
        mockActionsProvider.countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockMethod = { _, _, _ in
            countUnclaimedKeyPackages.fulfill()
            return self.sut.targetUnclaimedKeyPackageCount
        }

        mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_MockMethod = { _, _, _ in
            uploadKeyPackages.fulfill()
        }

        mockCoreCryptoContext.clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockMethod = { _, _, _ in
            XCTFail("shouldn't be generating key packages")
            return []
        }

        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        await fulfillment(of: [countUnclaimedKeyPackages, uploadKeyPackages], timeout: 1)
    }

    // MARK: - Update key material

    func test_UpdateKeyMaterial() async throws {
        // Given
        let group1 = MLSGroupID.random()
        let group2 = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock stale groups.
        mockStaleMLSKeyDetector.groupsWithStaleKeyingMaterial = [group1, group2]

        // Mock updating key material.
        var mockUpdateKeyingMaterialArguments = Set<MLSGroupID>()
        mockMLSActionExecutor.mockUpdateKeyMaterial = {
            mockUpdateKeyingMaterialArguments.insert($0)
        }

        // Expectations
        keyMaterialUpdatedExpectation = customExpectation(description: "did update key material")

        // When
        await sut.updateKeyMaterialForAllStaleGroupsIfNeeded()

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 5))

        // Then we updated the key material.
        XCTAssertEqual(
            mockUpdateKeyingMaterialArguments,
            [group1, group2]
        )

        // Then we informed the detector.
        XCTAssertEqual(
            Set(mockStaleMLSKeyDetector.keyingMaterialUpdatedFor_Invocations),
            Set([group1, group2])
        )

        // Then we updated the last check date.
        XCTAssertEqual(
            sut.lastKeyMaterialUpdateCheck.timeIntervalSinceNow,
            Date().timeIntervalSinceNow,
            accuracy: 0.1
        )

        // Then we scheduled a timer.
        let timer = try XCTUnwrap(sut.keyMaterialUpdateCheckTimer)
        XCTAssertTrue(timer.isValid)

        XCTAssertEqual(
            timer.fireDate.timeIntervalSinceNow,
            Date().addingTimeInterval(.oneDay).timeIntervalSinceNow,
            accuracy: 0.1
        )
    }

    // Note: these tests are asserting the behavior of the retry mechanism only, which
    // is used in various operations, such as adding members or removing clients. For
    // these tests, we will just pick one operation.

    func test_RetryOnCommitFailure_SingleRetry() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock one failure to update key material, then a success.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            switch mockUpdateKeyMaterialCount {
            case 0:
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                    reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
                ))
            default:
                return
            }
        }

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to update key material twice.
        XCTAssertEqual(mockUpdateKeyMaterialCount, 2)
    }

    func test_RetryOnCommitFailure_MultipleRetries() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock three failures to update key material, then a success.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            switch mockUpdateKeyMaterialCount {
            case 0 ..< 3:
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                    reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
                ))
            default:
                return
            }
        }

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to update key material 4 times (3 failed, 1 success).
        XCTAssertEqual(mockUpdateKeyMaterialCount, 4)
    }

    func test_RetryOnCommitFailure_Keep_Throwing_Commit_Error_Prevents_Infinite_Loop() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Since `retryOnCommitFailure` is a recursive function for specific error
        // `mlsClientMismatch`, we'll try to create an infinite loop by keep throwing the same error over and over
        // again.

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
            ))
        }

        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
            ))
        }

        do {
            // When
            try await sut.updateKeyMaterial(for: groupID)
        } catch is BackoffRetrier.Failure {
            // Then, infinite loop is broken after a few attempts, it throws an error
        } catch {
            XCTFail("failed with unexpected error: \(error)")
        }
    }

    func test_RetryOnCommitFailure_Keep_Throwing_External_Commit_Error_Prevents_Infinite_Loop() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Since `retryOnCommitFailure` is a recursive function for specific error
        // `mlsClientMismatch`, we'll try to create an infinite loop by keep throwing the same error over and over
        // again.

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
            ))
        }

        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
            ))
        }
        do {
            // When
            try await sut.updateKeyMaterial(for: groupID)
        } catch let error as BackoffRetrier.Failure {
            // Then, infinite loop is broken after a few attempts, it throws an error
        } catch {
            XCTFail("failed with unexpected error: \(error)")
        }
    }

    func test_RetryOnCommitFailure_ChainMultipleRecoverableOperations() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock two failures to commit pending proposals, then a success.
        var mockCommitPendingProposalsCount = 0
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            defer { mockCommitPendingProposalsCount += 1 }
            switch mockCommitPendingProposalsCount {
            case 0 ..< 2:
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                    reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
                ))
            default:
                return
            }
        }

        // Mock three failures to update key material, then a success.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            switch mockUpdateKeyMaterialCount {
            case 0 ..< 3:
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                    reason: try MLSAPIError.mlsClientMismatch.encodeAsString()
                ))
            default:
                return
            }
        }

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to commit pending proposals 3 times (2 failed, 1 success).
        XCTAssertEqual(mockCommitPendingProposalsCount, 3)

        // Then it attempted to update key material 4 times (3 failed, 1 success).
        XCTAssertEqual(mockUpdateKeyMaterialCount, 4)
    }

    func test_RetryOnCommitFailure_GroupOutOfSync() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let domain = "example.com"

        // Mock: commit failed due to missing users.
        let missingUsers: Set<WireDataModel.QualifiedID> = [
            .init(uuid: UUID(), domain: domain),
            .init(uuid: UUID(), domain: domain)
        ]
        var callCount = 0
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            defer { callCount += 1 }
            if callCount == 0 {
                // Fail on first call.
                let users = missingUsers.map {
                    WireNetwork.QualifiedID(id: $0.uuid, domain: $0.domain)
                }
                let error = MLSAPIError.groupOutOfSync(missingUsers: Set(users))
                let reason = try error.encodeAsString()
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(reason: reason))
            } else {
                // Success.
            }
        }

        // Mock: add users.
        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { userID, _, _, _, _ in
                [self.createKeyPackage(userID: userID, domain: domain)]
            }
        var addedUsers = [WireDataModel.QualifiedID]()
        var addedInGroupIDs: [MLSGroupID] = []
        mockMLSActionExecutor.mockAddMembers = { keyPackages, groupID in
            let ids = keyPackages.map {
                WireDataModel.QualifiedID(
                    uuid: $0.userID,
                    domain: $0.domain
                )
            }
            addedUsers.append(contentsOf: ids)
            addedInGroupIDs.append(groupID)
        }

        // When a commit is generated.
        try await sut.commitPendingProposals(in: groupID)

        // Then
        // 1 failed, 1 success.
        XCTAssertEqual(mockMLSActionExecutor.commitPendingProposalsCount, 2)
        // Added the missing users.
        XCTAssertEqual(addedInGroupIDs, [groupID])
        XCTAssertEqual(Set(addedUsers), missingUsers)
    }

    func test_RetryOnCommitFailure_CommitPendingProposalsAfterRetry() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        var mockCommitPendingProposalsCount = 0
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            defer { mockCommitPendingProposalsCount += 1 }
            switch mockCommitPendingProposalsCount {
            case 0:
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                    reason: try MLSAPIError.mlsCommitMissingReferences.encodeAsString()
                ))
            default:
                return
            }
        }

        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            mockUpdateKeyMaterialCount += 1
        }

        // Mock no subgroup
        mockSubconversationGroupIDRepository.findSubgroupTypeAndParentIDFor_MockMethod = { _ in
            nil
        }

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to commit pending proposals twice (1 no-op, 1 success).
        XCTAssertEqual(mockCommitPendingProposalsCount, 2)

        // Then it attempted to update key material once.
        XCTAssertEqual(mockUpdateKeyMaterialCount, 1)
    }

    func test_RetryOnCommitFailure_ItGivesUp() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()
        let unrecoverableError = MLSAPIError.mlsError("unrecoverable-error", "give up")

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        // Mock failures to update key material, no successes.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            throw CoreCryptoError.Mls(mlsError: .MessageRejected(
                reason: try unrecoverableError.encodeAsString()
            ))
        }

        // Then
        await assertItThrows(
            error: try MLSService.MLSRetryError
                .nonRecoverableError(unrecoverableError.encodeAsString())
        ) {
            // When
            try await sut.updateKeyMaterial(for: groupID)
        }

        // Then it attempted to update key material once.
        XCTAssertEqual(mockUpdateKeyMaterialCount, 1)
    }

    func test_UpdateKeyMaterial_ContinuesOnFailureForSomeGroups() async throws {
        // Given
        let group1 = MLSGroupID.random()
        let group2 = MLSGroupID.random()
        let group3 = MLSGroupID.random()

        mockStaleMLSKeyDetector.groupsWithStaleKeyingMaterial = [group1, group2, group3]

        var updatedGroups = [MLSGroupID]()
        mockMLSActionExecutor.mockUpdateKeyMaterial = { groupID in
            if groupID == group2 {
                // Given one of the group fails
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(reason: "mls stale mesage"))
            } else {
                updatedGroups.append(groupID)
            }
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        keyMaterialUpdatedExpectation = customExpectation(description: "did update key material")

        // When
        await sut.updateKeyMaterialForAllStaleGroupsIfNeeded()

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 5))

        // Check that group1 and group3 were successfully updated
        XCTAssertEqual(Set(updatedGroups), Set([group1, group3]))

        // Check that lastKeyMaterialUpdateCheck is updated
        XCTAssertEqual(
            sut.lastKeyMaterialUpdateCheck.timeIntervalSinceNow,
            Date().timeIntervalSinceNow,
            accuracy: 0.1
        )
    }

    // MARK: - Subgroups

    func test_CreateOrJoinSubgroup_CreateNewGroup() async throws {
        // Given
        let parentQualifiedID = QualifiedID.random()
        let parentID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()
        let epoch = 0
        let epochTimestamp = Date()
        let externalSender = ExternalSenderKey(bytes: Data.random())

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            MLSSubgroup(
                cipherSuite: 0,
                epoch: epoch,
                epochTimestamp: epochTimestamp,
                groupID: subgroupID,
                members: [],
                parentQualifiedID: parentQualifiedID
            )
        }

        mockCoreCryptoContext.getExternalSenderConversationId_MockMethod = { groupID in
            XCTAssertEqual(groupID, parentID.conversationId)
            return externalSender
        }

        mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { groupID, _, config in
                XCTAssertEqual(config.externalSenders, [externalSender])
                XCTAssertEqual(groupID, subgroupID.conversationId)
            }

        mockMLSActionExecutor.mockCommitPendingProposals = { groupID in
            XCTAssertEqual(groupID, subgroupID)
        }

        mockMLSActionExecutor.mockUpdateKeyMaterial = { groupID in
            XCTAssertEqual(groupID, subgroupID)
        }

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // When
        let result = try await sut.createOrJoinSubgroup(
            parentQualifiedID: parentQualifiedID,
            parentID: parentID
        )

        // Then
        XCTAssertEqual(result, subgroupID)

        XCTAssertEqual(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.count, 1)
        let fetchSubroupInvocation = try XCTUnwrap(
            mockActionsProvider
                .fetchSubgroupConversationIDDomainTypeContext_Invocations.first
        )
        XCTAssertEqual(fetchSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(fetchSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchSubroupInvocation.type, .conference)

        XCTAssertEqual(
            mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_Invocations.count,
            1
        )
        XCTAssertEqual(mockMLSActionExecutor.commitPendingProposalsCount, 1)
        XCTAssertEqual(mockMLSActionExecutor.updateKeyMaterialCount, 1)

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
        let subconversationGroupID = try XCTUnwrap(
            mockSubconversationGroupIDRepository
                .storeSubconversationGroupIDForTypeParentGroupID_Invocations.first
        )
        XCTAssertEqual(subconversationGroupID.groupID, subgroupID)
        XCTAssertEqual(subconversationGroupID.type, .conference)
        XCTAssertEqual(subconversationGroupID.parentGroupID, parentID)
    }

    func test_CreateOrJoinSubgroup_DeleteOldGroupCreateNewGroup() async throws {
        // Given
        let parentQualifiedID = QualifiedID.random()
        let parentID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()
        let epoch = 1
        let epochTimestamp = Date(timeIntervalSinceNow: -.oneDay)
        let externalSender = ExternalSenderKey(bytes: Data.random())

        mockActionsProvider
            .deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_MockMethod = { _, _, _, _, _, _ in
                // no-op
            }

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            MLSSubgroup(
                cipherSuite: 0,
                epoch: epoch,
                epochTimestamp: epochTimestamp,
                groupID: subgroupID,
                members: [],
                parentQualifiedID: parentQualifiedID
            )
        }

        mockCoreCryptoContext.getExternalSenderConversationId_MockMethod = { groupID in
            XCTAssertEqual(groupID, parentID.conversationId)
            return externalSender
        }

        mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { groupID, _, config in
                XCTAssertEqual(config.externalSenders, [externalSender])
                XCTAssertEqual(groupID, subgroupID.conversationId)
            }

        mockMLSActionExecutor.mockCommitPendingProposals = { groupID in
            XCTAssertEqual(groupID, subgroupID)
        }

        mockMLSActionExecutor.mockUpdateKeyMaterial = { groupID in
            XCTAssertEqual(groupID, subgroupID)
        }

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // When
        let result = try await sut.createOrJoinSubgroup(
            parentQualifiedID: parentQualifiedID,
            parentID: parentID
        )

        // Then
        XCTAssertEqual(result, subgroupID)

        XCTAssertEqual(
            mockActionsProvider.deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_Invocations.count,
            1
        )
        let deleteSubroupInvocation = try XCTUnwrap(
            mockActionsProvider
                .deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_Invocations.first
        )
        XCTAssertEqual(deleteSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(deleteSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(deleteSubroupInvocation.subgroupType, .conference)

        XCTAssertEqual(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.count, 1)
        let fetchSubroupInvocation = try XCTUnwrap(
            mockActionsProvider
                .fetchSubgroupConversationIDDomainTypeContext_Invocations.first
        )
        XCTAssertEqual(fetchSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(fetchSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchSubroupInvocation.type, .conference)

        XCTAssertEqual(
            mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_Invocations.count,
            1
        )
        XCTAssertEqual(mockMLSActionExecutor.commitPendingProposalsCount, 1)
        XCTAssertEqual(mockMLSActionExecutor.updateKeyMaterialCount, 1)

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
        let subconversationGroupID = try XCTUnwrap(
            mockSubconversationGroupIDRepository
                .storeSubconversationGroupIDForTypeParentGroupID_Invocations.first
        )
        XCTAssertEqual(subconversationGroupID.groupID, subgroupID)
        XCTAssertEqual(subconversationGroupID.type, .conference)
        XCTAssertEqual(subconversationGroupID.parentGroupID, parentID)
    }

    func test_CreateOrJoinSubgroup_JoinExistingGroup() async throws {
        // Given
        let parentQualifiedID = QualifiedID.random()
        let parentID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()
        let epoch = 1
        let epochTimestamp = Date()
        let publicGroupState = Data.random()

        await uiMOC.perform { [uiMOC] in
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.remoteIdentifier = parentQualifiedID.uuid
            conversation.domain = parentQualifiedID.domain
            conversation.mlsGroupID = parentID
        }

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            MLSSubgroup(
                cipherSuite: 0,
                epoch: epoch,
                epochTimestamp: epochTimestamp,
                groupID: subgroupID,
                members: [],
                parentQualifiedID: parentQualifiedID
            )
        }

        mockActionsProvider
            .fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = publicGroupState

        mockMLSActionExecutor.mockJoinGroup = {
            XCTAssertEqual($0, subgroupID)
            XCTAssertEqual($1, publicGroupState)
        }

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // When
        let result = try await sut.createOrJoinSubgroup(
            parentQualifiedID: parentQualifiedID,
            parentID: parentID
        )

        // Then
        XCTAssertEqual(result, subgroupID)

        XCTAssertEqual(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.count, 1)
        let fetchSubroupInvocation = try XCTUnwrap(
            mockActionsProvider
                .fetchSubgroupConversationIDDomainTypeContext_Invocations.first
        )
        XCTAssertEqual(fetchSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(fetchSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchSubroupInvocation.type, .conference)

        XCTAssertEqual(
            mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations.count,
            1
        )
        let fetchGroupInfoInvocation = try XCTUnwrap(
            mockActionsProvider
                .fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations.first
        )
        XCTAssertEqual(fetchGroupInfoInvocation.conversationId, parentQualifiedID.uuid)
        XCTAssertEqual(fetchGroupInfoInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchGroupInfoInvocation.subgroupType, .conference)

        XCTAssertEqual(mockMLSActionExecutor.mockJoinGroupCount, 1)

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
        let subconversationGroupID = try XCTUnwrap(
            mockSubconversationGroupIDRepository
                .storeSubconversationGroupIDForTypeParentGroupID_Invocations.first
        )
        XCTAssertEqual(subconversationGroupID.groupID, subgroupID)
        XCTAssertEqual(subconversationGroupID.type, .conference)
        XCTAssertEqual(subconversationGroupID.parentGroupID, parentID)
    }

    func test_LeaveSubconversation() async throws {
        // Given
        let parentID = QualifiedID.random()
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference

        mockActionsProvider
            .leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod = { _, _, _, _ in
                // no op
            }

        var mockWipeConversationArguments = [WireCoreCryptoUniffi.ConversationId]()
        mockCoreCryptoContext.wipeConversationConversationId_MockMethod = {
            mockWipeConversationArguments.append($0)
        }

        mockSubconversationGroupIDRepository
            .fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // When
        try await sut.leaveSubconversation(
            parentQualifiedID: parentID,
            parentGroupID: parentGroupID,
            subconversationType: subconversationType
        )

        // Then
        let leaveSubconversationInvocations = mockActionsProvider
            .leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations
        XCTAssertEqual(leaveSubconversationInvocations.count, 1)
        let leaveSubconversationInvocation = try XCTUnwrap(leaveSubconversationInvocations.first)
        XCTAssertEqual(leaveSubconversationInvocation.conversationID, parentID.uuid)
        XCTAssertEqual(leaveSubconversationInvocation.domain, parentID.domain)
        XCTAssertEqual(leaveSubconversationInvocation.subconversationType, subconversationType)

        XCTAssertEqual(mockWipeConversationArguments, [subconversationGroupID.conversationId])

        let clearSubconversationGroupIDInvocations = mockSubconversationGroupIDRepository
            .storeSubconversationGroupIDForTypeParentGroupID_Invocations
        XCTAssertEqual(clearSubconversationGroupIDInvocations.count, 1)
        let clearSubconversationGroupIDInvocation = try XCTUnwrap(clearSubconversationGroupIDInvocations.first)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.groupID, nil)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.type, .conference)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.parentGroupID, parentGroupID)
    }

    func test_LeaveSubconversationIfNeeded_GroupIDExists() async throws {
        // Given
        let parentID = QualifiedID.random()
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference
        let selfClientID = MLSClientID.random()

        mockSubconversationGroupIDRepository
            .fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID
        mockCoreCryptoContext.conversationExistsConversationId_MockMethod = {
            XCTAssertEqual($0, subconversationGroupID.conversationId)
            return true
        }

        mockActionsProvider
            .leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod = { _, _, _, _ in
                // no op
            }

        var mockWipeConversationArguments = [ConversationId]()
        mockCoreCryptoContext.wipeConversationConversationId_MockMethod = {
            mockWipeConversationArguments.append($0)
        }

        mockSubconversationGroupIDRepository
            .fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // When
        try await sut.leaveSubconversationIfNeeded(
            parentQualifiedID: parentID,
            parentGroupID: parentGroupID,
            subconversationType: subconversationType,
            selfClientID: selfClientID
        )

        // Then
        let invocations = mockActionsProvider
            .leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations
        XCTAssertEqual(invocations.count, 1)
        let invocation = try XCTUnwrap(invocations.first)
        XCTAssertEqual(invocation.conversationID, parentID.uuid)
        XCTAssertEqual(invocation.domain, parentID.domain)
        XCTAssertEqual(invocation.subconversationType, subconversationType)

        XCTAssertEqual(mockWipeConversationArguments, [subconversationGroupID.conversationId])

        let clearSubconversationGroupIDInvocations = mockSubconversationGroupIDRepository
            .storeSubconversationGroupIDForTypeParentGroupID_Invocations
        XCTAssertEqual(clearSubconversationGroupIDInvocations.count, 1)
        let clearSubconversationGroupIDInvocation = try XCTUnwrap(clearSubconversationGroupIDInvocations.first)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.groupID, nil)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.type, .conference)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.parentGroupID, parentGroupID)
    }

    func test_LeaveSubconversationIfNeeded_GroupIDDoesNotExist() async throws {
        // Given
        let parentID = QualifiedID.random()
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference
        let selfClientID = MLSClientID.random()

        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _ in
            nil
        }

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            MLSSubgroup(
                cipherSuite: 1,
                epoch: 1,
                epochTimestamp: nil,
                groupID: subconversationGroupID,
                members: [selfClientID],
                parentQualifiedID: parentID
            )
        }

        mockActionsProvider
            .leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod = { _, _, _, _ in
                // no op
            }

        var mockWipeConversationArguments = [ConversationId]()
        mockCoreCryptoContext.wipeConversationConversationId_MockMethod = {
            mockWipeConversationArguments.append($0)
        }

        mockSubconversationGroupIDRepository
            .fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // When
        try await sut.leaveSubconversationIfNeeded(
            parentQualifiedID: parentID,
            parentGroupID: parentGroupID,
            subconversationType: subconversationType,
            selfClientID: selfClientID
        )

        // Then
        let invocations = mockActionsProvider
            .leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations
        XCTAssertEqual(invocations.count, 1)
        let invocation = try XCTUnwrap(invocations.first)
        XCTAssertEqual(invocation.conversationID, parentID.uuid)
        XCTAssertEqual(invocation.domain, parentID.domain)
        XCTAssertEqual(invocation.subconversationType, subconversationType)

        XCTAssertEqual(mockWipeConversationArguments, [subconversationGroupID.conversationId])

        let clearSubconversationGroupIDInvocations = mockSubconversationGroupIDRepository
            .storeSubconversationGroupIDForTypeParentGroupID_Invocations
        XCTAssertEqual(clearSubconversationGroupIDInvocations.count, 1)
        let clearSubconversationGroupIDInvocation = try XCTUnwrap(clearSubconversationGroupIDInvocations.first)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.groupID, nil)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.type, .conference)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.parentGroupID, parentGroupID)
    }

    // MARK: - On conference info changed

    func test_OnConferenceInfoChanged_WhenEpochChangesForParentConversation() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()

        // When then
        try await assertConferenceInfoIsReceivedWhenEpochChanges(
            parentGroupID: parentGroupID,
            subconversationGroupID: subconversationGroupID,
            epochChangeSequence: .random(), .random(), parentGroupID
        )
    }

    func test_OnConferenceInfoChanged_WhenEpochChangesForSubconversation() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()

        // When then
        try await assertConferenceInfoIsReceivedWhenEpochChanges(
            parentGroupID: parentGroupID,
            subconversationGroupID: subconversationGroupID,
            epochChangeSequence: .random(), .random(), subconversationGroupID
        )
    }

    private func assertConferenceInfoIsReceivedWhenEpochChanges(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID,
        epochChangeSequence: MLSGroupID...
    ) async throws {
        // Mock conference info
        let epoch: UInt64 = 42
        let key = Data.random(byteCount: 32)
        let keyCC = SecretKey(bytes: key)
        let clientID = MLSClientID.random()
        let clientIDData = try XCTUnwrap(clientID.rawValue.utf8Data)

        mockCoreCryptoContext.conversationEpochConversationId_MockMethod = { groupID in
            XCTAssertEqual(groupID, subconversationGroupID.conversationId)
            return epoch
        }

        mockCoreCryptoContext.exportSecretKeyConversationIdKeyLength_MockMethod = { groupID, _ in
            XCTAssertEqual(groupID, subconversationGroupID.conversationId)
            return keyCC
        }

        mockCoreCryptoContext.getClientIdsConversationId_MockMethod = { groupID in
            XCTAssertTrue(groupID.isOne(of: parentGroupID.conversationId, subconversationGroupID.conversationId))
            return [ClientId(bytes: clientIDData)]
        }

        // Collect the received conference infos
        let conferenceInfoChanges = sut.onConferenceInfoChange(
            parentGroupID: parentGroupID,
            subConversationGroupID: subconversationGroupID
        )

        // When
        for groupID in epochChangeSequence {
            try await sut.epochChanged(conversationId: groupID.conversationId, epoch: epoch)
        }

        // Then
        let receivedConferenceInfo = try await conferenceInfoChanges.first(where: { _ in true })
        let expectedConferenceInfo = MLSConferenceInfo(
            epoch: epoch,
            keyData: key,
            members: [.init(id: clientID, isInSubconversation: true)]
        )

        XCTAssertEqual(receivedConferenceInfo, expectedConferenceInfo)
    }

    // MARK: - On new distribution points

    func test_OnNewDistributionPoints_InterleavesSources() throws {
        // Given
        let dp1 = try XCTUnwrap(CRLsDistributionPoints(from: ["acme.dp1.com"]))
        let dp2 = try XCTUnwrap(CRLsDistributionPoints(from: ["acme.dp2.com"]))
        let dp3 = try XCTUnwrap(CRLsDistributionPoints(from: ["acme.dp3.com"]))

        // Mock new distribution points
        let newDistributionPointsFromDecryptionService = PassthroughSubject<CRLsDistributionPoints, Never>()
        mockDecryptionService.onNewCRLsDistributionPoints_MockValue = newDistributionPointsFromDecryptionService
            .eraseToAnyPublisher()

        let newDistributionPointsFromActionExecutor = PassthroughSubject<CRLsDistributionPoints, Never>()
        mockMLSActionExecutor.mockOnNewCRLsDistributionPoints = newDistributionPointsFromActionExecutor
            .eraseToAnyPublisher

        // Collect sent values
        var receivedDPs = [CRLsDistributionPoints]()
        let expectation = XCTestExpectation(description: "received new distribution points")
        let cancellable = sut.onNewCRLsDistributionPoints().collect(3).sink {
            receivedDPs = $0
            expectation.fulfill()
        }

        // When
        newDistributionPointsFromDecryptionService.send(dp1)
        newDistributionPointsFromActionExecutor.send(dp2)
        newDistributionPointsFromDecryptionService.send(dp3)

        // Then
        wait(for: [expectation], timeout: 0.5)
        cancellable.cancel()
        XCTAssertEqual(receivedDPs, [dp1, dp2, dp3])
    }

    // MARK: - Self group

    func test_itCreatesSelfGroup_WithNoKeyPackages_Successfully() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()
        let expectation1 = customExpectation(description: "CreateConversation should be called")
        let expectation2 = customExpectation(description: "UpdateKeyMaterial should be called")

        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in
            expectation1.fulfill()
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in }

        mockActionsProvider.claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue = []

        var mockUpdateKeyingMaterialArguments = [MLSGroupID]()
        mockMLSActionExecutor.mockUpdateKeyMaterial = {
            defer { expectation2.fulfill() }
            mockUpdateKeyingMaterialArguments.append($0)
        }

        // WHEN
        _ = try await sut.createSelfGroup(for: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockUpdateKeyingMaterialArguments, [groupID])
    }

    func test_itCreatesSelfGroup_WithKeyPackages_Successfully() async throws {
        // Given a group.
        let expectation1 = customExpectation(description: "CreateConversation should be called")
        let expectation2 = customExpectation(description: "AddMembers should be called")
        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in
            expectation1.fulfill()
        }

        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod = { _, _, _, _, _ in
                [KeyPackage(client: "", domain: "", keyPackage: "", keyPackageRef: "", userID: UUID())]
            }

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in

        }

        mockMLSActionExecutor.mockAddMembers = { _, _ in
            expectation2.fulfill()
        }

        let groupID = MLSGroupID.random()

        // WHEN
        _ = try await sut.createSelfGroup(for: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 2.0))
    }

    func test_GenerateNewEpoch() async throws {
        // Given
        let groupID = MLSGroupID.random()

        var commitPendingProposalsInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            commitPendingProposalsInvocations.append($0)
        }

        var updateKeyMaterialInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockUpdateKeyMaterial = {
            updateKeyMaterialInvocations.append($0)
        }

        // When
        try await sut.generateNewEpoch(groupID: groupID)

        // Then
        XCTAssertEqual(commitPendingProposalsInvocations, [groupID])
        XCTAssertEqual(updateKeyMaterialInvocations, [groupID])
    }

    func test_GenerateNewEpochFailsWithResetMLSConversationError_FeatureON() async throws {
        // Given
        let groupID = MLSGroupID.random()

        var commitPendingProposalsInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            commitPendingProposalsInvocations.append($0)
        }

        let updateKeyMaterialInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            throw CoreCryptoError
                .Mls(mlsError: .MessageRejected(reason: try MLSAPIError.mlsInvalidLeafNodeSignature.encodeAsString()))
        }

        // When

        XCTAssertTrue(resetMLSConversationDelegate.didCatchBrokenMLSConversationGroupIDEpoch_Invocations.isEmpty)

        try await sut.generateNewEpoch(groupID: groupID)

        // Then
        XCTAssertEqual(commitPendingProposalsInvocations, [groupID])
        XCTAssertEqual(updateKeyMaterialInvocations, [])
        XCTAssertEqual(mockLegacyFeatureRepository.fetchAllowedGlobalOperations_Invocations.count, 1)
        XCTAssertEqual(resetMLSConversationDelegate.didCatchBrokenMLSConversationGroupIDEpoch_Invocations.count, 1)
        let invocation = try XCTUnwrap(
            resetMLSConversationDelegate
                .didCatchBrokenMLSConversationGroupIDEpoch_Invocations.first
        )
        XCTAssertEqual(invocation.groupID, groupID)
        XCTAssertEqual(invocation.epoch, 0)
    }

    func test_GenerateNewEpochFailsWithResetMLSConversationError_FeatureOff() async throws {
        // Given
        let groupID = MLSGroupID.random()

        mockLegacyFeatureRepository.fetchAllowedGlobalOperations_MockValue = Feature
            .AllowedGlobalOperations(
                status: .disabled,
                config: .init(mlsConversationReset: true)
            )

        var commitPendingProposalsInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            commitPendingProposalsInvocations.append($0)
        }

        let reason = try MLSAPIError.mlsInvalidLeafNodeIndex.encodeAsString()
        let updateKeyMaterialInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            throw CoreCryptoError
                .Mls(mlsError: .MessageRejected(reason: reason))
        }

        // When

        let delegate = MockResetBrokenMLSConversationDelegate()
        sut.setResetBrokenMLSConversationDelegate(delegate)
        XCTAssertTrue(delegate.didCatchBrokenMLSConversationGroupIDEpoch_Invocations.isEmpty)
        await XCTAssertThrowsErrorAsync(MLSService.MLSRetryError.nonRecoverableError(reason)) {
            try await self.sut.generateNewEpoch(groupID: groupID)
        }

        // Then
        XCTAssertEqual(commitPendingProposalsInvocations, [groupID])
        XCTAssertEqual(updateKeyMaterialInvocations, [])
        XCTAssertEqual(mockLegacyFeatureRepository.fetchAllowedGlobalOperations_Invocations.count, 1)
        XCTAssertTrue(delegate.didCatchBrokenMLSConversationGroupIDEpoch_Invocations.isEmpty)
    }

    // MARK: - Guest links

    func test_ItJoinsNewGroupForGuestLinkWhenConversationDoesNotExist() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.messageProtocol = .mls
            conversation.domain = "example.com"
        }

        let expectation1 = customExpectation(description: "CreateConversation should be called")

        mockMLSActionExecutor.mockJoinGroup = { _, _ in }
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()
        mockCoreCryptoContext.conversationExistsConversationId_MockMethod = { _ in
            false
        }
        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in
            expectation1.fulfill()
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { id in
            XCTAssertEqual(id, groupID)
        }

        mockActionsProvider.claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue = [.init(
            client: "123",
            domain: localDomain,
            keyPackage: "",
            keyPackageRef: "",
            userID: UUID()
        )]

        mockMLSActionExecutor.mockAddMembers = { _, id in
            XCTAssertEqual(id, groupID)
        }

        // WHEN
        try await sut.joinNewGroup(with: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItJoinsNewGroupForGuestLinkWhenConversationExists() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.messageProtocol = .mls
            conversation.domain = "example.com"
        }

        mockMLSActionExecutor.mockJoinGroup = { _, _ in }
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()
        mockCoreCryptoContext.conversationExistsConversationId_MockMethod = { _ in
            true
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { id in
            XCTAssertEqual(id, groupID)
        }

        mockActionsProvider.claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue = [.init(
            client: "123",
            domain: localDomain,
            keyPackage: "",
            keyPackageRef: "",
            userID: UUID()
        )]

        mockMLSActionExecutor.mockAddMembers = { _, id in
            XCTAssertEqual(id, groupID)
        }

        // WHEN
        _ = try await sut.joinNewGroup(with: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: - Proteus to MLS migration

    func test_startProteusToMLSMigration_succeeds() async throws {
        // Given
        let mlsGroupID = MLSGroupID.random()
        let conversation = await uiMOC.perform { [self] in
            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.teamIdentifier = .create()
            selfUser.domain = localDomain

            let conversation = createConversation(in: uiMOC, with: [selfUser])
            conversation.mlsGroupID = mlsGroupID
            conversation.messageProtocol = .proteus
            conversation.domain = localDomain
            conversation.teamRemoteIdentifier = selfUser.teamIdentifier
            return conversation
        }

        let updateConversationProtocolExpectation =
            XCTestExpectation(description: "updateConversationProtocol must be called")
        mockActionsProvider
            .updateConversationProtocolQualifiedIDMessageProtocolContext_MockMethod =
            { [uiMOC] qualifiedID, messageProtocol, notificationContext in
                XCTAssertEqual(qualifiedID, uiMOC.performAndWait { conversation.qualifiedID })
                XCTAssertEqual(messageProtocol, .mixed)
                XCTAssert(notificationContext === uiMOC.notificationContext)
                updateConversationProtocolExpectation.fulfill()
            }

        let syncConversationExpectation = XCTestExpectation(description: "updateLocalConversation must be called")
        mockActionsProvider.syncConversationQualifiedIDContext_MockMethod = { [uiMOC] qualifiedID, _ in
            XCTAssertEqual(qualifiedID, uiMOC.performAndWait { conversation.qualifiedID })
            syncConversationExpectation.fulfill()
        }

        let createConversationExpectation = XCTestExpectation(description: "createConversation must be called")
        mockCoreCryptoContext
            .createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { conversationID, _, _ in
                XCTAssertEqual(conversationID, mlsGroupID.conversationId)
                createConversationExpectation.fulfill()
            }

        let updateKeyMaterialExpectation = XCTestExpectation(description: "updateKeyMaterial must be called")
        mockMLSActionExecutor.mockUpdateKeyMaterial = { [self] mlsGroupID in
            XCTAssertEqual(mlsGroupID, uiMOC.performAndWait { conversation.mlsGroupID })
            updateKeyMaterialExpectation.fulfill()
        }

        let commitPendingProposalsExpectation = XCTestExpectation(description: "commitPendingProposals must be called")
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            commitPendingProposalsExpectation.fulfill()
        }

        // Mock claiming a key package.
        var keyPackage: WireDataModel.KeyPackage!
        mockActionsProvider
            .claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod =
            { [self] userID, domain, _, _, _ in
                keyPackage = createKeyPackage(userID: userID, domain: domain ?? localDomain)
                return [keyPackage]
            }

        // Mock adding members to the conversation.
        var addedMembers = [(keyPackages: [WireDataModel.KeyPackage], mlsGroupID: MLSGroupID)]()
        mockMLSActionExecutor.mockAddMembers = {
            addedMembers.append(($0, $1))
        }

        // When
        try await sut.startProteusToMLSMigration()

        // Then
        await fulfillment(
            of: [
                updateConversationProtocolExpectation,
                createConversationExpectation,
                updateKeyMaterialExpectation,
                commitPendingProposalsExpectation
            ],
            timeout: 0.5,
            enforceOrder: true
        )

        // members are added
        XCTAssertEqual(addedMembers.count, 1)
        XCTAssertEqual(addedMembers.first?.keyPackages, [keyPackage])
        XCTAssertEqual(addedMembers.first?.mlsGroupID, mlsGroupID)
    }

    func test_startProteusToMLSMigration_staleMessageErrorWipesGroup() async throws {
        // Given
        let mlsGroupID = MLSGroupID.random()
        await uiMOC.perform { [self] in
            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.teamIdentifier = .create()
            selfUser.domain = localDomain

            let conversation = createConversation(in: uiMOC, with: [selfUser])
            conversation.mlsGroupID = mlsGroupID
            conversation.messageProtocol = .proteus
            conversation.domain = localDomain
            conversation.teamRemoteIdentifier = selfUser.teamIdentifier
        }

        mockActionsProvider.updateConversationProtocolQualifiedIDMessageProtocolContext_MockMethod = { _, _, _ in }
        mockActionsProvider.syncConversationQualifiedIDContext_MockMethod = { _, _ in }

        mockCoreCryptoContext.createConversationConversationIdCreatorCredentialTypeConfig_MockMethod = { _, _, _ in }
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            throw SendMLSMessageFailure.mlsStaleMessage
        }
        let wipeConversationExpectation = XCTestExpectation(description: "wipeConversation must be called")
        mockCoreCryptoContext.wipeConversationConversationId_MockMethod = { conversationID in
            XCTAssertEqual(conversationID, mlsGroupID.conversationId)
            wipeConversationExpectation.fulfill()
        }
        mockCoreCryptoContext.conversationExistsConversationId_MockValue = true

        // When
        try await sut.startProteusToMLSMigration()

        // Then
        await fulfillment(
            of: [wipeConversationExpectation],
            timeout: 0.5,
            enforceOrder: true
        )
    }
}

extension ConversationConfiguration: @retroactive Equatable {
    public static func == (
        lhs: ConversationConfiguration,
        rhs: ConversationConfiguration
    ) -> Bool {
        lhs.ciphersuite == rhs.ciphersuite &&
            lhs.externalSenders == rhs.externalSenders &&
            lhs.custom == rhs.custom
    }
}

extension ExternalSenderKey: @retroactive Equatable {
    public static func == (lhs: ExternalSenderKey, rhs: ExternalSenderKey) -> Bool {
        lhs.copyBytes() == rhs.copyBytes()
    }
}

extension ClientId: @retroactive Equatable {
    public static func == (lhs: ClientId, rhs: ClientId) -> Bool {
        lhs.copyBytes() == rhs.copyBytes()
    }
}

private extension MLSAPIError {

    func encodeAsString() throws -> String {
        let error = MLSTransportError(self)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(error)
        return String(decoding: data, as: UTF8.self)
    }

}
