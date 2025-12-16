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

import Combine
import Foundation
import WireCoreCrypto
import WireFoundation
import WireLogging
import WireNetwork

// This is only used in tests, so it should be removed.
public protocol MLSServiceDelegate: AnyObject {

    func mlsServiceDidCommitPendingProposal(for groupID: MLSGroupID)
    func mlsServiceDidUpdateKeyMaterialForAllGroups()

}

/// This class is responsible for handling several MLS operations. See <doc:MLS> for more informations about MLS
///
/// The MLS operations covered by this class include:
/// - managing groups and subgroups (creating, joining, leaving)
/// - adding and removing members
/// - updating key material
/// - uploading key packages
/// - encrypting and decrypting messages
/// - processing welcome messages
/// - generating conference information for subconversations
/// - handling out-of-sync conversations
/// - observing epoch changes
/// - committing pending proposals
///
/// It uses the CoreCrypto framework to perform cryptographic operations, and interacts with core data and the backend

public final class MLSService: MLSServiceInterface {

    // MARK: - Properties

    private weak var context: NSManagedObjectContext?
    private var notificationContext: any NotificationContext
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    private let encryptionService: MLSEncryptionServiceInterface
    private let decryptionService: MLSDecryptionServiceInterface

    private let mlsActionExecutor: MLSActionExecutorProtocol
    private let staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol
    private let userDefaults: PrivateUserDefaults<Keys>
    private let logger = WireLogger.mls
    private let groupsBeingRepaired = GroupsBeingRepaired()
    private let featureRepository: LegacyFeatureRepositoryInterface
    private weak var mlsSyncDelegate: (any MLSSyncDelegate)?
    private weak var resetBrokenMLSConversationDelegate: (any ResetBrokenMLSConversationDelegate)?
    private let onEpochChangedSubject = PassthroughSubject<MLSGroupID, Never>()
    private var brokenGroupIDs: Set<MLSGroupID> = []
    private let localDomain: String?

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

    private let maxRetryAttempts = 3

    weak var delegate: MLSServiceDelegate?

    // MARK: - Life cycle

    public convenience init(
        context: NSManagedObjectContext,
        notificationContext: any NotificationContext,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        featureRepository: LegacyFeatureRepositoryInterface,
        userDefaults: UserDefaults,
        userID: UUID,
        localDomain: String?
    ) {
        self.init(
            context: context,
            notificationContext: notificationContext,
            coreCryptoProvider: coreCryptoProvider,
            staleKeyMaterialDetector: StaleMLSKeyDetector(context: context),
            userDefaults: userDefaults,
            actionsProvider: MLSActionsProvider(),
            userID: userID,
            featureRepository: featureRepository,
            localDomain: localDomain
        )
    }

    init(
        context: NSManagedObjectContext,
        notificationContext: any NotificationContext,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        encryptionService: MLSEncryptionServiceInterface? = nil,
        decryptionService: MLSDecryptionServiceInterface? = nil,
        mlsActionExecutor: MLSActionExecutorProtocol? = nil,
        staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol,
        userDefaults: UserDefaults,
        actionsProvider: MLSActionsProviderProtocol = MLSActionsProvider(),
        delegate: MLSServiceDelegate? = nil,
        userID: UUID,
        featureRepository: LegacyFeatureRepositoryInterface,
        subconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface =
            SubconversationGroupIDRepository(),
        localDomain: String?
    ) {
        self.context = context
        self.notificationContext = notificationContext
        self.coreCryptoProvider = coreCryptoProvider
        self.featureRepository = featureRepository
        self.mlsActionExecutor = mlsActionExecutor ?? MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: featureRepository
        )
        self.staleKeyMaterialDetector = staleKeyMaterialDetector
        self.actionsProvider = actionsProvider
        self.userDefaults = PrivateUserDefaults(userID: userID, storage: userDefaults)
        self.delegate = delegate
        self.subconversationGroupIDRepository = subconversationGroupIDRepository

        self.encryptionService = encryptionService ?? MLSEncryptionService(
            coreCryptoProvider: coreCryptoProvider
        )

        self.decryptionService = decryptionService ?? MLSDecryptionService(
            context: context,
            mlsActionExecutor: self.mlsActionExecutor,
            subconversationGroupIDRepository: subconversationGroupIDRepository
        )

