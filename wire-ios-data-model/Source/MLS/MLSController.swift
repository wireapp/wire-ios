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
import CoreCryptoSwift

public enum MLSDecryptResult: Equatable {
    case message(_ messageData: Data, _ senderClientID: String?)
    case proposal(_ commitDelay: UInt64)
}

public protocol MLSControllerProtocol {

    func uploadKeyPackagesIfNeeded()

    func createGroup(for groupID: MLSGroupID) throws

    func conversationExists(groupID: MLSGroupID) -> Bool

    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID

    func encrypt(message: Bytes, for groupID: MLSGroupID) throws -> Bytes

    func decrypt(message: String, for groupID: MLSGroupID) throws -> MLSDecryptResult?

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws

    func registerPendingJoin(_ group: MLSGroupID)

    func performPendingJoins()

    func wipeGroup(_ groupID: MLSGroupID)

    func commitPendingProposals() async throws

    func commitPendingProposals(in groupID: MLSGroupID) async throws

    func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date)
}

public protocol MLSControllerDelegate: AnyObject {

    func mlsControllerDidCommitPendingProposal(for groupID: MLSGroupID)
    func mlsControllerDidUpdateKeyMaterialForAllGroups()

}

public final class MLSController: MLSControllerProtocol {

    // MARK: - Properties

    private weak var context: NSManagedObjectContext?
    private let coreCrypto: SafeCoreCryptoProtocol
    private let mlsActionExecutor: MLSActionExecutorProtocol
    private let conversationEventProcessor: ConversationEventProcessorProtocol
    private let staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol
    private let userDefaults: UserDefaults
    private let logger = Logging.mls
    private var groupsPendingJoin = Set<MLSGroupID>()

    private let syncStatus: SyncStatusProtocol

    var backendPublicKeys = BackendMLSPublicKeys()
    var pendingProposalCommitTimers = [MLSGroupID: Timer]()

    let targetUnclaimedKeyPackageCount = 100
    let actionsProvider: MLSActionsProviderProtocol

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

