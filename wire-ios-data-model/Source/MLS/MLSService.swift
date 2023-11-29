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

public protocol MLSServiceInterface: MLSEncryptionServiceInterface, MLSDecryptionServiceInterface {

    func uploadKeyPackagesIfNeeded()

    func createSelfGroup(for groupID: MLSGroupID)

    func joinGroup(with groupID: MLSGroupID) async throws

    /// Join group after creating it if needed
    func joinNewGroup(with groupID: MLSGroupID) async throws

    func createGroup(for groupID: MLSGroupID) throws

    func conversationExists(groupID: MLSGroupID) -> Bool

    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws

    func registerPendingJoin(_ group: MLSGroupID)

    func performPendingJoins()

    func wipeGroup(_ groupID: MLSGroupID) throws

    func commitPendingProposals() async throws

    func commitPendingProposals(in groupID: MLSGroupID) async throws

    func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID

    func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) throws -> MLSConferenceInfo

    func onConferenceInfoChange(
        parentGroupID: MLSGroupID,
        subConversationGroupID: MLSGroupID
    ) -> AnyPublisher<MLSConferenceInfo, Never>

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

    func generateNewEpoch(groupID: MLSGroupID) async throws

    func subconversationMembers(for subconversationGroupID: MLSGroupID) throws -> [MLSClientID]

    func repairOutOfSyncConversations()

    func fetchAndRepairGroup(with groupID: MLSGroupID) async

    /// Migrate proteus team group conversations to MLS

    func startProteusToMLSMigration() async throws

}

public protocol MLSServiceDelegate: AnyObject {

    func mlsServiceDidCommitPendingProposal(for groupID: MLSGroupID)
    func mlsServiceDidUpdateKeyMaterialForAllGroups()

}

public final class MLSService: MLSServiceInterface {

    // MARK: - Properties

    private weak var context: NSManagedObjectContext?
    private let coreCrypto: SafeCoreCryptoProtocol

    private let encryptionService: MLSEncryptionServiceInterface
    private let decryptionService: MLSDecryptionServiceInterface

    private let mlsActionExecutor: MLSActionExecutorProtocol
    private let conversationEventProcessor: ConversationEventProcessorProtocol
    private let staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol
    private let userDefaults: UserDefaults
    private let logger = WireLogger.mls
    private var groupsPendingJoin = Set<MLSGroupID>()
    private let groupsBeingRepaired = GroupsBeingRepaired()

    private let syncStatus: SyncStatusProtocol

    var backendPublicKeys = BackendMLSPublicKeys()
    var pendingProposalCommitTimers = [MLSGroupID: Timer]()

    let targetUnclaimedKeyPackageCount = 100
    let actionsProvider: MLSActionsProviderProtocol

    private let subconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface

    var lastKeyMaterialUpdateCheck = Date.distantPast
    var keyMaterialUpdateCheckTimer: Timer?

    // The number of days to wait until refreshing the key material for a group.

    private static var keyMaterialRefreshIntervalInDays: UInt {
        // To ensure that a group's key material does not exceed its maximum age,
        // refresh pre-emptively so that it doesn't go stale while the user is offline.
        return keyMaterialMaximumAgeInDays - backendMessageHoldTimeInDays
    }

    // The maximum age of a group's key material before it's considered stale.

    private static let keyMaterialMaximumAgeInDays: UInt = 90

    // The number of days the backend will hold a message.

    private static let backendMessageHoldTimeInDays: UInt = 28

    weak var delegate: MLSServiceDelegate?

    // MARK: - Life cycle

    public convenience init(
        context: NSManagedObjectContext,
        coreCrypto: SafeCoreCryptoProtocol,
        conversationEventProcessor: ConversationEventProcessorProtocol,
        userDefaults: UserDefaults,
        syncStatus: SyncStatusProtocol
    ) {
        self.init(
            context: context,
            coreCrypto: coreCrypto,
            conversationEventProcessor: conversationEventProcessor,
            staleKeyMaterialDetector: StaleMLSKeyDetector(
                refreshIntervalInDays: Self.keyMaterialRefreshIntervalInDays,
                context: context
            ),
            userDefaults: userDefaults,
            actionsProvider: MLSActionsProvider(),
            syncStatus: syncStatus
        )
    }