        self.localDomain = localDomain
        schedulePeriodicKeyMaterialUpdateCheck()
        startObservingEpochs()
    }

    deinit {
        keyMaterialUpdateCheckTimer?.invalidate()
    }

    // MARK: - Sync delegate

    public func setSyncDelegate(_ delegate: any MLSSyncDelegate) {
        mlsSyncDelegate = delegate
    }

    public func setResetBrokenMLSConversationDelegate(
        _ delegate: any ResetBrokenMLSConversationDelegate
    ) {
        resetBrokenMLSConversationDelegate = delegate
    }

    // MARK: - Conference info for subconversations

    public func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) async throws -> MLSConferenceInfo {
        do {
            logger.info("generating conference info")

            let keyLength: UInt32 = 32

            return try await coreCrypto.perform {
                let epoch = try await $0.conversationEpoch(conversationId: subconversationGroupID.conversationId)

                let secretKey = try await $0.exportSecretKey(
                    conversationId: subconversationGroupID.conversationId,
                    keyLength: keyLength
                )

                let conversationMembers = try await $0.getClientIds(conversationId: parentGroupID.conversationId)
                    .compactMap { MLSClientID(data: $0.copyBytes()) }

                let subconversationMembers = try await $0
                    .getClientIds(conversationId: subconversationGroupID.conversationId)
                    .compactMap { MLSClientID(data: $0.copyBytes()) }

                let members = conversationMembers.map {
                    MLSConferenceInfo.Member(
                        id: $0,
                        isInSubconversation: subconversationMembers.contains($0)
                    )
                }

                return MLSConferenceInfo(
                    epoch: epoch,
                    keyData: secretKey.copyBytes(),
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
                try await $0.getClientIds(conversationId: subconversationGroupID.conversationId).compactMap {
                    MLSClientID(data: $0.copyBytes())
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
            .filter { $0.isOne(of: parentGroupID, subConversationGroupID) }
            .values
            .compactMap { [weak self] _ in
                try await self?.generateConferenceInfo(
                    parentGroupID: parentGroupID,
                    subconversationGroupID: subConversationGroupID
                )
            }.makeAsyncIterator()

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
                let context else {
                return
            }

            Task { [context] in
                let hasRegisteredMLSClient = await context
                    .perform { ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient == true }

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
            try await mlsActionExecutor.updateKeyMaterial(for: groupID)
            staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
        } catch {
            WireLogger.mls
                .warn(
                    "failed to update key material for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))"
                )
            throw error
        }
    }

    // MARK: - Group creation

    public enum MLSGroupCreationError: Error, Equatable {
        case failedToGetExternalSenders
        case failedToCreateGroup
        case invalidCiphersuite
    }

    public func establishGroup(
        for groupID: MLSGroupID,
        with users: [MLSUser],
        removalKeys: BackendMLSPublicKeys? = nil
    ) async throws -> MLSCipherSuite {
        guard let context else { throw MLSGroupCreationError.failedToCreateGroup }

        do {
            let ciphersuite = try await createGroup(for: groupID, removalKeys: removalKeys)
            let mlsSelfUser = await context.perform {
                let selfUser = ZMUser.selfUser(in: context)
                return MLSUser(from: selfUser, localDomain: self.localDomain)
            }
            // make sure we have the selfUser but only once
            let usersWithSelfUser = Set(users + [mlsSelfUser])
            try await addMembersToConversation(with: Array(usersWithSelfUser), for: groupID)
            return ciphersuite
        } catch {
            try await wipeGroup(groupID)
            throw error
        }
    }

    public func createGroup(
        for groupID: MLSGroupID,
        parentGroupID: MLSGroupID
    ) async throws -> MLSCipherSuite {
        let useCase = CreateMLSGroupUseCase(
            parentGroupID: parentGroupID,
            removalKeys: nil,
            defaultCipherSuite: await featureRepository.fetchMLS().config.defaultCipherSuite,
            coreCrypto: try await coreCrypto,
            staleKeyMaterialDetector: staleKeyMaterialDetector,
            actionsProvider: actionsProvider,
            notificationContext: notificationContext
        )
        return try await useCase.invoke(groupID: groupID)
    }

    public func createGroup(
        for groupID: MLSGroupID,
        removalKeys: BackendMLSPublicKeys? = nil
    ) async throws -> MLSCipherSuite {
        let useCase = CreateMLSGroupUseCase(
            parentGroupID: nil,
            removalKeys: removalKeys,
            defaultCipherSuite: await featureRepository.fetchMLS().config.defaultCipherSuite,
            coreCrypto: try await coreCrypto,
            staleKeyMaterialDetector: staleKeyMaterialDetector,
            actionsProvider: actionsProvider,
            notificationContext: notificationContext
        )
        return try await useCase.invoke(groupID: groupID)
    }

    public func createSelfGroup(for groupID: MLSGroupID) async throws -> MLSCipherSuite {
        do {
            guard let context else { throw MLSAddMembersError.noManagedObjectContext }
            let ciphersuite = try await createGroup(for: groupID)
            let mlsSelfUser = await context.perform {
                let selfUser = ZMUser.selfUser(in: context)
                return MLSUser(from: selfUser, localDomain: self.localDomain)
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

            if keyPackages.isEmpty {
                // CC does not accept empty keypackages in addMembers, but
                // when creating a group we still need to send a commit to backend
                // to inform we are in the group
                try await mlsActionExecutor.updateKeyMaterial(for: groupID)
            } else {
                try await mlsActionExecutor.addMembers(keyPackages, to: groupID)
            }
        } catch {
            logger
                .warn(
                    "failed to add members to group (\(groupID.safeForLoggingDescription)): \(String(describing: error))"
                )
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

        if !failedUsers.isEmpty {
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
            let clientIds = clientIds.compactMap(\.rawValue.utf8Data).map { ClientId(bytes: $0) }
            try await mlsActionExecutor.removeClients(clientIds, from: groupID)
        } catch {
            logger
                .warn(
                    "failed to remove members from group (\(groupID.safeForLoggingDescription)): \(String(describing: error))"
                )
            throw error
        }
    }

    // MARK: - Remove group

    public func wipeGroup(_ groupID: MLSGroupID) async throws {
        logger.info(
            "wiping group",
            attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
        )

        do {
            try await coreCrypto.perform { [self] in
                guard try await $0.conversationExists(
                    conversationId: groupID.conversationId
                ) else {
                    return logger.info(
                        "conversation doesn't exist, nothing to wipe..",
                        attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
                    )
                }
                try await $0.wipeConversation(
                    conversationId: groupID.conversationId
                )

                logger.info(
                    "wiped group",
                    attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
                )
            }
        } catch {
            logger.warn(
                "failed to wipe group \(String(describing: error))",
                attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
            )
            throw error
        }
    }

    // MARK: - Key packages

    enum MLSKeyPackagesError: Error {

        case failedToGenerateKeyPackages
        case failedToUploadKeyPackages
        case failedToCountUnclaimedKeyPackages
    }

    public func uploadKeyPackagesIfNeeded() async {
        logger.info("uploading key packages if needed")

        func logWarn(abortedWithReason reason: String) {
            logger.warn("aborting key packages upload: \(reason)")
        }

        guard await shouldQueryUnclaimedKeyPackagesCount() else { return }

        guard let context else {
            return logWarn(abortedWithReason: "missing context")
        }

        guard let clientID = await context.perform({ ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier })
        else {
            return logWarn(abortedWithReason: "failed to get client ID")
        }

        do {
            let ciphersuite = await featureRepository.fetchMLS().config.defaultCipherSuite
            let unclaimedKeyPackageCount = try await countUnclaimedKeyPackages(
                clientID: clientID,
                ciphersuite: MLSCipherSuite(rawValue: ciphersuite.rawValue),
                context: context.notificationContext
            )
            logger.info("there are \(unclaimedKeyPackageCount) unclaimed key packages")

            userDefaults.set(Date(), forKey: .keyPackageQueriedTime)
            guard unclaimedKeyPackageCount <= halfOfTargetUnclaimedKeyPackageCount else {
                logger.info("no need to upload new key packages yet")
                return
            }

            let amount = UInt32(targetUnclaimedKeyPackageCount)
            let keyPackages = try await generateKeyPackages(amountRequested: amount)
            try await uploadKeyPackages(
                clientID: clientID,
                keyPackages: keyPackages,
                context: context.notificationContext
            )
            logger.info("success: uploaded key packages for client \(clientID)")
        } catch {
            logger.warn("failed to upload key packages for client \(clientID). \(String(describing: error))")
        }
    }

    private func shouldQueryUnclaimedKeyPackagesCount() async -> Bool {
        do {
            let ciphersuite = await featureRepository.fetchMLS().config.defaultCipherSuite.coreCryptoCipherSuite
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

        if let hour = Calendar.current.dateComponents([.hour], from: storedDate, to: Date()).hour, hour > 24 {
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
        ciphersuite: MLSCipherSuite?,
        context: NotificationContext
    ) async throws -> Int {
        do {
            return try await actionsProvider.countUnclaimedKeyPackages(
                clientID: clientID,
                ciphersuite: ciphersuite,
                context: context
            )

        } catch {
            logger.warn("failed to fetch unclaimed key packages count with error: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToCountUnclaimedKeyPackages
        }
    }

    private func generateKeyPackages(amountRequested: UInt32) async throws -> [String] {
        logger.info("generating \(amountRequested) key packages")

        var keyPackages = [WireCoreCryptoUniffi.KeyPackage]()

        do {
            let ciphersuite = await featureRepository.fetchMLS().config.defaultCipherSuite.coreCryptoCipherSuite
            keyPackages = try await coreCrypto.perform {
                let e2eiIsEnabled = try await $0.e2eiIsEnabled(ciphersuite: ciphersuite)
                return try await $0.clientKeypackages(
                    ciphersuite: ciphersuite,
                    credentialType: e2eiIsEnabled ? .x509 : .basic,
                    amountRequested: amountRequested
                )
            }

        } catch {
            logger.warn("failed to generate new key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        if keyPackages.isEmpty {
            logger.warn("CoreCrypto generated empty key packages array")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        return keyPackages.map { $0.copyBytes().base64EncodedString() }
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

        } catch {
            logger.warn("failed to upload key packages for client (\(clientID)): \(String(describing: error))")
            throw MLSKeyPackagesError.failedToUploadKeyPackages
        }
    }

    // MARK: - Process welcome message

    public enum MLSWelcomeMessageProcessingError: Error {

        case failedToConvertMessageToBytes
        case failedToProcessMessage

    }
    
    public func externalSenderKey(groupID: MLSGroupID) async throws -> Data {
        return try await coreCrypto.perform { coreCrypto in
            try await coreCrypto.getExternalSender(conversationId: groupID.conversationId)
        }.copyBytes()
    }

    public func conversationExists(groupID: MLSGroupID) async throws -> Bool {

        logger.info("checking if group (\(groupID)) exists...")
        let result = try await coreCrypto.perform { coreCrypto in
            try await coreCrypto.conversationExists(conversationId: groupID.conversationId)
        }
        logger.info("... group (\(groupID)) " + (result ? "exists!" : "does not exist!"))
        return result
    }

    public func processWelcomeMessage(
        welcomeMessage: String,
        context: CoreCryptoContextProtocol?
    ) async throws -> MLSGroupID {
        try await decryptionService.processWelcomeMessage(
            welcomeMessage: welcomeMessage,
            context: context
        )
    }

    // MARK: - Joining conversations

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        guard let context else {
            logger.warn("MLSService is missing sync context")
            return
        }

        // TODO: [WPB-9029] jacob this looks wrong,
        // why would we create the MLS group if doesn't exist? We are about
        // to join it via external commit.
        if try await !conversationExists(groupID: groupID) {
            try await _ = createGroup(for: groupID)
        }

        let mlsUser = await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            return MLSUser(from: selfUser, localDomain: self.localDomain)
        }

        try await joinGroup(with: groupID)
        try await addMembersToConversation(with: [mlsUser], for: groupID)
    }

    public func joinGroup(with groupID: MLSGroupID) async throws {
        try await joinByExternalCommit(groupID: groupID)
    }

    typealias PendingJoin = (groupID: MLSGroupID, epoch: UInt64)

    public func establishPendingGroup(groupID: MLSGroupID) async throws {
        guard let context else {
            return
        }

        let conversation = await context.perform {
            ZMConversation.fetch(with: groupID, in: context)
        }

        guard let conversation else {
            throw MLSServiceError.conversationNotFound
        }

        try await internalEstablishPendingGroup(
            groupID: groupID,
            pendingGroup: conversation,
            context: context
        )

        await save(context)
    }

    private func internalEstablishPendingGroup(
        groupID: MLSGroupID,
        pendingGroup: ZMConversation,
        context: NSManagedObjectContext
    ) async throws {
        let mlsUsers = await context.perform {
            pendingGroup.localParticipants.map {
                MLSUser(from: $0, localDomain: self.localDomain)
            }
        }

        let ciphersuite = try await establishGroup(
            for: groupID,
            with: mlsUsers
        )

        await context.perform {
            pendingGroup.ciphersuite = ciphersuite
            pendingGroup.mlsStatus = .ready
        }
    }

    public func performPendingJoins() async throws {
        guard let context else {
            return
        }

        let pendingGroups = try await context.perform {
            try ZMConversation.fetchConversationsWithMLSGroupStatus(
                mlsGroupStatus: .pendingJoin,
                in: context
            )
        }

        logger.info("joining \(pendingGroups.count) group(s)")

        let needToSave = await withTaskGroup(of: Bool.self) { group in
            for pendingGroup in pendingGroups {
                group.addTask {
                    guard let mlsGroupID = await context.perform({ pendingGroup.mlsGroupID }) else {
                        return false
                    }

                    do {
                        let (epoch, isSelfConversation) = await context.perform {
                            (pendingGroup.epoch, pendingGroup.isSelfConversation)
                        }
                        let conversationExists = try await self.conversationExists(
                            groupID: mlsGroupID
                        )
                        let shouldEstablishGroup = epoch == 0 && isSelfConversation && !conversationExists

                        if shouldEstablishGroup {
                            try await self.internalEstablishPendingGroup(
                                groupID: mlsGroupID,
                                pendingGroup: pendingGroup,
                                context: context
                            )
                            return true
                        } else {
                            try await self.joinByExternalCommit(groupID: mlsGroupID)
                            return false
                        }
                    } catch {
                        WireLogger.mls.error(
                            "Failed to join pending group: \(error)",
                            attributes: [.mlsGroupID: mlsGroupID.safeForLoggingDescription]
                        )
                        return false
                    }
                }
            }

            var needToSave = false
            for await groupResult in group {
                needToSave = needToSave || groupResult
            }
            return needToSave
        }
        if needToSave {
            await save(context)
        }
    }

    private func save(_ context: NSManagedObjectContext) async {
        _ = await context.perform { [context] in
            context.saveOrRollback()
        }
    }

    public func reEstablishPendingGroup(groupID: MLSGroupID) async throws {
        guard let context else { return }

        let conversationInfo = await fetchConversationInfo(with: groupID, in: context)

        guard let conversationInfo else {
            throw MLSServiceError.conversationNotFound
        }

        try await actionsProvider.syncConversation(
            qualifiedID: conversationInfo.qualifiedID,
            context: context.notificationContext
        )

        let (conversation, epoch, lastGroupID) = await context.perform {
            let conversation = ZMConversation.fetch(
                with: conversationInfo.qualifiedID.uuid,
                domain: conversationInfo.qualifiedID.domain,
                in: context
            )
            return (conversation, conversation?.epoch, conversation?.mlsGroupID)
        }

        guard let conversation, let lastGroupID, let epoch else {
            throw MLSServiceError.conversationNotFound
        }

        let conversationExists = try await conversationExists(
            groupID: lastGroupID
        )

        let shouldEstablishGroup = epoch == 0 && !conversationExists

        if shouldEstablishGroup {
            try await internalEstablishPendingGroup(groupID: lastGroupID, pendingGroup: conversation, context: context)
        } else {
            try await joinByExternalCommit(groupID: lastGroupID)
        }

        await save(context)
    }

    // MARK: - Out-of-sync conversations

    public func repairOutOfSyncConversations() async throws {
        guard let context else { return }

        let outOfSyncConversationInfos = try await outOfSyncConversations(in: context)

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
                    self.logger
                        .warn(
                            "failed to repair out of sync conversation (\(conversationInfo.mlsGroupId.safeForLoggingDescription)). error: \(String(reflecting: error))"
                        )
                }
            }
        }
    }

    public func fetchAndRepairGroupIfPossible(with groupID: MLSGroupID) async {
        await launchGroupRepairTaskIfNotInProgress(for: groupID) {
            await self.fetchAndRepairGroup(with: groupID, shouldPerformIncrementalSync: true)
        }
    }

    public func fetchAndRepairGroup(
        with groupID: MLSGroupID,
        shouldPerformIncrementalSync: Bool
    ) async {
        if let subgroupInfo = await subconversationGroupIDRepository.findSubgroupTypeAndParentID(for: groupID) {
            await fetchAndRepairSubgroup(parentGroupID: subgroupInfo.parentID)
        } else {
            await fetchAndRepairParentGroup(
                with: groupID,
                shouldPerformIncrementalSync: shouldPerformIncrementalSync
            )
        }
    }

    private func fetchAndRepairParentGroup(
        with groupID: MLSGroupID,
        shouldPerformIncrementalSync: Bool
    ) async {
        guard let context else {
            return
        }

        do {
            logger.info("repairing out of sync conversation... (\(groupID.safeForLoggingDescription))")

            if shouldPerformIncrementalSync {
                // In case of `WrongEpoch` error, local and remote epochs have diverged so we may have missed events.
                // This ensures we're on the latest state.
                try await mlsSyncDelegate?.recoverWithIncrementalSync()
            }

            guard let conversationInfo = await fetchConversationInfo(
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

            guard try await isConversationOutOfSync(
                conversationInfo.conversation,
                subgroup: nil,
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
            logger
                .warn(
                    "failed to repair conversation (\(groupID.safeForLoggingDescription)). error: \(String(describing: error))"
                )
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
        guard let context else { return }

        do {
            logger.info("repairing out of sync subgroup... (parent: \(parentGroupID.safeForLoggingDescription))")

            guard let conversationInfo = await fetchConversationInfo(
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

            guard try await isConversationOutOfSync(
                conversationInfo.conversation,
                subgroup: subgroup,
                context: context
            ) else {
                logger
                    .info(
                        "subgroup is not out of sync (parent: \(parentGroupID.safeForLoggingDescription), subgroup: \(subgroup.groupID.safeForLoggingDescription))"
                    )
                return
            }

            try await joinSubgroup(
                parentID: parentGroupID,
                subgroupID: subgroup.groupID
            )

            logger
                .info(
                    "repaired out of sync subgroup! (parent: \(parentGroupID.safeForLoggingDescription), subgroup: \(subgroup.groupID.safeForLoggingDescription))"
                )
        } catch {
            logger
                .warn(
                    "failed to repair subgroup (parent: \(parentGroupID.safeForLoggingDescription)). error: \(String(describing: error))"
                )
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

    private func outOfSyncConversations(in context: NSManagedObjectContext) async throws
        -> [OutOfSyncConversationInfo] {

        let conversations = try await coreCrypto.perform { coreCrypto in

            let allMLSConversations = await context.perform { ZMConversation.fetchMLSConversations(in: context) }

            var outOfSyncConversations = [ZMConversation]()
            for conversation in allMLSConversations {
                guard await self.isConversationOutOfSync(conversation, coreCrypto: coreCrypto, context: context)
                else { continue }
                outOfSyncConversations.append(conversation)
            }
            return outOfSyncConversations
        }
        return await context.perform {
            conversations.compactMap {
                if let groupId = $0.mlsGroupID {
                    (groupId, $0)
                } else {
                    nil
                }
            }
        }
    }

    private func isConversationOutOfSync(
        _ conversation: ZMConversation,
        subgroup: MLSSubgroup? = nil,
        coreCrypto: CoreCryptoContextProtocol,
        context: NSManagedObjectContext
    ) async -> Bool {
        var groupID: MLSGroupID?
        var epoch: UInt64?

        await context.perform {
            if let subgroup {
                groupID = subgroup.groupID
                epoch = UInt64(subgroup.epoch)
            } else {
                groupID = conversation.mlsGroupID
                epoch = conversation.epoch
            }
        }
        guard let groupID, let epoch else { return false }

        do {
            let localEpoch = try await coreCrypto.conversationEpoch(conversationId: groupID.conversationId)

            logger.info("epochs(remote: \(epoch), local: \(localEpoch)) for (\(groupID.safeForLoggingDescription))")
            return localEpoch < epoch
        } catch {
            logger
                .info(
                    "cannot resolve conversation epoch \(String(describing: error)) for (\(groupID.safeForLoggingDescription))"
                )
            return false
        }
    }

    private func isConversationOutOfSync(
        _ conversation: ZMConversation,
        subgroup: MLSSubgroup?,
        context: NSManagedObjectContext
    ) async throws -> Bool {
        try await coreCrypto.perform {
            await self.isConversationOutOfSync(
                conversation,
                subgroup: subgroup,
                coreCrypto: $0,
                context: context
            )
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

    enum MLSServiceError: Error {
        case conversationNotFound
    }

    private func internalJoinByExternalCommit(
        parentID: MLSGroupID,
        subgroupIDAndType: (MLSGroupID, SubgroupType)?
    ) async throws {
        let subgroupID = subgroupIDAndType?.0
        let subgroupType = subgroupIDAndType?.1

        let logInfo =
            "parent: \(parentID.safeForLoggingDescription), subgroup: \(String(describing: subgroupID?.safeForLoggingDescription)), subgroup type: \(String(describing: subgroupType))"

        do {
            logger.info("sending external commit to join group (\(logInfo))")

            guard let context else { return }

            guard let parentConversationInfo = await fetchConversationInfo(
                with: parentID,
                in: context
            ) else {
                throw MLSServiceError.conversationNotFound
            }

            let groupInfo = try await actionsProvider.fetchConversationGroupInfo(
                conversationId: parentConversationInfo.qualifiedID.uuid,
                domain: parentConversationInfo.qualifiedID.domain,
                subgroupType: subgroupType,
                context: context.notificationContext
            )

            if let subgroupID {
                try await mlsActionExecutor.joinGroup(
                    subgroupID,
                    groupInfo: groupInfo
                )
            } else {
                try await mlsActionExecutor.joinGroup(
                    parentID,
                    groupInfo: groupInfo
                )

                await context.perform {
                    parentConversationInfo.conversation.mlsStatus = .ready
                }
            }

            logger.info("success: joined group with external commit (\(logInfo))")

        } catch {
            logger.warn("failed to send external commit to join group (\(logInfo)): \(String(describing: error))")
            throw error
        }
    }

    private func fetchConversationInfo(
        with groupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async -> (conversation: ZMConversation, qualifiedID: QualifiedID, groupID: MLSGroupID, epoch: UInt64)? {

        var conversation: ZMConversation?
        var qualifiedID: QualifiedID?
        var epoch: UInt64 = 0
        await context.perform {
            conversation = ZMConversation.fetch(with: groupID, in: context)
            qualifiedID = conversation?.qualifiedID
            epoch = conversation?.epoch ?? 0
        }

        guard
            let conversation,
            let qualifiedID
        else {
            return nil
        }

        return (conversation, qualifiedID, groupID, epoch)
    }

    // MARK: - Encrypt message

    public func encrypt(
        message: Data,
        for groupID: MLSGroupID
    ) async throws -> Data {
        try await encryptionService.encrypt(
            message: message,
            for: groupID
        )
    }

    // MARK: - Decrypting Message

    public func decrypt(
        message: String,
        for groupID: MLSGroupID,
        subconversationType: SubgroupType?,
        context: CoreCryptoContextProtocol?
    ) async throws -> [MLSDecryptResult] {
        typealias DecryptionError = MLSDecryptionService.MLSMessageDecryptionError

        do {
            return try await decryptionService.decrypt(
                message: message,
                for: groupID,
                subconversationType: subconversationType,
                context: context
            )
        } catch DecryptionError.wrongEpoch {
            Task.detached { [self] in
                // ⚠️ Important:
                // Run in detached Task to avoid deadlock:
                // `fetchAndRepairGroupIfPossible` internally triggers quick sync via `recoverWithQuickSync()`.
                // If this is called during an ongoing quick sync, awaiting it directly would deadlock.
                await fetchAndRepairGroupIfPossible(with: groupID)
            }
            throw DecryptionError.wrongEpoch
        } catch {
            throw error
        }
    }

    // MARK: - Pending proposals

    enum MLSCommitPendingProposalsError: Error {

        case failedToCommitPendingProposals

    }

    private var lastExecutionTime = Date.distantPast
    private let throttleInterval: TimeInterval = 2.0 // 2 seconds throttle

    public func commitPendingProposalsIfNeeded() async {
        let now = Date.now

        guard now.timeIntervalSince(lastExecutionTime) > throttleInterval else {
            return // Ignore call if within the throttle period
        }

        lastExecutionTime = now

        await commitPendingProposals()
    }

    func commitPendingProposals() async {
        guard let context else {
            return
        }

        logger.info("committing any scheduled pending proposals")

        let groupsWithPendingCommits = await sortedGroupsWithPendingCommits()

        logger.info("\(groupsWithPendingCommits.count) groups with scheduled pending proposals")

        // Committing proposals for each group is independent and should not wait for
        // each other.
        await withTaskGroup(of: Void.self) { taskGroup in
            for (groupID, timestamp) in groupsWithPendingCommits {
                taskGroup.addTask { [self] in
                    do {
                        if timestamp.isInThePast {
                            logger.info(
                                "commit scheduled in the past, committing...",
                                attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
                            )
                            try await commitPendingProposals(in: groupID)
                        } else {
                            logger.info(
                                "commit scheduled in the future, waiting...",
                                attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
                            )

                            let timeIntervalSinceNow = timestamp.timeIntervalSinceNow
                            if timeIntervalSinceNow > 0 {
                                try await Task.sleep(nanoseconds: timeIntervalSinceNow.nanoseconds)
                            }

                            let isSelfAnActiveMember = await context.perform {
                                let conversation = ZMConversation.fetch(with: groupID, in: context)
                                return conversation?.isSelfAnActiveMember ?? false
                            }

                            guard isSelfAnActiveMember else {
                                logger.info(
                                    "cancelling commit as the user is no longer a member",
                                    attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
                                )
                                return
                            }

                            logger.info(
                                "scheduled commit is ready, committing...",
                                attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
                            )
                            try await commitPendingProposals(in: groupID)
                        }

                    } catch {
                        logger.error(
                            "failed to commit pending proposals: \(String(describing: error))",
                            attributes: [.mlsGroupID: groupID.safeForLoggingDescription]
                        )
                    }
                }
            }
        }
        logger.debug("end any scheduled pending proposals")
    }

    private func sortedGroupsWithPendingCommits() async -> [(MLSGroupID, Date)] {
        guard let context else {
            return []
        }

        var result: [(MLSGroupID, Date)] = []

        let groupIDsAndProposalDatesArray: [(MLSGroupID, Date)] = await context.perform {
            ZMConversation.fetchConversationsWithPendingProposals(
                in: context
            ).filter(
                \.isSelfAnActiveMember
            ).compactMap {
                guard
                    let groupID = $0.mlsGroupID,
                    let proposalDate = $0.commitPendingProposalDate
                else {
                    return nil
                }
                return (groupID, proposalDate)
            }
        }

        for (groupID, timestamp) in groupIDsAndProposalDatesArray {
            // The pending proposal will always fail and cause
            // recovery too many recovery syncs.
            guard !brokenGroupIDs.contains(groupID) else {
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
        guard let context else { return false }

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
            try await mlsActionExecutor.commitPendingProposals(in: groupID)
            clearPendingProposalCommitDate(for: groupID)
            delegate?.mlsServiceDidCommitPendingProposal(for: groupID)
        } catch {
            logger
                .info(
                    "failed to commit pending proposals in \(groupID.safeForLoggingDescription): \(String(describing: error))"
                )
            throw error
        }
    }

    private func clearPendingProposalCommitDate(for groupID: MLSGroupID) {
        guard let context else {
            return
        }

        context.performAndWait {
            let conversation = ZMConversation.fetch(with: groupID, in: context)
            conversation?.commitPendingProposalDate = nil
        }
    }

    // MARK: - Error recovery

    enum MLSRetryError: Error, Equatable {
        case retryLimitReached
        case nonRecoverableError(_ reason: String)
    }

    enum RecoveryStrategy: Equatable {

        /// Perform a quick sync, then retry the action in its entirety.
        ///
        /// Core Crypto can not automatically recover by itself. It needs
        /// to process incoming handshake messages then generate a new commit.

        case retryAfterQuickSync

        /// Repair (re-join) the group and retry the action
        ///
        /// We may have missed a few commits so we will rejoin the group
        /// and try again.

        case retryAfterRepairingGroup

        /// Add the missing users to the group, then retry the action in
        /// its entirety.
        ///
        /// It's possible that the membership of the local group does not
        /// match the membership of the conversation according to the backend.
        /// This needs correcting so that all members will receive the commit.

        case retryAfterAddingMissingUsers(Set<QualifiedID>)

        /// Reset the mls group.
        ///
        /// Some bugs led to MLS getting broken which then required
        /// an explicit fix.

        case resetBrokenMLSConversation

        /// Abort the action and inform the user.
        ///
        /// There is no way to automatically recover from the error.

        case giveUp

        init(from reason: String) {
            guard let error = try? JSONDecoder().decode(
                MLSTransportError.self,
                from: Data(reason.utf8)
            ) else {
                self = .giveUp
                return
            }

            switch error {
            case .mlsClientMismatch, .mlsCommitMissingReferences:
                self = .retryAfterQuickSync
            case .mlsStaleMessage:
                self = .retryAfterRepairingGroup
            case .mlsInvalidLeafNodeIndex, .mlsInvalidLeafNodeSignature:
                self = .resetBrokenMLSConversation
            case let .groupOutOfSync(missingUsers):
                self = .retryAfterAddingMissingUsers(missingUsers)
            default:
                self = .giveUp
            }
        }

    }

    private func retryOnCommitFailure(
        for groupID: MLSGroupID,
        operation: @escaping () async throws -> Void,
        retryCount: Int = 0
    ) async throws {
        let logAttributes: LogAttributes = [
            .public: true,
            .mlsGroupID: groupID.safeForLoggingDescription
        ]

        do {
            try await operation()
        } catch let CoreCryptoError.Mls(.MessageRejected(reason: reason)) {
            switch RecoveryStrategy(from: reason) {
            case .retryAfterQuickSync:
                logger.warn(
                    "failed to send commit, syncing then retrying operation...",
                    attributes: logAttributes
                )
                try await mlsSyncDelegate?.recoverWithIncrementalSync()
                logger.info(
                    "sync finished, retrying operation...",
                    attributes: logAttributes
                )

                guard retryCount <= maxRetryAttempts else {
                    // If MLS conversation reset is DISABLED we quarantine the group to avoid repeated commit attempts
                    // otherwise assume that things will sort themselves out through conversation reset.
                    let feature = await featureRepository.fetchAllowedGlobalOperations()
                    if feature.status == .disabled || feature.config.mlsConversationReset == false {
                        brokenGroupIDs.insert(groupID)
                    }

                    throw MLSRetryError.retryLimitReached
                }

                var currentRetryCount = retryCount
                currentRetryCount += 1

                try await retryOnCommitFailure(for: groupID, operation: operation, retryCount: currentRetryCount)

            case .retryAfterRepairingGroup:
                logger.warn(
                    "failed to send commit, repairing group then retrying operation...",
                    attributes: logAttributes
                )
                await fetchAndRepairGroup(
                    with: groupID,
                    shouldPerformIncrementalSync: true
                )

                logger.info(
                    "repair finished, retrying operation...",
                    attributes: logAttributes
                )
                try await operation()

            case let .retryAfterAddingMissingUsers(missingUsers):
                guard retryCount <= maxRetryAttempts else {
                    logger.error(
                        "failed to send commit due to missing users and reached max attempts",
                        attributes: logAttributes
                    )
                    throw MLSRetryError.retryLimitReached
                }

                logger.warn(
                    "failed to send commit due to missing users. Adding users then retrying operation - attempt: \(retryCount)...",
                    attributes: logAttributes
                )

                let users = missingUsers.map {
                    MLSUser($0, selfClientID: nil)
                }

                // It's important to call the internal method because
                // we don't want to re-enter the commit failure handling
                // again for this action, otherwise we may end up in a loop.
                try await internalAddMembersToConversation(
                    with: users,
                    for: groupID
                )

                try await retryOnCommitFailure(
                    for: groupID,
                    operation: operation,
                    retryCount: retryCount + 1
                )

            case .resetBrokenMLSConversation:
                let feature = await featureRepository.fetchAllowedGlobalOperations()
                guard feature.status == .enabled,
                      feature.config.mlsConversationReset == true
                else {
                    logger.info(
                        "no need to apply recovery strategy for reset broken MLS conversation, FF is OFF",
                        attributes: logAttributes
                    )
                    brokenGroupIDs.insert(groupID)
                    throw MLSRetryError.nonRecoverableError(reason)
                }

                logger.info(
                    "Handling reset broken MLS conversation recovery strategy...",
                    attributes: logAttributes
                )
                var epoch: UInt64 = 0
                if let context {
                    epoch = await fetchConversationInfo(with: groupID, in: context)?.epoch ?? 0
                }
                await resetBrokenMLSConversationDelegate?.didCatchBrokenMLSConversation(groupID: groupID, epoch: epoch)
                brokenGroupIDs.remove(groupID)

            case .giveUp:
                logger.warn(
                    "failed to send commit, giving up...",
                    attributes: logAttributes
                )
                throw MLSRetryError.nonRecoverableError(reason)
            }
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
            logger
                .error(
                    "failed to create or join subgroup in parent conversation (\(parentQualifiedID)): \(String(describing: error))"
                )
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
            _ = try await createGroup(for: id, parentGroupID: parentID)
            try await updateKeyMaterial(for: id)
        } catch {
            logger
                .error(
                    "failed to create subgroup with id (\(id.safeForLoggingDescription)): \(String(describing: error))"
                )
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
            context: notificationContext
        )
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
            logger
                .info(
                    "joining subgroup (parent: \(parentID.safeForLoggingDescription), subgroup: \(subgroupID.safeForLoggingDescription))"
                )
            try await joinSubgroupByExternalCommit(
                parentID: parentID,
                subgroupID: subgroupID,
                subgroupType: .conference
            )
        } catch {
            logger
                .error(
                    "failed to join subgroup (parent: \(parentID.safeForLoggingDescription), subgroup: \(subgroupID.safeForLoggingDescription)): \(String(describing: error))"
                )
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

        if let subConversationGroupID = await subconversationGroupIDRepository.fetchSubconversationGroupID(
            forType: subconversationType,
            parentGroupID: parentGroupID
        ),
            try await conversationExists(groupID: subConversationGroupID) {
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
                try await $0.wipeConversation(conversationId: subconversationGroupID.conversationId)
            }
        } catch {
            logger
                .error(
                    "failed to leave subconversation (\(subconversationType)) with parent (\(parentQualifiedID)): \(String(describing: error))"
                )
            throw error
        }
    }

    // MARK: - Epoch

    public func startObservingEpochs() {
        Task {
            await coreCryptoProvider.registerEpochObserver(self)
        }
    }

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChangedSubject.eraseToAnyPublisher()
    }

    public func epochChanged(conversationId: WireCoreCryptoUniffi.ConversationId, epoch: UInt64) async throws {
        onEpochChangedSubject.send(MLSGroupID(conversationId))
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
        guard let context else {
            assertionFailure("MLSService.context is nil")
            return
        }

        let groupConversations = try await context.perform {
            try ZMConversation.fetchAllTeamGroupConversations(messageProtocol: .proteus, in: context)
        }
        for conversation in groupConversations {

            let (qualifiedID, members) = await context.perform {
                (
                    conversation.qualifiedID,
                    conversation.localParticipants.map { MLSUser(from: $0, localDomain: self.localDomain) }
                )
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

                _ = try await createGroup(for: mlsGroupID)

                do {

                    // update keying material and send commit bundle to the backend
                    try await internalUpdateKeyMaterial(for: mlsGroupID)

                    // add all participants (all clients) to the group
                    try await addMembersToConversation(with: members, for: mlsGroupID)

                } catch SendMLSMessageFailure.mlsStaleMessage {

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

extension MLSService: EpochObserver {}

// MARK: - Helper types

public struct MLSUser: Equatable, Hashable {

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

    public init(
        from user: ZMUser,
        localDomain: String?
    ) {
        self.id = user.remoteIdentifier
        self.domain = if let domain = user.domain, !domain.isEmpty { domain } else { localDomain! }

        if user.isSelfUser, let selfClientID = user.selfClient()?.remoteIdentifier {
            self.selfClientID = selfClientID
        } else {
            self.selfClientID = nil
        }
    }

}

extension MLSUser: CustomStringConvertible {

    public var description: String {
        "\(id)@\(domain)"
    }

}

// MARK: - Helper Extensions

private extension TimeInterval {

    var nanoseconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }

}

// sourcery: AutoMockable
public protocol LegacyConversationEventProcessorProtocol {

    /// Decodes event's payload and transform it to local model
    func processConversationEvents(_ events: [ZMUpdateEvent]) async
    /// Process the events and perform a save on syncContext
    func processAndSaveConversationEvents(_ events: [ZMUpdateEvent]) async
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