    weak var delegate: MLSControllerDelegate?

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
        mlsActionExecutor: MLSActionExecutorProtocol? = nil,
        conversationEventProcessor: ConversationEventProcessorProtocol,
        staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol,
        userDefaults: UserDefaults,
        actionsProvider: MLSActionsProviderProtocol = MLSActionsProvider(),
        delegate: MLSControllerDelegate? = nil,
        syncStatus: SyncStatusProtocol
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
                let keyBytes = try coreCrypto.perform { try $0.clientPublicKey() }
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
            delegate?.mlsControllerDidUpdateKeyMaterialForAllGroups()
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
            Logging.mls.info("updating key material for group (\(groupID))")
            let events = try await mlsActionExecutor.updateKeyMaterial(for: groupID)
            staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
            conversationEventProcessor.processConversationEvents(events)
        } catch {
            Logging.mls.warn("failed to update key material for group (\(groupID)): \(String(describing: error))")
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
        logger.info("creating group for id: \(groupID)")

        do {
            let config = ConversationConfiguration(
                ciphersuite: .mls128Dhkemx25519Aes128gcmSha256Ed25519,
                externalSenders: backendPublicKeys.ed25519Keys,
                custom: .init(keyRotationSpan: nil, wirePolicy: nil)
            )

            try coreCrypto.perform {
                try $0.createConversation(
                    conversationId: groupID.bytes,
                    config: config
                )
            }
        } catch let error {
            logger.warn("failed to create group (\(groupID)): \(String(describing: error))")
            throw MLSGroupCreationError.failedToCreateGroup
        }

        staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
    }

    // MARK: - Add member

    enum MLSAddMembersError: Error {

        case noMembersToAdd
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
            logger.info("adding members to group (\(groupID)) with users: \(users)")
            guard !users.isEmpty else { throw MLSAddMembersError.noMembersToAdd }
            let keyPackages = try await claimKeyPackages(for: users)
            let invitees = keyPackages.map(Invitee.init(from:))
            let events = try await mlsActionExecutor.addMembers(invitees, to: groupID)
            conversationEventProcessor.processConversationEvents(events)
        } catch {
            logger.warn("failed to add members to group (\(groupID)): \(String(describing: error))")
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
            logger.info("removing members from group (\(groupID)), members: \(clientIds)")
            guard !clientIds.isEmpty else { throw MLSRemoveParticipantsError.noClientsToRemove }
            let clientIds = clientIds.compactMap { $0.string.utf8Data?.bytes }
            let events = try await mlsActionExecutor.removeClients(clientIds, from: groupID)
            conversationEventProcessor.processConversationEvents(events)
        } catch {
            logger.warn("failed to remove members from group (\(groupID)): \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Remove group

    public func wipeGroup(_ groupID: MLSGroupID) {
        logger.info("wiping group (\(groupID))")
        do {
            try coreCrypto.perform { try $0.wipeConversation(conversationId: groupID.bytes) }
        } catch {
            logger.warn("failed to wipe group (\(groupID)): \(String(describing: error))")
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
                try $0.clientValidKeypackagesCount()
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

        var keyPackages = [Bytes]()

        do {
            keyPackages = try coreCrypto.perform { try $0.clientKeypackages(amountRequested: amountRequested) }

        } catch let error {
            logger.warn("failed to generate new key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        if keyPackages.isEmpty {
            logger.warn("CoreCrypto generated empty key packages array")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        return keyPackages.map { $0.base64EncodedString } 
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

        guard let messageBytes = welcomeMessage.base64EncodedBytes else {
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

    typealias PendingJoin = (groupID: MLSGroupID, epoch: UInt64)

    /// Registers a group to be joined via external add proposal once the app has finished processing events
    /// - Parameter groupID: the identifier for the MLS group
    public func registerPendingJoin(_ groupID: MLSGroupID) {
        groupsPendingJoin.insert(groupID)
    }

    /// Request to join groups still pending
    ///
    /// Generates a list of groups for which the `mlsStatus` is `pendingJoin`
    /// and sends external add proposals for these groups
    public func performPendingJoins() {
        guard let context = context else {
            return
        }

        generatePendingJoins(in: context).forEach { pendingJoin in
            Task {
                try await sendExternalCommit(groupID: pendingJoin.groupID)
            }
        }

        groupsPendingJoin.removeAll()
    }

    private func generatePendingJoins(in context: NSManagedObjectContext) -> [PendingJoin] {
        logger.info("generating list of groups pending join")

        return groupsPendingJoin.compactMap { groupID in

            guard let conversation = ZMConversation.fetch(with: groupID, in: context) else {
                logger.warn("conversation not found for group (\(groupID))")
                return nil
            }

            guard let status = conversation.mlsStatus, status == .pendingJoin else {
                logger.warn("group (\(groupID)) status is not pending join")
                return nil
            }

            return (groupID, conversation.epoch)

        }
    }

    // MARK: - External Proposals

    private func sendExternalAddProposal(_ groupID: MLSGroupID, epoch: UInt64) async {
        logger.info("requesting to join group (\(groupID)")

        do {
            let proposal = try coreCrypto.perform { try $0.newExternalAddProposal(conversationId: groupID.bytes, epoch: epoch) }
            try await sendProposal(proposal, groupID: groupID)
            logger.info("success: requested to join group (\(groupID)")
        } catch {
            logger.warn(
                "failed to request join for group (\(groupID)): \(String(describing: error))"
            )
        }
    }

    enum MLSSendProposalError: Error {
        case failedToSendProposal
    }

    private func sendProposal(_ bytes: Bytes, groupID: MLSGroupID) async throws {
        do {
            logger.info("sending proposal in group (\(groupID))")

            guard let context = context else { return }

            let updateEvents = try await actionsProvider.sendMessage(
                bytes.data,
                in: context.notificationContext
            )

            conversationEventProcessor.processConversationEvents(updateEvents)

        } catch let error {
            logger.warn("failed to send proposal in group (\(groupID)): \(String(describing: error))")
            throw MLSSendProposalError.failedToSendProposal
        }
    }

    // MARK: - External Commits

    private func sendExternalCommit(groupID: MLSGroupID) async throws {
        try await retryOnCommitFailure(for: groupID, operation: { [weak self] in
            try await self?.internalSendExternalCommit(groupID: groupID)
        })
    }

    enum MLSSendExternalCommitError: Error {
        case conversationNotFound
    }

    private func internalSendExternalCommit(groupID: MLSGroupID) async throws {
        do {
            logger.info("sending external commit to join group (\(groupID)")

            guard let context = context else { return }

            guard let conversationInfo = fetchConversationInfo(
                with: groupID,
                in: context
            ) else {
                throw MLSSendExternalCommitError.conversationNotFound
            }

            let publicGroupState = try await actionsProvider.fetchPublicGroupState(
                conversationId: conversationInfo.identifier,
                domain: conversationInfo.domain,
                context: context.notificationContext
            )

            let updateEvents = try await mlsActionExecutor.joinGroup(
                groupID,
                publicGroupState: publicGroupState
            )

            context.performAndWait {
                conversationInfo.conversation.mlsStatus = .ready
            }
            
            conversationEventProcessor.processConversationEvents(updateEvents)
            logger.info("success: joined group (\(groupID)) with external commit")

        } catch {
            logger.warn("failed to send external commit to join group (\(groupID)): \(String(describing: error))")
            throw error
        }
    }

    private func fetchConversationInfo(
        with groupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) -> (conversation: ZMConversation, identifier: UUID, domain: String)? {

        var conversation: ZMConversation?
        var identifier: UUID?
        var domain: String?

        context.performAndWait {
            conversation = ZMConversation.fetch(with: groupID, in: context)
            identifier = conversation?.remoteIdentifier
            domain = conversation?.domain
        }

        guard
            let conversation = conversation,
            let identifier = identifier,
            let domain = domain?.selfOrNilIfEmpty ?? BackendInfo.domain
        else {
            return nil
        }

        return (conversation, identifier, domain)
    }

    // MARK: - Encrypt message

    public enum MLSMessageEncryptionError: Error {

        case failedToEncryptMessage

    }

    public func encrypt(message: Bytes, for groupID: MLSGroupID) throws -> Bytes {
        do {
            logger.info("encrypting message (\(message.count) bytes) for group (\(groupID))")
            return try coreCrypto.perform { try $0.encryptMessage(conversationId: groupID.bytes, message: message) }
        } catch let error {
            logger.warn("failed to encrypt message for group (\(groupID)): \(String(describing: error))")
            throw MLSMessageEncryptionError.failedToEncryptMessage
        }
    }


    // MARK: - Decrypting Message

    public enum MLSMessageDecryptionError: Error {

        case failedToConvertMessageToBytes
        case failedToDecryptMessage

    }

    /// Decrypts an MLS message for the given group
    ///
    /// - Parameters:
    ///   - message: a base64 encoded encrypted message
    ///   - groupID: the id of the MLS group
    ///
    /// - Returns:
    ///   The data representing the decrypted message bytes.
    ///   May be nil if the message was a handshake message, in which case it is safe to ignore.
    ///
    /// - Throws: `MLSMessageDecryptionError` if the message could not be decrypted

    public func decrypt(message: String, for groupID: MLSGroupID) throws -> MLSDecryptResult? {
        logger.info("decrypting message for group (\(groupID))")

        guard let messageBytes = message.base64EncodedBytes else {
            throw MLSMessageDecryptionError.failedToConvertMessageToBytes
        }

        do {
            let decryptedMessage = try coreCrypto.perform { try $0.decryptMessage(
                conversationId: groupID.bytes,
                payload: messageBytes
            ) }

            if let commitDelay = decryptedMessage.commitDelay {
                return MLSDecryptResult.proposal(commitDelay)
            }

            if let message = decryptedMessage.message {
                return MLSDecryptResult.message(
                    message.data,
                    senderClientId(from: decryptedMessage)
                )
            }

            return nil
        } catch {
            logger.warn("failed to decrypt message for group (\(groupID)): \(String(describing: error))")
            throw MLSMessageDecryptionError.failedToDecryptMessage
        }
    }

    private func senderClientId(from message: DecryptedMessage) -> String? {
        guard let senderClientID = message.senderClientId else {
            return nil
        }

        return MLSClientID(data: senderClientID.data)?.clientID
    }

    // MARK: - Pending proposals

    /// Schedule a date to commit all pending proposals for a group.
    ///
    /// - Parameters:
    ///   - groupID: The group in which the propsal(s) should be commited.
    ///   - commitDate: The date at which to commit the pending proposals.

    public func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date) {
        guard let context = context else {
            return
        }

        context.performAndWait {
            logger.info("schedule to commit pending proposals in \(groupID) at \(commitDate)")
            let conversation = ZMConversation.fetch(with: groupID, in: context)
            conversation?.commitPendingProposalDate = commitDate
        }
    }

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

            result = conversations.compactMap { conversation in
                guard
                    let groupID = conversation.mlsGroupID,
                    let timestamp = conversation.commitPendingProposalDate
                else {
                    return nil
                }

                return (groupID, timestamp)
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
        logger.info("preemptively committing pending proposals in group (\(groupID))")
        try await commitPendingProposals(in: groupID)
        logger.info("success: committed pending proposals in group (\(groupID))")
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
            logger.info("committing pending proposals in: \(groupID)")
            let events = try await mlsActionExecutor.commitPendingProposals(in: groupID)
            conversationEventProcessor.processConversationEvents(events)
            clearPendingProposalCommitDate(for: groupID)
            delegate?.mlsControllerDidCommitPendingProposal(for: groupID)
        } catch MLSActionExecutor.Error.noPendingProposals {
            logger.info("no proposals to commit in group (\(groupID))...")
            clearPendingProposalCommitDate(for: groupID)
        } catch {
            logger.info("failed to commit pending proposals in \(groupID): \(String(describing: error))")
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

        } catch MLSActionExecutor.Error.failedToSendCommit(recovery: .commitPendingProposalsAfterQuickSync) {
            logger.warn("failed to send commit, syncing then committing pending proposals...")
            await syncStatus.performQuickSync()
            logger.info("sync finished, committing pending proposals...")
            try await commitPendingProposals(in: groupID)

        } catch MLSActionExecutor.Error.failedToSendCommit(recovery: .retryAfterQuickSync) {
            logger.warn("failed to send commit, syncing then retrying operation...")
            await syncStatus.performQuickSync()
            logger.info("sync finished, retying operation...")
            try await retryOnCommitFailure(for: groupID, operation: operation)

        } catch MLSActionExecutor.Error.failedToSendCommit(recovery: .giveUp) {
            logger.warn("failed to send commit, giving up...")
            // TODO: [John] inform user
            throw MLSActionExecutor.Error.failedToSendCommit(recovery: .giveUp)

        } catch MLSActionExecutor.Error.failedToSendExternalCommit(recovery: .retry) {
            logger.warn("failed to send external commit, retrying operation...")
            try await retryOnCommitFailure(for: groupID, operation: operation)

        } catch MLSActionExecutor.Error.failedToSendExternalCommit(recovery: .giveUp) {
            logger.warn("failed to send external commit, giving up...")
            throw MLSActionExecutor.Error.failedToSendExternalCommit(recovery: .giveUp)

        }
    }

    // MARK: - Fetch Public Group State

    enum MLSGroupStateError: Error, Equatable {
        case failedToFetchGroupState
    }

    private func fetchPublicGroupState(
        conversationID: UUID,
        domain: String,
        context: NotificationContext
    ) async throws -> Data {
        do {
            return try await actionsProvider.fetchPublicGroupState(
                conversationId: conversationID,
                domain: domain,
                context: context
            )

        } catch let error {
            self.logger.warn("failed to fetch public group state with error: \(String(describing: error))")
            throw MLSGroupStateError.failedToFetchGroupState
        }
    }

}

// MARK: -  Helper types

public struct MLSUser: Equatable {

    public let id: UUID
    public let domain: String
    public let selfClientID: String?

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

private extension TimeInterval  {

    var nanoseconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }

}

private extension Date {

    var isInThePast: Bool {
        return compare(Date()) != .orderedDescending
    }

}

extension String {

    var utf8Data: Data? {
        return data(using: .utf8)
    }

    var base64DecodedData: Data? {
        return Data(base64Encoded: self)
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
            let idData = id.string.utf8Data,
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