    init(
        context: NSManagedObjectContext,
        coreCrypto: SafeCoreCryptoProtocol,
        encryptionService: MLSEncryptionServiceInterface? = nil,
        decryptionService: MLSDecryptionServiceInterface? = nil,
        mlsActionExecutor: MLSActionExecutorProtocol? = nil,
        conversationEventProcessor: ConversationEventProcessorProtocol,
        staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol,
        userDefaults: UserDefaults,
        actionsProvider: MLSActionsProviderProtocol = MLSActionsProvider(),
        delegate: MLSServiceDelegate? = nil,
        syncStatus: SyncStatusProtocol,
        subconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface = SubconversationGroupIDRepository()
    ) {
        self.context = context
        self.coreCrypto = coreCrypto
        self.mlsActionExecutor = mlsActionExecutor ?? MLSActionExecutor(
            coreCrypto: coreCrypto,
            context: context,
            actionsProvider: actionsProvider
        )
        self.conversationEventProcessor = conversationEventProcessor
        self.staleKeyMaterialDetector = staleKeyMaterialDetector
        self.actionsProvider = actionsProvider
        self.userDefaults = userDefaults
        self.delegate = delegate
        self.syncStatus = syncStatus
        self.subconversationGroupIDRepository = subconversationGroupIDRepository

        self.encryptionService = encryptionService ?? MLSEncryptionService(coreCrypto: coreCrypto)
        self.decryptionService = decryptionService ?? MLSDecryptionService(
            context: context,
            coreCrypto: coreCrypto,
            subconversationGroupIDRepository: subconversationGroupIDRepository
        )

        do {
            try coreCrypto.perform { try $0.setCallbacks(callbacks: CoreCryptoCallbacksImpl()) }
        } catch {
            logger.error("failed to set callbacks: \(String(describing: error))")
        }

        generateClientPublicKeysIfNeeded()
        uploadKeyPackagesIfNeeded()
        fetchBackendPublicKeys()
        updateKeyMaterialForAllStaleGroupsIfNeeded()
        schedulePeriodicKeyMaterialUpdateCheck()
    }

    deinit {
        keyMaterialUpdateCheckTimer?.invalidate()
    }

    // MARK: - Public keys

    private func generateClientPublicKeysIfNeeded() {
        guard
            let context = context,
            let selfClient = ZMUser.selfUser(in: context).selfClient()
        else {
            return
        }

        var keys = selfClient.mlsPublicKeys

        do {
            if keys.ed25519 == nil {
                logger.info("generating ed25519 public key")
                let keyBytes = try coreCrypto.perform { try $0.clientPublicKey(ciphersuite: defaultCipherSuite.rawValue) }
                let keyData = Data(keyBytes)
                keys.ed25519 = keyData.base64EncodedString()
            }
        } catch {
            logger.error("failed to generate public keys: \(String(describing: error))")
        }

        selfClient.mlsPublicKeys = keys
        context.saveOrRollback()
    }

