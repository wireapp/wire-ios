//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import Combine

// sourcery: AutoMockable
public protocol MLSServiceInterface: MLSEncryptionServiceInterface, MLSDecryptionServiceInterface {

    func uploadKeyPackagesIfNeeded() async

    func createSelfGroup(for groupID: MLSGroupID) async throws -> MLSCipherSuite

    func joinGroup(with groupID: MLSGroupID) async throws

    /// Join group after creating it if needed
    func joinNewGroup(with groupID: MLSGroupID) async throws

    func establishGroup(for groupID: MLSGroupID, with users: [MLSUser]) async throws -> MLSCipherSuite

    func createGroup(for groupID: MLSGroupID, parentGroupID: MLSGroupID?) async throws -> MLSCipherSuite

    func conversationExists(groupID: MLSGroupID) async -> Bool

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws

    func performPendingJoins() async throws

    func wipeGroup(_ groupID: MLSGroupID) async throws

    func commitPendingProposalsIfNeeded()

    func commitPendingProposals(in groupID: MLSGroupID) async throws

    func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID

    func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) async throws -> MLSConferenceInfo

    func onConferenceInfoChange(
        parentGroupID: MLSGroupID,
        subConversationGroupID: MLSGroupID
    ) -> AsyncThrowingStream<MLSConferenceInfo, Error>

    func epochChanges() -> AsyncStream<MLSGroupID>

    func leaveSubconversationIfNeeded(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType,
        selfClientID: MLSClientID
    ) async throws

    func leaveSubconversation(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType
    ) async throws

    func deleteSubgroup(parentQualifiedID: QualifiedID) async throws

    func generateNewEpoch(groupID: MLSGroupID) async throws

    func subconversationMembers(for subconversationGroupID: MLSGroupID) async throws -> [MLSClientID]

    func repairOutOfSyncConversations() async

    func fetchAndRepairGroup(with groupID: MLSGroupID) async

    /// Migrate proteus team group conversations to MLS
    func startProteusToMLSMigration() async throws

    func updateKeyMaterialForAllStaleGroupsIfNeeded() async

}

// This is only used in tests, so it should be removed.
public protocol MLSServiceDelegate: AnyObject {

    func mlsServiceDidCommitPendingProposal(for groupID: MLSGroupID)
    func mlsServiceDidUpdateKeyMaterialForAllGroups()

}

public final class MLSService: MLSServiceInterface {

    // MARK: - Properties

    private weak var context: NSManagedObjectContext?
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    private let encryptionService: MLSEncryptionServiceInterface
    private let decryptionService: MLSDecryptionServiceInterface

    private let mlsActionExecutor: MLSActionExecutorProtocol
    private let conversationEventProcessor: ConversationEventProcessorProtocol
    private let staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol
    private let userDefaults: PrivateUserDefaults<Keys>
    private let logger = WireLogger.mls
    private let groupsBeingRepaired = GroupsBeingRepaired()
    private let syncStatus: SyncStatusProtocol
    private let featureRepository: FeatureRepositoryInterface

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    enum Keys: String, DefaultsKey {
        case keyPackageQueriedTime
    }

    var pendingProposalCommitTimers = [MLSGroupID: Timer]()

    let targetUnclaimedKeyPackageCount = 100
    let actionsProvider: MLSActionsProviderProtocol

    private let subconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface

    var lastKeyMaterialUpdateCheck = Date.distantPast
    var keyMaterialUpdateCheckTimer: Timer?

    // The number of days to wait until refreshing the key material for a group.

    private static let epochChangeBufferSize: Int = 1000

    weak var delegate: MLSServiceDelegate?

    // MARK: - Life cycle

    public convenience init(
        context: NSManagedObjectContext,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        conversationEventProcessor: ConversationEventProcessorProtocol,
        featureRepository: FeatureRepositoryInterface,
        userDefaults: UserDefaults,
        syncStatus: SyncStatusProtocol,
        userID: UUID
    ) {
        self.init(
            context: context,
            coreCryptoProvider: coreCryptoProvider,
            conversationEventProcessor: conversationEventProcessor,
            staleKeyMaterialDetector: StaleMLSKeyDetector(context: context),
            userDefaults: userDefaults,
            actionsProvider: MLSActionsProvider(),
            syncStatus: syncStatus,
            userID: userID,
            featureRepository: featureRepository
        )
    }

    init(
        context: NSManagedObjectContext,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        encryptionService: MLSEncryptionServiceInterface? = nil,
        decryptionService: MLSDecryptionServiceInterface? = nil,
        mlsActionExecutor: MLSActionExecutorProtocol? = nil,
        conversationEventProcessor: ConversationEventProcessorProtocol,
        staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol,
        userDefaults: UserDefaults,
        actionsProvider: MLSActionsProviderProtocol = MLSActionsProvider(),
        delegate: MLSServiceDelegate? = nil,
        syncStatus: SyncStatusProtocol,
        userID: UUID,
        featureRepository: FeatureRepositoryInterface,
        subconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface = SubconversationGroupIDRepository()
    ) {
        let commitSender = CommitSender(
            coreCryptoProvider: coreCryptoProvider,
            notificationContext: context.notificationContext
        )

        self.context = context
        self.coreCryptoProvider = coreCryptoProvider
        self.featureRepository = featureRepository
        self.mlsActionExecutor = mlsActionExecutor ?? MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            commitSender: commitSender,
            featureRepository: featureRepository
        )
        self.conversationEventProcessor = conversationEventProcessor
        self.staleKeyMaterialDetector = staleKeyMaterialDetector
        self.actionsProvider = actionsProvider
        self.userDefaults = PrivateUserDefaults(userID: userID, storage: userDefaults)
        self.delegate = delegate
        self.syncStatus = syncStatus
        self.subconversationGroupIDRepository = subconversationGroupIDRepository

        self.encryptionService = encryptionService ?? MLSEncryptionService(
            coreCryptoProvider: coreCryptoProvider
        )

        self.decryptionService = decryptionService ?? MLSDecryptionService(
            context: context,
            mlsActionExecutor: self.mlsActionExecutor,
            subconversationGroupIDRepository: subconversationGroupIDRepository
        )

        schedulePeriodicKeyMaterialUpdateCheck()
    }

    deinit {
        keyMaterialUpdateCheckTimer?.invalidate()
    }

    // MARK: - Public keys

    private func fetchBackendPublicKeys() async -> BackendMLSPublicKeys? {
        logger.info("fetching backend public keys")

        guard let notificationContext = context?.notificationContext else {
            logger.warn("can't fetch backend public keys: notification context is missing")
            return nil
        }

        do {
            return try await actionsProvider.fetchBackendPublicKeys(in: notificationContext)
        } catch {
            logger.warn("failed to fetch backend public keys: \(String(describing: error))")
            return nil
        }
    }

    // MARK: - Conference info for subconversations

    /// Generate conference information for a given conference subconversation.
    ///
    /// - Parameters:
    ///   - parentGroupID: The group ID of the parent conversation.
    ///   - subconversationGroupID: The group ID of the subconversation in which the conference takes place.
    ///
    /// - Returns: An `MLSConferenceInfo` object.
    /// - Throws: `MLSConferenceInfoError`

    public func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) async throws -> MLSConferenceInfo {
        do {
            logger.info("generating conference info")

            let keyLength: UInt32 = 32

            return try await coreCrypto.perform {
                let epoch = try await $0.conversationEpoch(conversationId: subconversationGroupID.data)

                let keyData = try await $0.exportSecretKey(
                    conversationId: subconversationGroupID.data,
                    keyLength: keyLength
                )

                let conversationMembers = try await $0.getClientIds(conversationId: parentGroupID.data)
                    .compactMap { MLSClientID(data: $0) }

                let subconversationMembers = try await $0.getClientIds(conversationId: subconversationGroupID.data)
                    .compactMap { MLSClientID(data: $0) }

                let members = conversationMembers.map {
                    MLSConferenceInfo.Member(
                        id: $0,
                        isInSubconversation: subconversationMembers.contains($0)
                    )
                }

                return MLSConferenceInfo(
                    epoch: epoch,
                    keyData: keyData,
                    members: members
                )
            }
        } catch {
            logger.warn("failed to generate conference info: \(String(describing: error))")
            throw MLSConferenceInfoError.failedToGenerateConferenceInfo
        }
    }

    public func subconversationMembers(for subconversationGroupID: MLSGroupID) async throws -> [MLSClientID] {
        do {
            return try await coreCrypto.perform {
                try await $0.getClientIds(conversationId: subconversationGroupID.data).compactMap {
                    MLSClientID(data: $0)
                }
            }
        } catch {
            logger.warn("failed to get subconversation client ids: \(String(describing: error))")
            throw MLSSubconversationMembersError.failedToGetSubconversationMembers
        }
    }

    public enum MLSSubconversationMembersError: Error, Equatable {
        case failedToGetSubconversationMembers
    }

    public enum MLSConferenceInfoError: Error, Equatable {
        case failedToGenerateConferenceInfo
    }

    public func onConferenceInfoChange(
        parentGroupID: MLSGroupID,
        subConversationGroupID: MLSGroupID
    ) -> AsyncThrowingStream<MLSConferenceInfo, Error> {
        var sequence = onEpochChanged()
            .buffer(size: Self.epochChangeBufferSize, prefetch: .keepFull, whenFull: .dropOldest)
            .filter({ $0.isOne(of: parentGroupID, subConversationGroupID) })
            .values
            .compactMap({ [weak self] _ in
                try await self?.generateConferenceInfo(
                    parentGroupID: parentGroupID,
                    subconversationGroupID: subConversationGroupID
                )
            }).makeAsyncIterator()

        return AsyncThrowingStream {
            try await sequence.next()
        }
    }

    public func epochChanges() -> AsyncStream<MLSGroupID> {
        var sequence = onEpochChanged()
            .buffer(size: Self.epochChangeBufferSize, prefetch: .keepFull, whenFull: .dropOldest)
            .values
            .makeAsyncIterator()

        return AsyncStream {
            await sequence.next()
        }
    }

    // MARK: - Update key material

    private func schedulePeriodicKeyMaterialUpdateCheck() {
        keyMaterialUpdateCheckTimer?.invalidate()
        keyMaterialUpdateCheckTimer = Timer.scheduledTimer(
            withTimeInterval: .oneDay,
            repeats: true
        ) { [weak self] _ in
            guard
                let self,
                let context = context else {
                return
            }

            Task { [context] in
                let hasRegisteredMLSClient = await context.perform { ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient == true }

                guard hasRegisteredMLSClient else {
                    self.logger.info("Skip periodic key material check since MLS is not enabled")
                    return
                }

                await self.updateKeyMaterialForAllStaleGroupsIfNeeded()
            }
        }
    }

    public func updateKeyMaterialForAllStaleGroupsIfNeeded() async {
        guard lastKeyMaterialUpdateCheck.ageInDays >= 1 else { return }

        await updateKeyMaterialForAllStaleGroups()
        lastKeyMaterialUpdateCheck = Date()
        delegate?.mlsServiceDidUpdateKeyMaterialForAllGroups()
    }

    private func updateKeyMaterialForAllStaleGroups() async {
        WireLogger.mls.info("beginning to update key material for all stale groups")

        let staleGroups = staleKeyMaterialDetector.groupsWithStaleKeyingMaterial

        WireLogger.mls.info("found \(staleGroups.count) groups with stale key material")

        for staleGroup in staleGroups {
            try? await updateKeyMaterial(for: staleGroup)
        }
    }

    func updateKeyMaterial(for groupID: MLSGroupID) async throws {
        try await commitPendingProposals(in: groupID)
        try await retryOnCommitFailure(for: groupID) { [weak self] in
            try await self?.internalUpdateKeyMaterial(for: groupID)
        }
    }

    private func internalUpdateKeyMaterial(for groupID: MLSGroupID) async throws {
        do {
            WireLogger.mls.info("updating key material for group (\(groupID.safeForLoggingDescription))")
            let events = try await mlsActionExecutor.updateKeyMaterial(for: groupID)
            staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
            await conversationEventProcessor.processConversationEvents(events)
        } catch {
            WireLogger.mls.warn("failed to update key material for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Group creation

    enum MLSGroupCreationError: Error, Equatable {
        case failedToGetExternalSenders
        case failedToCreateGroup
        case invalidCiphersuite
    }

    /// Establish an MLS group with the given group id.
    ///
    /// - Parameters:
    ///   - groupID the id representing the MLS group.
    ///
    /// - Throws:
    ///   - MLSGroupCreationError if the group could not be created.

    public func establishGroup(for groupID: MLSGroupID, with users: [MLSUser]) async throws -> MLSCipherSuite {
        guard let context else { throw MLSGroupCreationError.failedToCreateGroup }

        do {
            let ciphersuite = try await createGroup(for: groupID)
            let mlsSelfUser = await context.perform {
                let selfUser = ZMUser.selfUser(in: context)
                return MLSUser(from: selfUser)
            }

            let usersWithSelfUser = users + [mlsSelfUser]
            try await addMembersToConversation(with: usersWithSelfUser, for: groupID)
            return ciphersuite
        } catch {
            try await self.wipeGroup(groupID)
            throw error
        }
    }

    public func createGroup(
        for groupID: MLSGroupID,
        parentGroupID: MLSGroupID? = nil
    ) async throws -> MLSCipherSuite {
        logger.info("creating group for id: \(groupID.safeForLoggingDescription)")

        let ciphersuiteRawValue = await featureRepository.fetchMLS().config.defaultCipherSuite.rawValue

        guard let ciphersuite = MLSCipherSuite(rawValue: ciphersuiteRawValue) else {
            throw MLSGroupCreationError.invalidCiphersuite
        }

        do {
            let externalSenders: [Data]
            if let parentGroupID {
                // Anyone in the parent conversation can create a subconversation,
                // even people from different domains. We need to make sure that
                // the external senders is the same as the parent, otherwise we
                // won't be able to decrypt external remove proposals from the
                // owning domain.
                externalSenders = try await coreCrypto.perform {
                    [try await $0.getExternalSender(conversationId: parentGroupID.data)]
                }
            } else if let backendPublicKeys = await fetchBackendPublicKeys() {
                externalSenders = backendPublicKeys.externalSenderKey(for: ciphersuite)
            } else {
                throw MLSGroupCreationError.failedToGetExternalSenders
            }
            let config = ConversationConfiguration(
                ciphersuite: UInt16(ciphersuite.rawValue),
                externalSenders: externalSenders,
                custom: .init(keyRotationSpan: nil, wirePolicy: nil)
            )

            try await coreCrypto.perform {
                let e2eiIsEnabled = try await $0.e2eiIsEnabled(ciphersuite: UInt16(ciphersuite.rawValue))
                try await $0.createConversation(
                    conversationId: groupID.data,
                    creatorCredentialType: e2eiIsEnabled ? .x509 : .basic,
                    config: config
                )
            }
        } catch {
            logger.warn("failed to create group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw MLSGroupCreationError.failedToCreateGroup
        }

        staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)

        return ciphersuite
    }

    public func createSelfGroup(for groupID: MLSGroupID) async throws -> MLSCipherSuite {
        do {
            guard let context else { throw MLSAddMembersError.noManagedObjectContext }
            let ciphersuite = try await self.createGroup(for: groupID)
            let mlsSelfUser = await context.perform {
                let selfUser = ZMUser.selfUser(in: context)
                return MLSUser(from: selfUser)
            }

            do {
                try await addMembersToConversation(with: [mlsSelfUser], for: groupID)
            } catch MLSAddMembersError.noInviteesToAdd {
                logger.debug("createConversation noInviteesToAdd, updateKeyMaterial")
                try await updateKeyMaterial(for: groupID)
            }
            return ciphersuite
        } catch {
            logger.error("create group for self conversation failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Add member

    public enum MLSAddMembersError: Error, Equatable {

        case noMembersToAdd
        case noInviteesToAdd
        case noManagedObjectContext
        case failedToClaimKeyPackages(users: [MLSUser])
        case invalidCiphersuite
    }

    /// Add users to MLS group in the given conversation.
    ///
    /// - Parameters:
    ///   - users: Users represents the MLS group to be added.
    ///   - groupID: Represents the MLS conversation group ID in which users to be added

    public func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {
        try await commitPendingProposals(in: groupID)
        try await retryOnCommitFailure(for: groupID) { [weak self] in
            try await self?.internalAddMembersToConversation(with: users, for: groupID)
        }
    }

    private func internalAddMembersToConversation(
        with users: [MLSUser],
        for groupID: MLSGroupID
    ) async throws {
        do {
            logger.info("adding members to group (\(groupID.safeForLoggingDescription)) with users: \(users)")
            guard !users.isEmpty else { throw MLSAddMembersError.noMembersToAdd }
            let mlsConfig = await featureRepository.fetchMLS().config
            guard let ciphersuite = MLSCipherSuite(rawValue: mlsConfig.defaultCipherSuite.rawValue) else {
                throw MLSAddMembersError.invalidCiphersuite
            }
            let keyPackages = try await claimKeyPackages(for: users, ciphersuite: ciphersuite)

            let events = if keyPackages.isEmpty {
                // CC does not accept empty keypackages in addMembers, but
                // when creating a group we still need to send a commit to backend
                // to inform we are in the group
                try await mlsActionExecutor.updateKeyMaterial(for: groupID)
            } else {
                try await mlsActionExecutor.addMembers(keyPackages, to: groupID)
            }
            await conversationEventProcessor.processConversationEvents(events)

        } catch {
            logger.warn("failed to add members to group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    private func claimKeyPackages(
        for users: [MLSUser],
        ciphersuite: MLSCipherSuite
    ) async throws -> [KeyPackage] {

        guard let context else {
            assertionFailure("MLSService.context is nil")
            return []
        }

        var result = [KeyPackage]()
        var failedUsers = [MLSUser]()

        for user in users {
            do {
                let keyPackages = try await actionsProvider.claimKeyPackages(
                    userID: user.id,
                    domain: user.domain,
                    ciphersuite: ciphersuite,
                    excludedSelfClientID: user.selfClientID,
                    in: context.notificationContext
                )
                result.append(contentsOf: keyPackages)
            } catch {
                failedUsers.append(user)
                logger.warn("failed to claim key packages for user (\(user.id)): \(String(describing: error))")
            }
        }

        if failedUsers.isNonEmpty {
            throw MLSAddMembersError.failedToClaimKeyPackages(users: failedUsers)
        }

        return result
    }

    // MARK: - Remove participants from mls group

    enum MLSRemoveParticipantsError: Error {
        case noClientsToRemove
    }

    public func removeMembersFromConversation(
        with clientIds: [MLSClientID],
        for groupID: MLSGroupID
    ) async throws {
        try await commitPendingProposals(in: groupID)
        try await retryOnCommitFailure(for: groupID) { [weak self] in
            try await self?.internalRemoveMembersFromConversation(with: clientIds, for: groupID)
        }
    }

    private func internalRemoveMembersFromConversation(
        with clientIds: [MLSClientID],
        for groupID: MLSGroupID
    ) async throws {
        do {
            logger.info("removing members from group (\(groupID.safeForLoggingDescription)), members: \(clientIds)")
            guard !clientIds.isEmpty else { throw MLSRemoveParticipantsError.noClientsToRemove }
            let clientIds = clientIds.compactMap { $0.rawValue.utf8Data }
            let events = try await mlsActionExecutor.removeClients(clientIds, from: groupID)
            await conversationEventProcessor.processConversationEvents(events)
        } catch {
            logger.warn("failed to remove members from group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Remove group

    public func wipeGroup(_ groupID: MLSGroupID) async throws {
        logger.info("wiping group (\(groupID.safeForLoggingDescription))")
        do {
            try await coreCrypto.perform { try await $0.wipeConversation(conversationId: groupID.data) }
        } catch {
            logger.warn("failed to wipe group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Key packages

    enum MLSKeyPackagesError: Error {

        case failedToGenerateKeyPackages
        case failedToUploadKeyPackages
        case failedToCountUnclaimedKeyPackages
    }

    /// Uploads new key packages if needed.
    ///
    /// Checks how many key packages are available on the backend and
    /// generates new ones if there are less than 50% of the target unclaimed key package count..

    public func uploadKeyPackagesIfNeeded() async {
        logger.info("uploading key packages if needed")

        func logWarn(abortedWithReason reason: String) {
            logger.warn("aborting key packages upload: \(reason)")
        }

        guard await shouldQueryUnclaimedKeyPackagesCount() else { return }

        guard let context else {
            return logWarn(abortedWithReason: "missing context")
        }

        guard let clientID = await context.perform({ ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier }) else {
            return logWarn(abortedWithReason: "failed to get client ID")
        }

        do {
            let unclaimedKeyPackageCount = try await countUnclaimedKeyPackages(clientID: clientID, context: context.notificationContext)
            logger.info("there are \(unclaimedKeyPackageCount) unclaimed key packages")

            guard unclaimedKeyPackageCount <= halfOfTargetUnclaimedKeyPackageCount else {
                logger.info("no need to upload new key packages yet")
                return
            }

            let amount = UInt32(targetUnclaimedKeyPackageCount)
            let keyPackages = try await generateKeyPackages(amountRequested: amount)
            try await uploadKeyPackages(clientID: clientID, keyPackages: keyPackages, context: context.notificationContext)
            userDefaults.set(Date(), forKey: .keyPackageQueriedTime)
            logger.info("success: uploaded key packages for client \(clientID)")
        } catch let error {
            logger.warn("failed to upload key packages for client \(clientID). \(String(describing: error))")
        }
    }

    private func shouldQueryUnclaimedKeyPackagesCount() async -> Bool {
        do {
            let ciphersuite = UInt16(await featureRepository.fetchMLS().config.defaultCipherSuite.rawValue)
            let estimatedLocalKeyPackageCount = try await coreCrypto.perform {
                try await $0.clientValidKeypackagesCount(ciphersuite: ciphersuite, credentialType: .basic)
            }
            let shouldCountRemainingKeyPackages = estimatedLocalKeyPackageCount < halfOfTargetUnclaimedKeyPackageCount

            guard hasMoreThan24HoursPassedSinceLastCheck || shouldCountRemainingKeyPackages else {
                logger.info("last check was recent and there are enough unclaimed key packages. not uploading.")
                return false
            }

            return true

        } catch {
            logger.warn("failed to get valid key packages count with error: \(String(describing: error))")
            return true
        }
    }

    private var hasMoreThan24HoursPassedSinceLastCheck: Bool {
        guard let storedDate = userDefaults.date(forKey: .keyPackageQueriedTime) else { return true }

        if Calendar.current.dateComponents([.hour], from: storedDate, to: Date()).hour > 24 {
            return true
        } else {
            return false
        }
    }

    private var halfOfTargetUnclaimedKeyPackageCount: Int {
        targetUnclaimedKeyPackageCount / 2
    }

    private func countUnclaimedKeyPackages(
        clientID: String,
        context: NotificationContext
    ) async throws -> Int {
        do {
            return try await actionsProvider.countUnclaimedKeyPackages(
                clientID: clientID,
                context: context
            )

        } catch let error {
            self.logger.warn("failed to fetch unclaimed key packages count with error: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToCountUnclaimedKeyPackages
        }
    }

    private func generateKeyPackages(amountRequested: UInt32) async throws -> [String] {
        logger.info("generating \(amountRequested) key packages")

        var keyPackages = [Data]()

        do {
            let ciphersuite = UInt16(await featureRepository.fetchMLS().config.defaultCipherSuite.rawValue)
            keyPackages = try await coreCrypto.perform {
                let e2eiIsEnabled = try await $0.e2eiIsEnabled(ciphersuite: ciphersuite)
                return try await $0.clientKeypackages(
                    ciphersuite: ciphersuite,
                    credentialType: e2eiIsEnabled ? .x509 : .basic,
                    amountRequested: amountRequested
                ) }

        } catch let error {
            logger.warn("failed to generate new key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        if keyPackages.isEmpty {
            logger.warn("CoreCrypto generated empty key packages array")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        return keyPackages.map { $0.base64EncodedString() }
    }

    private func uploadKeyPackages(
        clientID: String,
        keyPackages: [String],
        context: NotificationContext
    ) async throws {

        do {
            try await actionsProvider.uploadKeyPackages(
                clientID: clientID,
                keyPackages: keyPackages,
                context: context
            )

        } catch let error {
            logger.warn("failed to upload key packages for client (\(clientID)): \(String(describing: error))")
            throw MLSKeyPackagesError.failedToUploadKeyPackages
        }
    }

    // MARK: - Process welcome message

    public enum MLSWelcomeMessageProcessingError: Error {

        case failedToConvertMessageToBytes
        case failedToProcessMessage

    }

    public func conversationExists(groupID: MLSGroupID) async -> Bool {
        // swiftlint:disable todo_requires_jira_link
        // TODO: [jacob] let it throw
        // swiftlint:enable todo_requires_jira_link
        let result = (try? await coreCrypto.perform { await $0.conversationExists(conversationId: groupID.data) }) ?? false
        logger.info("checking if group (\(groupID)) exists... it does\(result ? "!" : " not!")")
        return result
    }

    public func processWelcomeMessage(welcomeMessage: String) async throws -> MLSGroupID {
        return try await decryptionService.processWelcomeMessage(welcomeMessage: welcomeMessage)
    }

    // MARK: - Joining conversations

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        guard let context = context else {
            logger.warn("MLSService is missing sync context")
            return
        }

        // TODO: [WPB-9029] jacob this looks wrong,
        // why would we create the MLS group if doesn't exist? We are about
        // to join it via external commit.
        if await !conversationExists(groupID: groupID) {
            try await _ = createGroup(for: groupID)
        }

        let mlsUser = await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            return MLSUser(from: selfUser)
        }

        try await joinGroup(with: groupID)
        try await addMembersToConversation(with: [mlsUser], for: groupID)
    }

    public func joinGroup(with groupID: MLSGroupID) async throws {
        try await joinByExternalCommit(groupID: groupID)
    }

    typealias PendingJoin = (groupID: MLSGroupID, epoch: UInt64)

    /// Request to join groups still pending
    ///
    /// Generates a list of groups for which the `mlsStatus` is `pendingJoin`
    /// and sends external commits to join these groups
    public func performPendingJoins() async throws {
        guard let context = context else {
            return
        }

        let pendingGroups = try await context.perform {
            try ZMConversation.fetchConversationsWithMLSGroupStatus(
                mlsGroupStatus: .pendingJoin,
                in: context
            ).compactMap(\.mlsGroupID)
        }

        logger.info("joining \(pendingGroups.count) group(s)")

        await withTaskGroup(of: Void.self) { group in
            for pendingGroup in pendingGroups {
                group.addTask {
                    do {
                        try await self.joinByExternalCommit(groupID: pendingGroup)
                    } catch {
                        WireLogger.mls.error("Failed to join pending group (\(pendingGroup): \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Out-of-sync conversations

    /// Fetches and re-joins MLS conversations that are out of sync
    /// (where the conversation object's epoch differs from the corresponding MLS group epoch)
    public func repairOutOfSyncConversations() async {
        guard let context = self.context else { return }

        let outOfSyncConversationInfos = await outOfSyncConversations(in: context)

        logger.info("found \(outOfSyncConversationInfos.count) conversations out of sync")

        for conversationInfo in outOfSyncConversationInfos {

            await launchGroupRepairTaskIfNotInProgress(for: conversationInfo.mlsGroupId) {
                do {
                    try await self.joinGroupAndAppendGapSystemMessage(
                        groupID: conversationInfo.mlsGroupId,
                        conversation: conversationInfo.conversation,
                        context: context
                    )
                } catch {
                    self.logger.warn("failed to repair out of sync conversation (\(conversationInfo.mlsGroupId.safeForLoggingDescription)). error: \(String(reflecting: error))")
                }
            }
        }
    }

    func fetchAndRepairGroupIfPossible(with groupID: MLSGroupID) async {
        await launchGroupRepairTaskIfNotInProgress(for: groupID) {
            await self.fetchAndRepairGroup(with: groupID)
        }
    }

    public func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        if let subgroupInfo = await subconversationGroupIDRepository.findSubgroupTypeAndParentID(for: groupID) {
            await fetchAndRepairSubgroup(parentGroupID: subgroupInfo.parentID)
        } else {
            await fetchAndRepairParentGroup(with: groupID)
        }
    }

    private func fetchAndRepairParentGroup(with groupID: MLSGroupID) async {
        guard let context = context else {
            return
        }

        do {
            logger.info("repairing out of sync conversation... (\(groupID.safeForLoggingDescription))")

            guard let conversationInfo = fetchConversationInfo(
                with: groupID,
                in: context
            ) else {
                logger.warn("conversation not found (\(groupID.safeForLoggingDescription))")
                return
            }

            try await actionsProvider.syncConversation(
                qualifiedID: conversationInfo.qualifiedID,
                context: context.notificationContext
            )

            guard await isConversationOutOfSync(
                conversationInfo.conversation,
                context: context
            ) else {
                logger.info("conversation is not out of sync (\(groupID.safeForLoggingDescription))")
                return
            }

            try await joinGroupAndAppendGapSystemMessage(
                groupID: groupID,
                conversation: conversationInfo.conversation,
                context: context
            )
        } catch {
            logger.warn("failed to repair conversation (\(groupID.safeForLoggingDescription)). error: \(String(describing: error))")
        }

    }

    private func joinGroupAndAppendGapSystemMessage(
        groupID: MLSGroupID,
        conversation: ZMConversation,
        context: NSManagedObjectContext
    ) async throws {
        try await joinGroup(with: groupID)

        logger.info("repaired out of sync conversation! (\(groupID.safeForLoggingDescription))")

        await appendGapSystemMessage(
            in: conversation,
            context: context
        )

        logger.info("inserted gap system message in conversation (\(groupID.safeForLoggingDescription))")
    }

    private func appendGapSystemMessage(
        in conversation: ZMConversation,
        context: NSManagedObjectContext
    ) async {
        await context.perform {
            conversation.appendNewPotentialGapSystemMessage(
                users: conversation.localParticipants,
                timestamp: Date()
            )
        }
    }

    private func fetchAndRepairSubgroup(parentGroupID: MLSGroupID) async {
        guard let context = context else { return }

        do {
            logger.info("repairing out of sync subgroup... (parent: \(parentGroupID.safeForLoggingDescription))")

            guard let conversationInfo = fetchConversationInfo(
                with: parentGroupID,
                in: context
            ) else {
                logger.warn("conversation not found (\(parentGroupID.safeForLoggingDescription))")
                return
            }

            let subgroup = try await fetchSubgroup(
                parentID: conversationInfo.qualifiedID,
                context: context.notificationContext
            )

            guard await isConversationOutOfSync(
                conversationInfo.conversation,
                subgroup: subgroup,
                context: context
            ) else {
                logger.info("subgroup is not out of sync (parent: \(parentGroupID.safeForLoggingDescription), subgroup: \(subgroup.groupID.safeForLoggingDescription))")
                return
            }

            try await joinSubgroup(
                parentID: parentGroupID,
                subgroupID: subgroup.groupID
            )

            logger.info("repaired out of sync subgroup! (parent: \(parentGroupID.safeForLoggingDescription), subgroup: \(subgroup.groupID.safeForLoggingDescription))")
        } catch {
            logger.warn("failed to repair subgroup (parent: \(parentGroupID.safeForLoggingDescription)). error: \(String(describing: error))")
        }
    }

    private func launchGroupRepairTaskIfNotInProgress(
        for groupID: MLSGroupID,
        repairOperation: @escaping () async -> Void
    ) async {
        guard await !groupsBeingRepaired.contains(group: groupID) else {
            return
        }

        await groupsBeingRepaired.insert(group: groupID)
        await repairOperation()
        await groupsBeingRepaired.remove(group: groupID)
    }

    typealias OutOfSyncConversationInfo = (mlsGroupId: MLSGroupID, conversation: ZMConversation)

    private func outOfSyncConversations(in context: NSManagedObjectContext) async -> [OutOfSyncConversationInfo] {

        let conversations: [ZMConversation] = (try? await coreCrypto.perform { coreCrypto in
            let mlsConversations = await context.perform { ZMConversation.fetchMLSConversations(in: context) }
            return await mlsConversations.asyncFilter {
                await isConversationOutOfSync(
                    $0,
                    coreCrypto: coreCrypto,
                    context: context
                ) == true
            } // swiftlint:disable todo_requires_jira_link
        }) ?? [] // TODO: [jacob] let it throw
        // swiftlint:enable todo_requires_jira_link
        return await context.perform { conversations.compactMap {
            if let groupId = $0.mlsGroupID {
                return (groupId, $0)
            } else {
                return nil
            }
        } }
    }

    private func isConversationOutOfSync(
        _ conversation: ZMConversation,
        subgroup: MLSSubgroup? = nil,
        coreCrypto: CoreCryptoProtocol,
        context: NSManagedObjectContext
    ) async -> Bool {
        var groupID: MLSGroupID?
        var epoch: UInt64?

        await context.perform {
            if let subgroup = subgroup {
                groupID = subgroup.groupID
                epoch = UInt64(subgroup.epoch)
            } else {
                groupID = conversation.mlsGroupID
                epoch = conversation.epoch
            }
        }
        guard let groupID, let epoch else { return false }

        do {
            let localEpoch = try await coreCrypto.conversationEpoch(conversationId: groupID.data)

            logger.info("epochs(remote: \(epoch), local: \(localEpoch)) for (\(groupID.safeForLoggingDescription))")
            return localEpoch < epoch
        } catch {
            logger.info("cannot resolve conversation epoch \(String(describing: error)) for (\(groupID.safeForLoggingDescription))")
            return false
        }
    }

    private func isConversationOutOfSync(
        _ conversation: ZMConversation,
        subgroup: MLSSubgroup? = nil,
        context: NSManagedObjectContext
    ) async -> Bool {
        return (try? await coreCrypto.perform {
            return await isConversationOutOfSync(
                conversation,
                subgroup: subgroup,
                coreCrypto: $0,
                context: context
            ) // swiftlint:disable todo_requires_jira_link
        }) ?? false // TODO: [jacob] let it throw
    } // swiftlint: enable todo_requires_jira_link

    // MARK: - External Proposals

    private func sendExternalAddProposal(_ groupID: MLSGroupID, epoch: UInt64) async {
        logger.info("requesting to join group (\(groupID.safeForLoggingDescription)")

        do {
            let ciphersuite = UInt16(await featureRepository.fetchMLS().config.defaultCipherSuite.rawValue)
            let proposal = try await coreCrypto.perform {
                try await $0.newExternalAddProposal(conversationId: groupID.data,
                                                    epoch: epoch,
                                                    ciphersuite: ciphersuite,
                                                    credentialType: .basic)
            }

            try await sendProposal(proposal, groupID: groupID)
            logger.info("success: requested to join group (\(groupID.safeForLoggingDescription)")
        } catch {
            logger.warn(
                "failed to request join for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))"
            )
        }
    }

    enum MLSSendProposalError: Error {
        case failedToSendProposal
    }

    private func sendProposal(_ data: Data, groupID: MLSGroupID) async throws {
        do {
            logger.info("sending proposal in group (\(groupID.safeForLoggingDescription))")

            guard let context = context else { return }

            let updateEvents = try await actionsProvider.sendMessage(
                data,
                in: context.notificationContext
            )

            await conversationEventProcessor.processConversationEvents(updateEvents)

        } catch let error {
            logger.warn("failed to send proposal in group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw MLSSendProposalError.failedToSendProposal
        }
    }

    // MARK: - External Commits

    private func joinByExternalCommit(groupID: MLSGroupID) async throws {
        try await joinByExternalCommit(parentID: groupID)
    }

    private func joinSubgroupByExternalCommit(
        parentID: MLSGroupID,
        subgroupID: MLSGroupID,
        subgroupType: SubgroupType
    ) async throws {
        try await joinByExternalCommit(
            parentID: parentID,
            subgroupIDAndType: (subgroupID, subgroupType)
        )
    }

    private func joinByExternalCommit(
        parentID: MLSGroupID,
        subgroupIDAndType: (MLSGroupID, SubgroupType)? = nil
    ) async throws {
        try await retryOnCommitFailure(for: parentID, operation: { [weak self] in
            try await self?.internalJoinByExternalCommit(
                parentID: parentID,
                subgroupIDAndType: subgroupIDAndType
            )
        })
    }

    enum MLSSendExternalCommitError: Error {
        case conversationNotFound
    }

    private func internalJoinByExternalCommit(
        parentID: MLSGroupID,
        subgroupIDAndType: (MLSGroupID, SubgroupType)?
    ) async throws {
        let subgroupID = subgroupIDAndType?.0
        let subgroupType = subgroupIDAndType?.1

        let logInfo = "parent: \(parentID.safeForLoggingDescription), subgroup: \(String(describing: subgroupID?.safeForLoggingDescription)), subgroup type: \(String(describing: subgroupType))"

        do {
            logger.info("sending external commit to join group (\(logInfo))")

            guard let context = context else { return }

            guard let parentConversationInfo = fetchConversationInfo(
                with: parentID,
                in: context
            ) else {
                throw MLSSendExternalCommitError.conversationNotFound
            }

            let groupInfo = try await actionsProvider.fetchConversationGroupInfo(
                conversationId: parentConversationInfo.qualifiedID.uuid,
                domain: parentConversationInfo.qualifiedID.domain,
                subgroupType: subgroupType,
                context: context.notificationContext
            )

            let updateEvents: [ZMUpdateEvent]

            if let subgroupID = subgroupID {
                updateEvents = try await mlsActionExecutor.joinGroup(
                    subgroupID,
                    groupInfo: groupInfo
                )
            } else {
                updateEvents = try await mlsActionExecutor.joinGroup(
                    parentID,
                    groupInfo: groupInfo
                )

                await context.perform {
                    parentConversationInfo.conversation.mlsStatus = .ready
                }
            }

            await conversationEventProcessor.processConversationEvents(updateEvents)
            logger.info("success: joined group with external commit (\(logInfo))")

        } catch {
            logger.warn("failed to send external commit to join group (\(logInfo)): \(String(describing: error))")
            throw error
        }
    }

    private func fetchConversationInfo(
        with groupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) -> (conversation: ZMConversation, qualifiedID: QualifiedID, groupID: MLSGroupID)? {

        var conversation: ZMConversation?
        var qualifiedID: QualifiedID?

        context.performAndWait {
            conversation = ZMConversation.fetch(with: groupID, in: context)
            qualifiedID = conversation?.qualifiedID
        }

        guard
            let conversation = conversation,
            let qualifiedID = qualifiedID
        else {
            return nil
        }

        return (conversation, qualifiedID, groupID)
    }

    // MARK: - Encrypt message

    public func encrypt(
        message: Data,
        for groupID: MLSGroupID
    ) async throws -> Data {
        return try await encryptionService.encrypt(
            message: message,
            for: groupID
        )
    }

    // MARK: - Decrypting Message

    public func decrypt(
        message: String,
        for groupID: MLSGroupID,
        subconversationType: SubgroupType?
    ) async throws -> [MLSDecryptResult] {
        typealias DecryptionError = MLSDecryptionService.MLSMessageDecryptionError

        do {
            return try await decryptionService.decrypt(
                message: message,
                for: groupID,
                subconversationType: subconversationType
            )
        } catch DecryptionError.wrongEpoch {
            await fetchAndRepairGroupIfPossible(with: groupID)
            throw DecryptionError.wrongEpoch
        } catch {
            throw error
        }
    }

    // MARK: - Pending proposals

    enum MLSCommitPendingProposalsError: Error {

        case failedToCommitPendingProposals

    }

    public func commitPendingProposalsIfNeeded() {
        guard let context = context else {
            return
        }

        WaitingGroupTask(context: context) { [self] in
            await commitPendingProposals()
        }
    }

    func commitPendingProposals() async {
        guard context != nil else {
            return
        }

        logger.info("committing any scheduled pending proposals")

        let groupsWithPendingCommits = await self.sortedGroupsWithPendingCommits()

        logger.info("\(groupsWithPendingCommits.count) groups with scheduled pending proposals")

        // Committing proposals for each group is independent and should not wait for
        // each other.
        await withTaskGroup(of: Void.self) { taskGroup in
            for (groupID, timestamp) in groupsWithPendingCommits {
                taskGroup.addTask { [self] in
                    do {
                        if timestamp.isInThePast {
                            logger.info("commit scheduled in the past, committing...")
                            try await commitPendingProposals(in: groupID)
                        } else {
                            logger.info("commit scheduled in the future, waiting...")

                            let timeIntervalSinceNow = timestamp.timeIntervalSinceNow
                            if timeIntervalSinceNow > 0 {
                                try await Task.sleep(nanoseconds: timeIntervalSinceNow.nanoseconds)
                            }
                            logger.info("scheduled commit is ready, committing...")
                            try await commitPendingProposals(in: groupID)
                        }

                    } catch {
                        logger.error("failed to commit pending proposals: \(String(describing: error))")
                    }
                }
            }
        }
    }

    private func sortedGroupsWithPendingCommits() async -> [(MLSGroupID, Date)] {
        guard let context = context else {
            return []
        }

        var result: [(MLSGroupID, Date)] = []

        let conversations = await context.perform { ZMConversation.fetchConversationsWithPendingProposals(in: context) }

        for conversation in conversations {
            let (groupID, timestamp) = await context.perform {
                (conversation.mlsGroupID,
                conversation.commitPendingProposalDate)
            }

            guard let groupID, let timestamp else {
                    continue
            }

            result.append((groupID, timestamp))

            // The pending proposal might be for the subconversation,
            // so include it just in case.
            if let subgroupID = await subconversationGroupIDRepository.fetchSubconversationGroupID(
                forType: .conference,
                parentGroupID: groupID
            ) {
                result.append((subgroupID, timestamp))
            }
        }

        return result.sorted { lhs, rhs in
            let (lhsCommitDate, rhsCommitDate) = (lhs.1, rhs.1)
            return lhsCommitDate <= rhsCommitDate
        }
    }

    private func commitPendingProposalsIfNeeded(in groupID: MLSGroupID) async throws {
        guard existsPendingProposals(in: groupID) else { return }
        // Sending a message while there are pending proposals will result in an error,
        // so commit any first.
        logger.info("preemptively committing pending proposals in group (\(groupID.safeForLoggingDescription))")
        try await commitPendingProposals(in: groupID)
        logger.info("success: committed pending proposals in group (\(groupID.safeForLoggingDescription))")
    }

    private func existsPendingProposals(in groupID: MLSGroupID) -> Bool {
        guard let context = context else { return false }

        var groupHasPendingProposals = false

        context.performAndWait {
            if let conversation = ZMConversation.fetch(with: groupID, in: context) {
                groupHasPendingProposals = conversation.commitPendingProposalDate != nil
            }
        }

        return groupHasPendingProposals
    }

    public func commitPendingProposals(in groupID: MLSGroupID) async throws {
        try await retryOnCommitFailure(for: groupID) { [weak self] in
            try await self?.internalCommitPendingProposals(in: groupID)
        }
    }

    private func internalCommitPendingProposals(in groupID: MLSGroupID) async throws {
        do {
            logger.info("committing pending proposals in: \(groupID.safeForLoggingDescription)")
            let events = try await mlsActionExecutor.commitPendingProposals(in: groupID)
            await conversationEventProcessor.processConversationEvents(events)
            clearPendingProposalCommitDate(for: groupID)
            delegate?.mlsServiceDidCommitPendingProposal(for: groupID)
        } catch CommitError.noPendingProposals {
            logger.info("no proposals to commit in group (\(groupID.safeForLoggingDescription))...")
            clearPendingProposalCommitDate(for: groupID)
        } catch {
            logger.info("failed to commit pending proposals in \(groupID.safeForLoggingDescription): \(String(describing: error))")
            throw error
        }
    }

    private func clearPendingProposalCommitDate(for groupID: MLSGroupID) {
        guard let context = context else {
            return
        }

        context.performAndWait {
            let conversation = ZMConversation.fetch(with: groupID, in: context)
            conversation?.commitPendingProposalDate = nil
        }
    }

    // MARK: - Error recovery

    private func retryOnCommitFailure(
        for groupID: MLSGroupID,
        operation: @escaping () async throws -> Void
    ) async throws {

        do {
            try await operation()

        } catch CommitError.failedToSendCommit(recovery: .commitPendingProposalsAfterQuickSync, _) {
            logger.warn("failed to send commit, syncing then committing pending proposals...")
            await syncStatus.performQuickSync()
            logger.info("sync finished, committing pending proposals...")
            try await commitPendingProposals(in: groupID)

        } catch CommitError.failedToSendCommit(recovery: .retryAfterQuickSync, _) {
            logger.warn("failed to send commit, syncing then retrying operation...")
            await syncStatus.performQuickSync()
            logger.info("sync finished, retying operation...")
            try await retryOnCommitFailure(for: groupID, operation: operation)

        } catch CommitError.failedToSendCommit(recovery: .retryAfterRepairingGroup, _) {
            logger.warn("failed to send commit, repairing group then retrying operation...")
            await fetchAndRepairGroup(with: groupID)
            logger.info("repair finished, retrying operation...")
            try await operation()

        } catch CommitError.failedToSendCommit(recovery: .giveUp, cause: let error) {
            logger.warn("failed to send commit, giving up...")
            throw error

        } catch ExternalCommitError.failedToSendCommit(recovery: .retry, _) {
            logger.warn("failed to send external commit, retrying operation...")
            try await retryOnCommitFailure(for: groupID, operation: operation)

        } catch ExternalCommitError.failedToSendCommit(recovery: .giveUp, cause: let error) {
            logger.warn("failed to send external commit, giving up...")
            throw error

        }
    }

    // MARK: - Subgroup

    public enum SubgroupFailure: Error {

        case missingNotificationContext
        case failedToFetchSubgroup
        case failedToCreateSubgroup
        case failedToDeleteSubgroup
        case failedToJoinSubgroup
        case missingSubgroupID

    }

    public func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID {
        do {
            logger.info("create or join subgroup in parent conversation (\(parentQualifiedID))")

            guard let notificationContext = context?.notificationContext else {
                logger.error("failed to create or join subgroup: missing notification context")
                throw SubgroupFailure.missingNotificationContext
            }

            let subgroup = try await fetchSubgroup(
                parentID: parentQualifiedID,
                context: notificationContext
            )

            await subconversationGroupIDRepository.storeSubconversationGroupID(
                subgroup.groupID,
                forType: .conference,
                parentGroupID: parentID
            )

            if subgroup.epoch <= 0 {
                try await createSubgroup(
                    with: subgroup.groupID,
                    parentID: parentID
                )
            } else if let epochAge = subgroup.epochTimestamp?.ageInDays, epochAge >= 1 {
                try await deleteSubgroup(
                    parentID: parentQualifiedID,
                    subgroup: subgroup,
                    context: notificationContext
                )
                try await createSubgroup(
                    with: subgroup.groupID,
                    parentID: parentID
                )
            } else {
                try await joinSubgroup(
                    parentID: parentID,
                    subgroupID: subgroup.groupID
                )
            }

            return subgroup.groupID
        } catch {
            logger.error("failed to create or join subgroup in parent conversation (\(parentQualifiedID)): \(String(describing: error))")
            throw error
        }
    }

    private func fetchSubgroup(
        parentID: QualifiedID,
        context: NotificationContext
    ) async throws -> MLSSubgroup {
        do {
            logger.info("fetching subgroup with parent id (\(parentID))")
            return try await actionsProvider.fetchSubgroup(
                conversationID: parentID.uuid,
                domain: parentID.domain,
                type: .conference,
                context: context
            )
        } catch {
            logger.error("failed to fetch subgroup with parent id (\(parentID)): \(String(describing: error))")
            throw SubgroupFailure.failedToFetchSubgroup
        }
    }

    private func createSubgroup(
        with id: MLSGroupID,
        parentID: MLSGroupID
    ) async throws {
        do {
            logger.info("creating subgroup with id (\(id.safeForLoggingDescription))")
            try await createGroup(for: id, parentGroupID: parentID)
            try await updateKeyMaterial(for: id)
        } catch {
            logger.error("failed to create subgroup with id (\(id.safeForLoggingDescription)): \(String(describing: error))")
            throw SubgroupFailure.failedToCreateSubgroup
        }
    }

    public func deleteSubgroup(parentQualifiedID: QualifiedID) async throws {
        guard let notificationContext = context?.notificationContext else {
            logger.error("failed to delete subgroup: missing notification context")
            throw SubgroupFailure.missingNotificationContext
        }
        let subgroup = try await fetchSubgroup(
            parentID: parentQualifiedID,
            context: notificationContext
        )

        try await deleteSubgroup(
            parentID: parentQualifiedID,
            subgroup: subgroup,
            context: notificationContext)
    }

    private func deleteSubgroup(
        parentID: QualifiedID,
        subgroup: MLSSubgroup,
        context: NotificationContext
    ) async throws {
        do {
            logger.info("deleting subgroup with parent id (\(parentID))")
            try await actionsProvider.deleteSubgroup(
                conversationID: parentID.uuid,
                domain: parentID.domain,
                subgroupType: .conference,
                epoch: subgroup.epoch,
                groupID: subgroup.groupID,
                context: context
            )
        } catch {
            logger.error("failed to delete subgroup with parent id (\(parentID)): \(String(describing: error))")
            throw SubgroupFailure.failedToDeleteSubgroup
        }
    }

    private func joinSubgroup(
        parentID: MLSGroupID,
        subgroupID: MLSGroupID
    ) async throws {
        do {
            logger.info("joining subgroup (parent: \(parentID.safeForLoggingDescription), subgroup: \(subgroupID.safeForLoggingDescription))")
            try await joinSubgroupByExternalCommit(
                parentID: parentID,
                subgroupID: subgroupID,
                subgroupType: .conference
            )
        } catch {
            logger.error("failed to join subgroup (parent: \(parentID.safeForLoggingDescription), subgroup: \(subgroupID.safeForLoggingDescription)): \(String(describing: error))")
            throw SubgroupFailure.failedToJoinSubgroup
        }
    }

    public func leaveSubconversationIfNeeded(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType,
        selfClientID: MLSClientID
    ) async throws {
        func leaveSubconversation(id: MLSGroupID) async throws {
            try await self.leaveSubconversation(
                subconversationGroupID: id,
                parentQualifiedID: parentQualifiedID,
                parentGroupID: parentGroupID,
                subconversationType: subconversationType
            )
        }

        if
            let subConversationGroupID = await subconversationGroupIDRepository.fetchSubconversationGroupID(
                forType: subconversationType,
                parentGroupID: parentGroupID
            ),
            await conversationExists(groupID: subConversationGroupID)
        {
            try await leaveSubconversation(id: subConversationGroupID)
        } else if let context = context?.notificationContext {
            let subconversation = try await actionsProvider.fetchSubgroup(
                conversationID: parentQualifiedID.uuid,
                domain: parentQualifiedID.domain,
                type: subconversationType,
                context: context
            )

            guard subconversation.members.contains(selfClientID) else { return }
            try await leaveSubconversation(id: subconversation.groupID)
        }
    }

    public func leaveSubconversation(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType
    ) async throws {
        guard let subconversationGroupID = await subconversationGroupIDRepository.fetchSubconversationGroupID(
            forType: subconversationType,
            parentGroupID: parentGroupID
        ) else {
            throw SubgroupFailure.missingSubgroupID
        }

        try await leaveSubconversation(
            subconversationGroupID: subconversationGroupID,
            parentQualifiedID: parentQualifiedID,
            parentGroupID: parentGroupID,
            subconversationType: subconversationType
        )
    }

    private func leaveSubconversation(
        subconversationGroupID: MLSGroupID,
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType
    ) async throws {
        do {
            logger.info("leaving subconversation (\(subconversationType)) with parent (\(parentQualifiedID))")

            guard let context = context?.notificationContext else {
                throw SubgroupFailure.missingNotificationContext
            }

            try await actionsProvider.leaveSubconversation(
                conversationID: parentQualifiedID.uuid,
                domain: parentQualifiedID.domain,
                subconversationType: subconversationType,
                context: context
            )

            await subconversationGroupIDRepository.storeSubconversationGroupID(
                nil,
                forType: subconversationType,
                parentGroupID: parentGroupID
            )

            try await coreCrypto.perform {
                try await $0.wipeConversation(conversationId: subconversationGroupID.data)
            }
        } catch {
            logger.error("failed to leave subconversation (\(subconversationType)) with parent (\(parentQualifiedID)): \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Epoch

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        return decryptionService.onEpochChanged()
            .merge(with: mlsActionExecutor.onEpochChanged())
            .eraseToAnyPublisher()
    }

    // MARK: - Generate new epoch

    public func generateNewEpoch(groupID: MLSGroupID) async throws {
        logger.info("generating new epoch in subconveration (\(groupID.safeForLoggingDescription))")
        try await updateKeyMaterial(for: groupID)
    }

    // MARK: - CRLs distribution points

    public func onNewCRLsDistributionPoints() -> AnyPublisher<CRLsDistributionPoints, Never> {
        decryptionService.onNewCRLsDistributionPoints()
            .merge(with: mlsActionExecutor.onNewCRLsDistributionPoints())
            .eraseToAnyPublisher()
    }

    // MARK: - Proteus to MLS Migration

    public func startProteusToMLSMigration() async throws {
        guard let context = context else {
            assertionFailure("MLSService.context is nil")
            return
        }

        let groupConversations = try await context.perform {
            try ZMConversation.fetchAllTeamGroupConversations(messageProtocol: .proteus, in: context)
        }
        for conversation in groupConversations {

            let (qualifiedID, members) = await context.perform {
                (conversation.qualifiedID, conversation.localParticipants.map { MLSUser(from: $0) })
            }

            guard let qualifiedID else {
                logger.warn("skipping migration of conversation \(conversation), `qualifiedID` is `nil`")
                assertionFailure("the group conversation has no `qualifiedID` set")
                continue
            }

            do {
                // update message protocol to `mixed`
                try await actionsProvider.updateConversationProtocol(
                    qualifiedID: qualifiedID,
                    messageProtocol: .mixed,
                    context: context.notificationContext
                )

                try await actionsProvider.syncConversation(
                    qualifiedID: qualifiedID,
                    context: context.notificationContext
                )

                // create MLS group and update keying material
                let mlsGroupID = await context.perform { conversation.mlsGroupID }
                guard let mlsGroupID else {
                    logger.warn("failed to convert conversation \(qualifiedID), `mlsGroupID` is `nil`")
                    assertionFailure("the group conversation has no `mlsGroupID` set")
                    continue
                }

                try await createGroup(for: mlsGroupID)

                do {

                    // update keying material and send commit bundle to the backend
                    try await internalUpdateKeyMaterial(for: mlsGroupID)

                    // add all participants (all clients) to the group
                    try await addMembersToConversation(with: members, for: mlsGroupID)

                } catch SendMLSMessageAction.Failure.mlsStaleMessage {

                    logger.error("failed to migrate conversation \(qualifiedID): stale message")

                    // rollback: destroy/wipe group
                    try await wipeGroup(mlsGroupID)

                }

            } catch {
                logger.error("failed to migrate conversation \(qualifiedID): \(String(describing: error))")
                continue
            }
        }
    }
}

// MARK: - Helper types

public struct MLSUser: Equatable {

    public let id: UUID
    public let domain: String
    public let selfClientID: String?

    public init(
        _ qualifiedID: QualifiedID,
        selfClientID: String? = nil
    ) {
        self.id = qualifiedID.uuid
        self.domain = qualifiedID.domain
        self.selfClientID = selfClientID
    }

    public init(
        id: UUID,
        domain: String,
        selfClientID: String? = nil
    ) {
        self.id = id
        self.domain = domain
        self.selfClientID = selfClientID
    }

    public init(from user: ZMUser) {
        id = user.remoteIdentifier
        domain = user.domain?.selfOrNilIfEmpty ?? BackendInfo.domain!

        if user.isSelfUser, let selfClientID = user.selfClient()?.remoteIdentifier {
            self.selfClientID = selfClientID
        } else {
            selfClientID = nil
        }
    }

}

extension MLSUser: CustomStringConvertible {

    public var description: String {
        return "\(id)@\(domain)"
    }

}

// MARK: - Helper Extensions

private extension TimeInterval {

    var nanoseconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }

}

// sourcery: AutoMockable
public protocol ConversationEventProcessorProtocol {

    func processConversationEvents(_ events: [ZMUpdateEvent]) async
    func processPayload(_ payload: ZMTransportData)
}

actor GroupsBeingRepaired {
    var values = Set<MLSGroupID>()

    func contains(group: MLSGroupID) -> Bool {
        values.contains(group)
    }

    func insert(group: MLSGroupID) {
        values.insert(group)
    }

    func remove(group: MLSGroupID) {
        values.remove(group)
    }
}