    private func fetchBackendPublicKeys() {
        logger.info("fetching backend public keys")

        guard let notificationContext = context?.notificationContext else {
            logger.warn("can't fetch backend public keys: notification context is missing")
            return
        }

        Task {
            do {
                backendPublicKeys = try await actionsProvider.fetchBackendPublicKeys(in: notificationContext)
            } catch {
                logger.warn("failed to fetch backend public keys: \(String(describing: error))")
            }
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
    ) throws -> MLSConferenceInfo {
        do {
            logger.info("generating conference info")

            let keyLength: UInt32 = 32

            return try coreCrypto.perform {
                let epoch = try $0.conversationEpoch(conversationId: subconversationGroupID.bytes)

                let keyData = try $0.exportSecretKey(
                    conversationId: subconversationGroupID.bytes,
                    keyLength: keyLength
                ).data

                let conversationMembers = try $0.getClientIds(conversationId: parentGroupID.bytes)
                    .compactMap { MLSClientID(data: $0.data) }

                let subconversationMembers = try $0.getClientIds(conversationId: subconversationGroupID.bytes)
                    .compactMap { MLSClientID(data: $0.data) }

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

    public func subconversationMembers(for subconversationGroupID: MLSGroupID) throws -> [MLSClientID] {
        do {
            return try coreCrypto.perform {
                return try $0.getClientIds(conversationId: subconversationGroupID.bytes).compactMap {
                    MLSClientID(data: $0.data)
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
    ) -> AnyPublisher<MLSConferenceInfo, Never> {
        return onEpochChanged().filter {
            $0.isOne(of: parentGroupID, subConversationGroupID)
        }.compactMap { [weak self] _ in
            try? self?.generateConferenceInfo(
                parentGroupID: parentGroupID,
                subconversationGroupID: subConversationGroupID
            )
        }.eraseToAnyPublisher()
    }

    // MARK: - Update key material

    private func schedulePeriodicKeyMaterialUpdateCheck() {
        keyMaterialUpdateCheckTimer?.invalidate()
        keyMaterialUpdateCheckTimer = Timer.scheduledTimer(
            withTimeInterval: .oneDay,
            repeats: true
        ) { [weak self] _ in
            self?.updateKeyMaterialForAllStaleGroupsIfNeeded()
        }
    }

    private func updateKeyMaterialForAllStaleGroupsIfNeeded() {
        guard lastKeyMaterialUpdateCheck.ageInDays >= 1 else { return }

        Task {
            await updateKeyMaterialForAllStaleGroups()
            lastKeyMaterialUpdateCheck = Date()
            delegate?.mlsServiceDidUpdateKeyMaterialForAllGroups()
        }
    }

    private func updateKeyMaterialForAllStaleGroups() async {
        Logging.mls.info("beginning to update key material for all stale groups")

        let staleGroups = staleKeyMaterialDetector.groupsWithStaleKeyingMaterial

        Logging.mls.info("found \(staleGroups.count) groups with stale key material")

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
            Logging.mls.info("updating key material for group (\(groupID.safeForLoggingDescription))")
            let events = try await mlsActionExecutor.updateKeyMaterial(for: groupID)
            staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
            conversationEventProcessor.processConversationEvents(events)
        } catch {
            Logging.mls.warn("failed to update key material for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Group creation

    enum MLSGroupCreationError: Error, Equatable {
        case failedToCreateGroup
    }

    /// Create an MLS group with the given group id.
    ///
    /// - Parameters:
    ///   - groupID the id representing the MLS group.
    ///
    /// - Throws:
    ///   - MLSGroupCreationError if the group could not be created.

    public func createGroup(for groupID: MLSGroupID) throws {
        logger.info("creating group for id: \(groupID.safeForLoggingDescription)")

        do {
            let config = ConversationConfiguration(
                ciphersuite: CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519.rawValue,
                externalSenders: backendPublicKeys.ed25519Keys,
                custom: .init(keyRotationSpan: nil, wirePolicy: nil)
            )

            try coreCrypto.perform {
                try $0.createConversation(
                    conversationId: groupID.bytes,
                    creatorCredentialType: .basic,
                    config: config
                )
            }
        } catch let error {
            logger.warn("failed to create group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw MLSGroupCreationError.failedToCreateGroup
        }

        staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
    }

    public func createSelfGroup(for groupID: MLSGroupID) {
        guard let context = context else {
            return
        }

        do {
            try createGroup(for: groupID)
            let selfUser = ZMUser.selfUser(in: context)
            let mlsSelfUser = MLSUser(from: selfUser)

            Task {
                do {
                    try await addMembersToConversation(with: [mlsSelfUser], for: groupID)
                } catch MLSAddMembersError.noInviteesToAdd {
                    logger.debug("createConversation noInviteesToAdd, updateKeyMaterial")
                    try await updateKeyMaterial(for: groupID)
                }
            }
        } catch {
            logger.error("create group for self conversation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Add member

    enum MLSAddMembersError: Error {

        case noMembersToAdd
        case noInviteesToAdd
        case failedToClaimKeyPackages

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
            let keyPackages = try await claimKeyPackages(for: users)
            let invitees = keyPackages.map(Invitee.init(from:))

            guard invitees.count > 0 else {
                throw MLSAddMembersError.noInviteesToAdd
            }

            let events = try await mlsActionExecutor.addMembers(invitees, to: groupID)
            conversationEventProcessor.processConversationEvents(events)
        } catch {
            logger.warn("failed to add members to group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    private func claimKeyPackages(for users: [MLSUser]) async throws -> [KeyPackage] {
        logger.info("claiming key packages for users: \(users)")
        do {
            guard let context = context else { return [] }

            var result = [KeyPackage]()

            for try await keyPackages in claimKeyPackages(for: users, in: context) {
                result.append(contentsOf: keyPackages)
            }

            return result
        } catch let error {
            logger.warn("failed to claim key packages: \(String(describing: error))")
            throw MLSAddMembersError.failedToClaimKeyPackages
        }
    }

    private func claimKeyPackages(
        for users: [MLSUser],
        in context: NSManagedObjectContext
    ) -> AsyncThrowingStream<([KeyPackage]), Error> {
        var index = 0

        return AsyncThrowingStream { [actionsProvider] in
            guard let user = users.element(atIndex: index) else { return nil }

            index += 1

            return try await actionsProvider.claimKeyPackages(
                userID: user.id,
                domain: user.domain,
                excludedSelfClientID: user.selfClientID,
                in: context.notificationContext
            )
        }
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
            let clientIds = clientIds.compactMap { $0.rawValue.utf8Data?.bytes }
            let events = try await mlsActionExecutor.removeClients(clientIds, from: groupID)
            conversationEventProcessor.processConversationEvents(events)
        } catch {
            logger.warn("failed to remove members from group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Remove group

    public func wipeGroup(_ groupID: MLSGroupID) throws {
        logger.info("wiping group (\(groupID.safeForLoggingDescription))")
        do {
            try coreCrypto.perform { try $0.wipeConversation(conversationId: groupID.bytes) }
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

    public func uploadKeyPackagesIfNeeded() {
        logger.info("uploading key packages if needed")

        func logWarn(abortedWithReason reason: String) {
            logger.warn("aborting key packages upload: \(reason)")
        }

        guard shouldQueryUnclaimedKeyPackagesCount() else { return }

        guard let context = context else {
            return logWarn(abortedWithReason: "missing context")
        }

        guard let clientID = ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier else {
            return logWarn(abortedWithReason: "failed to get client ID")
        }

        Task {
            do {
                let unclaimedKeyPackageCount = try await countUnclaimedKeyPackages(clientID: clientID, context: context.notificationContext)
                logger.info("there are \(unclaimedKeyPackageCount) unclaimed key packages")

                userDefaults.lastKeyPackageCountDate = Date()

                guard unclaimedKeyPackageCount <= halfOfTargetUnclaimedKeyPackageCount else {
                    logger.info("no need to upload new key packages yet")
                    return
                }

                let amount = UInt32(targetUnclaimedKeyPackageCount)
                let keyPackages = try generateKeyPackages(amountRequested: amount)
                try await uploadKeyPackages(clientID: clientID, keyPackages: keyPackages, context: context.notificationContext)
                logger.info("success: uploaded key packages for client \(clientID)")
            } catch let error {
                logger.warn("failed to upload key packages for client \(clientID). \(String(describing: error))")
            }
        }
    }

    private func shouldQueryUnclaimedKeyPackagesCount() -> Bool {
        do {
            let estimatedLocalKeyPackageCount = try coreCrypto.perform {
                try $0.clientValidKeypackagesCount(ciphersuite: defaultCipherSuite.rawValue)
            }
            let shouldCountRemainingKeyPackages = estimatedLocalKeyPackageCount < halfOfTargetUnclaimedKeyPackageCount
            let lastCheckWasMoreThan24Hours = userDefaults.hasMoreThan24HoursPassedSinceLastCheck

            guard lastCheckWasMoreThan24Hours || shouldCountRemainingKeyPackages else {
                logger.info("last check was recent and there are enough unclaimed key packages. not uploading.")
                return false
            }

            return true

        } catch let error {
            logger.warn("failed to get valid key packages count with error: \(String(describing: error))")
            return true
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

    private func generateKeyPackages(amountRequested: UInt32) throws -> [String] {
        logger.info("generating \(amountRequested) key packages")

        var keyPackages = [[Byte]]()

        do {
            keyPackages = try coreCrypto.perform { try $0.clientKeypackages(ciphersuite: defaultCipherSuite.rawValue, amountRequested: amountRequested) }

        } catch let error {
            logger.warn("failed to generate new key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        if keyPackages.isEmpty {
            logger.warn("CoreCrypto generated empty key packages array")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        return keyPackages.map { $0.data.base64EncodedString() }
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

    public func conversationExists(groupID: MLSGroupID) -> Bool {
        let result = coreCrypto.perform { $0.conversationExists(conversationId: groupID.bytes) }
        logger.info("checking if group (\(groupID)) exists... it does\(result ? "!" : " not!")")
        return result
    }

    public func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        logger.info("processing welcome message")

        guard let messageBytes = welcomeMessage.base64DecodedBytes else {
            logger.error("failed to convert welcome message to bytes")
            throw MLSWelcomeMessageProcessingError.failedToConvertMessageToBytes
        }

        do {
            let groupIDBytes = try coreCrypto.perform {
                try $0.processWelcomeMessage(
                    welcomeMessage: messageBytes,
                    customConfiguration: .init(keyRotationSpan: nil, wirePolicy: nil)
                )
            }
            let groupID = MLSGroupID(groupIDBytes)
            uploadKeyPackagesIfNeeded()
            staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
            return groupID

        } catch {
            logger.error("failed to process welcome message: \(String(describing: error))")
            throw MLSWelcomeMessageProcessingError.failedToProcessMessage
        }
    }

    // MARK: - Joining conversations

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        guard let context = context else {
            logger.warn("MLSService is missing sync context")
            return
        }

        if !conversationExists(groupID: groupID) {
            try createGroup(for: groupID)
        }

        let selfUser = ZMUser.selfUser(in: context)
        let mlsUser = MLSUser(from: selfUser)

        try await joinGroup(with: groupID)
        try await addMembersToConversation(with: [mlsUser], for: groupID)
    }

    public func joinGroup(with groupID: MLSGroupID) async throws {
        try await joinByExternalCommit(groupID: groupID)
    }

    typealias PendingJoin = (groupID: MLSGroupID, epoch: UInt64)

    /// Registers a group to be joined via external commit once the app has finished processing events
    /// - Parameter groupID: the identifier for the MLS group
    public func registerPendingJoin(_ groupID: MLSGroupID) {
        groupsPendingJoin.insert(groupID)
    }

    /// Request to join groups still pending
    ///
    /// Generates a list of groups for which the `mlsStatus` is `pendingJoin`
    /// and sends external commits to join these groups
    public func performPendingJoins() {
        guard let context = context else {
            return
        }

        generatePendingJoins(in: context).forEach { pendingJoin in
            Task {
                try await joinByExternalCommit(groupID: pendingJoin.groupID)
            }
        }

        groupsPendingJoin.removeAll()
    }

    private func generatePendingJoins(in context: NSManagedObjectContext) -> [PendingJoin] {
        logger.info("generating list of groups pending join")

        return groupsPendingJoin.compactMap { groupID in

            guard let conversation = ZMConversation.fetch(with: groupID, in: context) else {
                logger.warn("conversation not found for group (\(groupID.safeForLoggingDescription))")
                return nil
            }

            guard let status = conversation.mlsStatus, status == .pendingJoin else {
                logger.warn("group (\(groupID.safeForLoggingDescription)) status is not pending join")
                return nil
            }

            return (groupID, conversation.epoch)

        }
    }

    // MARK: - Out-of-sync conversations

    /// Fetches and re-joins MLS conversations that are out of sync
    /// (where the conversation object's epoch differs from the corresponding MLS group epoch)
    public func repairOutOfSyncConversations() {
        guard let context = self.context else { return }

        let outOfSync = outOfSyncConversations(in: context)

        logger.info("found \(outOfSync.count) conversations out of sync")

        outOfSync.forEach { conversation in
            guard let groupID = conversation.mlsGroupID else {
                return
            }

            launchGroupRepairTaskIfNotInProgress(for: groupID) {
                do {
                    try await self.joinGroupAndAppendGapSystemMessage(
                        groupID: groupID,
                        conversation: conversation,
                        context: context
                    )
                } catch {
                    self.logger.warn("failed to repair out of sync conversation (\(groupID.safeForLoggingDescription)). error: \(String(describing: error))")
                }
            }
        }
    }

    func fetchAndRepairGroupIfPossible(with groupID: MLSGroupID) {
        launchGroupRepairTaskIfNotInProgress(for: groupID) {
            await self.fetchAndRepairGroup(with: groupID)
        }
    }

    public func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        if let subgroupInfo = subconversationGroupIDRepository.findSubgroupTypeAndParentID(for: groupID) {
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

            guard isConversationOutOfSync(
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

        appendGapSystemMessage(
            in: conversation,
            context: context
        )

        logger.info("inserted gap system message in conversation (\(groupID.safeForLoggingDescription))")
    }

    private func appendGapSystemMessage(
        in conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        context.perform {
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

            guard isConversationOutOfSync(
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
    ) {
        Task {
            guard await !groupsBeingRepaired.contains(group: groupID) else {
                return
            }

            await groupsBeingRepaired.insert(group: groupID)
            await repairOperation()
            await groupsBeingRepaired.remove(group: groupID)
        }
    }

    private func outOfSyncConversations(in context: NSManagedObjectContext) -> [ZMConversation] {
        return coreCrypto.perform { coreCrypto in
            return ZMConversation.fetchMLSConversations(in: context).filter {
                isConversationOutOfSync(
                    $0,
                    coreCrypto: coreCrypto,
                    context: context
                )
            }
        }
    }

    private func isConversationOutOfSync(
        _ conversation: ZMConversation,
        subgroup: MLSSubgroup? = nil,
        coreCrypto: CoreCryptoProtocol,
        context: NSManagedObjectContext
    ) -> Bool {
        var isOutOfSync: Bool = false

        context.performAndWait {
            var groupID: MLSGroupID?
            var epoch: UInt64

            if let subgroup = subgroup {
                groupID = subgroup.groupID
                epoch = UInt64(subgroup.epoch)
            } else {
                groupID = conversation.mlsGroupID
                epoch = conversation.epoch
            }

            guard let groupID = groupID else { return }

            do {
                let localEpoch = try coreCrypto.conversationEpoch(conversationId: groupID.bytes)
                isOutOfSync = localEpoch != epoch
                logger.info("epochs(remote: \(epoch), local: \(localEpoch)) for (\(groupID.safeForLoggingDescription))")
            } catch {
                logger.info("cannot resolve conversation epoch \(String(describing: error)) for (\(groupID.safeForLoggingDescription))")
                return
            }
        }

        return isOutOfSync
    }

    private func isConversationOutOfSync(
        _ conversation: ZMConversation,
        subgroup: MLSSubgroup? = nil,
        context: NSManagedObjectContext
    ) -> Bool {
        return coreCrypto.perform {
            return isConversationOutOfSync(
                conversation,
                subgroup: subgroup,
                coreCrypto: $0,
                context: context
            )
        }
    }

    // MARK: - External Proposals

    private func sendExternalAddProposal(_ groupID: MLSGroupID, epoch: UInt64) async {
        logger.info("requesting to join group (\(groupID.safeForLoggingDescription)")

        do {
            let proposal = try coreCrypto.perform {
                try $0.newExternalAddProposal(conversationId: groupID.bytes,
                                              epoch: epoch,
                                              ciphersuite: defaultCipherSuite.rawValue,
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

    private func sendProposal(_ bytes: [Byte], groupID: MLSGroupID) async throws {
        do {
            logger.info("sending proposal in group (\(groupID.safeForLoggingDescription))")

            guard let context = context else { return }

            let updateEvents = try await actionsProvider.sendMessage(
                bytes.data,
                in: context.notificationContext
            )

            conversationEventProcessor.processConversationEvents(updateEvents)

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

                context.performAndWait {
                    parentConversationInfo.conversation.mlsStatus = .ready
                }
            }

            conversationEventProcessor.processConversationEvents(updateEvents)
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
        message: [Byte],
        for groupID: MLSGroupID
    ) throws -> [Byte] {
        return try encryptionService.encrypt(
            message: message,
            for: groupID
        )
    }

    // MARK: - Decrypting Message

    public func decrypt(
        message: String,
        for groupID: MLSGroupID,
        subconversationType: SubgroupType?
    ) throws -> MLSDecryptResult? {
        typealias DecryptionError = MLSDecryptionService.MLSMessageDecryptionError

        do {
            return try decryptionService.decrypt(
                message: message,
                for: groupID,
                subconversationType: subconversationType
            )
        } catch DecryptionError.wrongEpoch {
            fetchAndRepairGroupIfPossible(with: groupID)
            throw DecryptionError.wrongEpoch
        } catch {
            throw error
        }
    }

    // MARK: - Pending proposals

    enum MLSCommitPendingProposalsError: Error {

        case failedToCommitPendingProposals

    }

    /// Commit all pending proposals for all groups.
    ///
    /// - Throws: `MLSCommitPendingProposalsError` if proposals couldn't be commited.

    public func commitPendingProposals() async throws {
        guard context != nil else {
            return
        }

        logger.info("committing any scheduled pending proposals")

        let groupsWithPendingCommits = self.sortedGroupsWithPendingCommits()

        logger.info("\(groupsWithPendingCommits.count) groups with scheduled pending proposals")

        for (groupID, timestamp) in groupsWithPendingCommits {
            if timestamp.isInThePast {
                logger.info("commit scheduled in the past, committing...")
                try await commitPendingProposals(in: groupID)
            } else {
                logger.info("commit scheduled in the future, waiting...")
                try await Task.sleep(nanoseconds: timestamp.timeIntervalSinceNow.nanoseconds)
                logger.info("scheduled commit is ready, committing...")
                try await commitPendingProposals(in: groupID)
            }
        }
    }

    private func sortedGroupsWithPendingCommits() -> [(MLSGroupID, Date)] {
        guard let context = context else {
            return []
        }

        var result: [(MLSGroupID, Date)] = []

        context.performAndWait {
            let conversations = ZMConversation.fetchConversationsWithPendingProposals(in: context)

            for conversation in conversations {
                guard
                    let groupID = conversation.mlsGroupID,
                    let timestamp = conversation.commitPendingProposalDate
                else {
                    continue
                }

                result.append((groupID, timestamp))

                // The pending proposal might be for the subconversation,
                // so include it just in case.
                if let subgroupID = subconversationGroupIDRepository.fetchSubconversationGroupID(
                    forType: .conference,
                    parentGroupID: groupID
                ) {
                    result.append((subgroupID, timestamp))
                }
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
            conversationEventProcessor.processConversationEvents(events)
            clearPendingProposalCommitDate(for: groupID)
            delegate?.mlsServiceDidCommitPendingProposal(for: groupID)
        } catch MLSActionExecutor.Error.noPendingProposals {
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
        typealias Error = MLSActionExecutor.Error

        do {
            try await operation()

        } catch Error.failedToSendCommit(recovery: .commitPendingProposalsAfterQuickSync) {
            logger.warn("failed to send commit, syncing then committing pending proposals...")
            await syncStatus.performQuickSync()
            logger.info("sync finished, committing pending proposals...")
            try await commitPendingProposals(in: groupID)

        } catch Error.failedToSendCommit(recovery: .retryAfterQuickSync) {
            logger.warn("failed to send commit, syncing then retrying operation...")
            await syncStatus.performQuickSync()
            logger.info("sync finished, retying operation...")
            try await retryOnCommitFailure(for: groupID, operation: operation)

        } catch Error.failedToSendCommit(recovery: .retryAfterRepairingGroup) {
            logger.warn("failed to send commit, repairing group then retrying operation...")
            await fetchAndRepairGroup(with: groupID)
            logger.info("repair finished, retrying operation...")
            try await operation()

        } catch Error.failedToSendCommit(recovery: .giveUp) {
            logger.warn("failed to send commit, giving up...")
            // TODO: [John] inform user
            throw Error.failedToSendCommit(recovery: .giveUp)

        } catch Error.failedToSendExternalCommit(recovery: .retry) {
            logger.warn("failed to send external commit, retrying operation...")
            try await retryOnCommitFailure(for: groupID, operation: operation)

        } catch Error.failedToSendExternalCommit(recovery: .giveUp) {
            logger.warn("failed to send external commit, giving up...")
            throw MLSActionExecutor.Error.failedToSendExternalCommit(recovery: .giveUp)

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

            if subgroup.epoch <= 0 {
                try await createSubgroup(with: subgroup.groupID)
            } else if let epochAge = subgroup.epochTimestamp?.ageInDays, epochAge >= 1 {
                try await deleteSubgroup(
                    parentID: parentQualifiedID,
                    context: notificationContext
                )
                try await createSubgroup(with: subgroup.groupID)
            } else {
                try await joinSubgroup(
                    parentID: parentID,
                    subgroupID: subgroup.groupID
                )
            }

            subconversationGroupIDRepository.storeSubconversationGroupID(
                subgroup.groupID,
                forType: .conference,
                parentGroupID: parentID
            )

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

    private func createSubgroup(with id: MLSGroupID) async throws {
        do {
            logger.info("creating subgroup with id (\(id.safeForLoggingDescription))")
            try createGroup(for: id)
            try await updateKeyMaterial(for: id)
        } catch {
            logger.error("failed to create subgroup with id (\(id.safeForLoggingDescription)): \(String(describing: error))")
            throw SubgroupFailure.failedToCreateSubgroup
        }
    }

    private func deleteSubgroup(
        parentID: QualifiedID,
        context: NotificationContext
    ) async throws {
        do {
            logger.info("deleting subgroup with parent id (\(parentID))")
            try await actionsProvider.deleteSubgroup(
                conversationID: parentID.uuid,
                domain: parentID.domain,
                subgroupType: .conference,
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

    private func getMembers(for groupID: MLSGroupID) throws -> [MLSClientID] {
        do {
            logger.info("getting members for group (\(groupID.safeForLoggingDescription))")
            return try coreCrypto
                .perform { try $0.getClientIds(conversationId: groupID.bytes) }
                .compactMap { MLSClientID(data: Data($0)) }
        } catch {
            logger.error("failed to get members for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
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
            let subConversationGroupID = subconversationGroupIDRepository.fetchSubconversationGroupID(
                forType: subconversationType,
                parentGroupID: parentGroupID
            ),
            conversationExists(groupID: subConversationGroupID)
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
        guard let subconversationGroupID = subconversationGroupIDRepository.fetchSubconversationGroupID(
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

            subconversationGroupIDRepository.storeSubconversationGroupID(
                nil,
                forType: subconversationType,
                parentGroupID: parentGroupID
            )

            try coreCrypto.perform {
                try $0.wipeConversation(conversationId: subconversationGroupID.bytes)
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

    // MARK: - Proteus to MLS Migration

    public func startProteusToMLSMigration() async throws {
        // Migrate proteus team group conversations to MLS
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

private extension Date {

    var isInThePast: Bool {
        return compare(Date()) != .orderedDescending
    }

}

extension Invitee {

    init(from keyPackage: KeyPackage) {
        let id = MLSClientID(
            userID: keyPackage.userID.uuidString,
            clientID: keyPackage.client,
            domain: keyPackage.domain
        )

        guard
            let idData = id.rawValue.utf8Data,
            let keyPackageData = Data(base64Encoded: keyPackage.keyPackage)
        else {
            fatalError("Couldn't create Invitee from key package: \(keyPackage)")
        }

        self.init(
            id: idData.bytes,
            kp: keyPackageData.bytes
        )
    }

}

public protocol ConversationEventProcessorProtocol {

    func processConversationEvents(_ events: [ZMUpdateEvent])

}

private extension UserDefaults {

    enum Keys {
        static let keyPackageQueriedTime = "keyPackageQueriedTime"
    }

    var lastKeyPackageCountDate: Date? {

        get { object(forKey: Keys.keyPackageQueriedTime) as? Date }
        set { set(newValue, forKey: Keys.keyPackageQueriedTime) }

    }

    var hasMoreThan24HoursPassedSinceLastCheck: Bool {

        guard let storedDate = lastKeyPackageCountDate else { return true }

        if Calendar.current.dateComponents([.hour], from: storedDate, to: Date()).hour > 24 {
            return true
        } else {
            return false
        }

    }
}

extension UserDefaults {
    func test_setLastKeyPackageCountDate(_ date: Date) {
        lastKeyPackageCountDate = date
    }
}

extension CiphersuiteName {

    var rawValue: UInt16 {
        switch self {
        case .mls128Dhkemx25519Aes128gcmSha256Ed25519:
            return 1

        case .mls128Dhkemp256Aes128gcmSha256P256:
            return 2

        case .mls128Dhkemx25519Chacha20poly1305Sha256Ed25519:
            return 3

        case .mls256Dhkemx448Aes256gcmSha512Ed448:
            return 4

        case .mls256Dhkemp521Aes256gcmSha512P521:
            return 5

        case .mls256Dhkemx448Chacha20poly1305Sha512Ed448:
            return 6

        case .mls256Dhkemp384Aes256gcmSha384P384:
            return 7
        }
    }

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
