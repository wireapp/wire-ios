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

public protocol MLSControllerProtocol {

    func uploadKeyPackagesIfNeeded()

    @available(iOS 15, *)
    func createGroup(for groupID: MLSGroupID, with users: [MLSUser]) async throws

    func conversationExists(groupID: MLSGroupID) -> Bool

    @discardableResult
    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID

}

public final class MLSController: MLSControllerProtocol {

    // MARK: - Properties

    private weak var context: NSManagedObjectContext?
    private let coreCrypto: CoreCryptoProtocol
    private let logger = ZMSLog(tag: "core-crypto")

    let targetUnclaimedKeyPackageCount = 100

    let actionsProvider: MLSActionsProviderProtocol

    // MARK: - Life cycle

    init(
        context: NSManagedObjectContext,
        coreCrypto: CoreCryptoProtocol,
        actionsProvider: MLSActionsProviderProtocol = MLSActionsProvider()
    ) {
        self.context = context
        self.coreCrypto = coreCrypto
        self.actionsProvider = actionsProvider

        do {
            try generatePublicKeysIfNeeded()
        } catch {
            logger.error("failed to generate public keys: \(String(describing: error))")
        }
    }

    // MARK: - Public keys

    private func generatePublicKeysIfNeeded() throws {
        guard
            let context = context,
            let selfClient = ZMUser.selfUser(in: context).selfClient()
        else {
            return
        }

        var keys = selfClient.mlsPublicKeys

        if keys.ed25519 == nil {
            let keyBytes = try coreCrypto.wire_clientPublicKey()
            let keyData = Data(keyBytes)
            keys.ed25519 = keyData.base64EncodedString()
        }

        selfClient.mlsPublicKeys = keys
        context.saveOrRollback()
    }

    // MARK: - Group creation

    enum MLSGroupCreationError: Error {

        case noParticipantsToAdd
        case failedToClaimKeyPackages
        case failedToCreateGroup
        case failedToAddMembers
        case failedToSendHandshakeMessage
        case failedToSendWelcomeMessage

    }

    /// Create an MLS group with the given conversation.
    ///
    /// - Parameters:
    ///   - conversation the conversation representing the MLS group.
    ///
    /// - Throws:
    ///   - MLSGroupCreationError if the group could not be created.

    @available(iOS 15, *)
    public func createGroup(for groupID: MLSGroupID, with users: [MLSUser]) async throws {
        guard let context = context else { return }

        guard !users.isEmpty else {
            throw MLSGroupCreationError.noParticipantsToAdd
        }

        let keyPackages = try await claimKeyPackages(for: users)
        let invitees = keyPackages.map(Invitee.init(from:))
        let messagesToSend = try createGroup(id: groupID, invitees: invitees)

        guard let messagesToSend = messagesToSend else { return }
        try await sendMessage(messagesToSend.message)
        try await sendWelcomeMessage(messagesToSend.welcome)
    }

    @available(iOS 15, *)
    private func claimKeyPackages(for users: [MLSUser]) async throws -> [KeyPackage] {
        do {
            guard let context = context else { return [] }

            var result = [KeyPackage]()

            for try await keyPackages in claimKeyPackages(for: users, in: context) {
                result.append(contentsOf: keyPackages)
            }

            return result
        } catch let error {
            logger.error("failed to claim key packages: \(String(describing: error))")
            throw MLSGroupCreationError.failedToClaimKeyPackages
        }

    }

    @available(iOS 15, *)
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

    private func createGroup(
        id: MLSGroupID,
        invitees: [Invitee]
    ) throws -> MemberAddedMessages? {
        let config = ConversationConfiguration(ciphersuite: .mls128Dhkemx25519Aes128gcmSha256Ed25519)

        do {
            try coreCrypto.wire_createConversation(
                conversationId: id.bytes,
                config: config
            )
        } catch let error {
            logger.error("failed to create mls group: \(String(describing: error))")
            throw MLSGroupCreationError.failedToCreateGroup
        }

        do {
            return try coreCrypto.wire_addClientsToConversation(
                conversationId: id.bytes,
                clients: invitees
            )
        } catch let error {
            logger.error("failed to add members: \(String(describing: error))")
            throw MLSGroupCreationError.failedToAddMembers
        }
    }

    @available(iOS 15, *)
    private func sendMessage(_ bytes: Bytes) async throws {
        do {
            guard let context = context else { return }
            try await actionsProvider.sendMessage(
                bytes.data,
                in: context.notificationContext
            )
        } catch let error {
            logger.error("failed to send mls message: \(String(describing: error))")
            throw MLSGroupCreationError.failedToSendHandshakeMessage
        }
    }

    @available(iOS 15, *)
    private func sendWelcomeMessage(_ bytes:  Bytes) async throws {
        do {
            guard let context = context else { return }
            try await actionsProvider.sendWelcomeMessage(
                bytes.data,
                in: context.notificationContext
            )
        } catch let error {
            logger.error("failed to send welcome message: \(String(describing: error))")
            throw MLSGroupCreationError.failedToSendWelcomeMessage
        }
    }

    // MARK: - Key packages

    enum MLSKeyPackagesError: Error {

        case failedToGenerateKeyPackages

    }

    /// Uploads new key packages if needed.
    ///
    /// Checks how many key packages are available on the backend and
    /// generates new ones if there are less than 50% of the target unclaimed key package count..

    public func uploadKeyPackagesIfNeeded() {
        guard let context = context else { return }
        let user = ZMUser.selfUser(in: context)
        guard let clientID = user.selfClient()?.remoteIdentifier else { return }

        // TODO: Here goes the logic to determine how check to remaining key packages and re filling the new key packages after calculating number of welcome messages it receives by the client.

        /// For now temporarily we generate and upload at most 100 new key packages

         countUnclaimedKeyPackages(clientID: clientID, context: context.notificationContext) { unclaimedKeyPackageCount in
            guard unclaimedKeyPackageCount <= self.targetUnclaimedKeyPackageCount / 2 else { return }

            do {
                let amount = UInt32(self.targetUnclaimedKeyPackageCount - unclaimedKeyPackageCount)
                let keyPackages = try self.generateKeyPackages(amountRequested: amount)

                self.uploadKeyPackages(
                    clientID: clientID,
                    keyPackages: keyPackages,
                    context: context.notificationContext
                )

            } catch {
                self.logger.error("failed to generate new key packages: \(String(describing: error))")
            }
        }
    }

    private func countUnclaimedKeyPackages(clientID: String, context: NotificationContext, completion: @escaping (Int) -> Void) {
        actionsProvider.countUnclaimedKeyPackages(clientID: clientID, context: context) { result in
            switch result {
            case .success(let count):
                completion(count)

            case .failure(let error):
                self.logger.error("failed to fetch MLS key packages count with error: \(String(describing: error))")
            }
        }
    }

    private func generateKeyPackages(amountRequested: UInt32) throws -> [String] {

        var keyPackages = [[UInt8]]()

        do {

            keyPackages = try coreCrypto.wire_clientKeypackages(amountRequested: amountRequested)

        } catch let error {
            logger.error("failed to generate new key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        if keyPackages.isEmpty {
            logger.error("CoreCrypto generated empty key packages array")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        return keyPackages.map {
            Data($0).base64EncodedString()
        }
    }

    private func uploadKeyPackages(clientID: String, keyPackages: [String], context: NotificationContext) {
        actionsProvider.uploadKeyPackages(clientID: clientID, keyPackages: keyPackages, context: context) { result in
            switch result {
            case .success:
                break

            case .failure(let error):
                self.logger.error("failed to upload key packages: \(String(describing: error))")
            }
        }
    }

    // MARK: - Process welcome message

    public enum MLSWelcomeMessageProcessingError: Error {

        case failedToConvertMessageToBytes
        case failedToProcessMessage
        
    }


    public func conversationExists(groupID: MLSGroupID) -> Bool {
        return coreCrypto.wire_conversationExists(conversationId: groupID.bytes)
    }

    @discardableResult
    public func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        guard let messageBytes = welcomeMessage.base64EncodedBytes else {
            logger.error("failed to convert welcome message to bytes")
            throw MLSWelcomeMessageProcessingError.failedToConvertMessageToBytes
        }

        do {
            let groupID = try coreCrypto.wire_processWelcomeMessage(welcomeMessage: messageBytes)
            return MLSGroupID(groupID)
        } catch {
            logger.error("failed to process welcome message: \(String(describing: error))")
            throw MLSWelcomeMessageProcessingError.failedToProcessMessage
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
        domain = user.domain?.selfOrNilIfEmpty ?? APIVersion.domain!

        if user.isSelfUser, let selfClientID = user.selfClient()?.remoteIdentifier {
            self.selfClientID = selfClientID
        } else {
            selfClientID = nil
        }
    }

}

// MARK: - Helper Extensions

private extension String {

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

protocol MLSActionsProviderProtocol {

    func countUnclaimedKeyPackages(
        clientID: String,
        context: NotificationContext,
        resultHandler: @escaping CountSelfMLSKeyPackagesAction.ResultHandler
    )

    func uploadKeyPackages(
        clientID: String,
        keyPackages: [String],
        context: NotificationContext,
        resultHandler: @escaping UploadSelfMLSKeyPackagesAction.ResultHandler
    )

    @available(iOS 15, *)
    func claimKeyPackages(
        userID: UUID,
        domain: String?,
        excludedSelfClientID: String?,
        in context: NotificationContext
    ) async throws -> [KeyPackage]

    @available(iOS 15, *)
    func sendMessage(
        _ message: Data,
        in context: NotificationContext
    ) async throws

    @available(iOS 15, *)
    func sendWelcomeMessage(
        _ welcomeMessage: Data,
        in context: NotificationContext
    ) async throws

}

private class MLSActionsProvider: MLSActionsProviderProtocol {

    func countUnclaimedKeyPackages(clientID: String, context: NotificationContext, resultHandler: @escaping CountSelfMLSKeyPackagesAction.ResultHandler) {
        let action = CountSelfMLSKeyPackagesAction(clientID: clientID, resultHandler: resultHandler)
        action.send(in: context)
    }

    func uploadKeyPackages(clientID: String, keyPackages: [String], context: NotificationContext, resultHandler: @escaping UploadSelfMLSKeyPackagesAction.ResultHandler) {
        let action = UploadSelfMLSKeyPackagesAction(clientID: clientID, keyPackages: keyPackages, resultHandler: resultHandler)
        action.send(in: context)
    }

    @available(iOS 15, *)
    func claimKeyPackages(
        userID: UUID,
        domain: String?,
        excludedSelfClientID: String?,
        in context: NotificationContext
    ) async throws -> [KeyPackage] {
        var action = ClaimMLSKeyPackageAction(
            domain: domain,
            userId: userID,
            excludedSelfClientId: excludedSelfClientID
        )

        return try await action.perform(in: context)
    }

    @available(iOS 15, *)
    func sendMessage(
        _ message: Data,
        in context: NotificationContext
    ) async throws {
        var action = SendMLSMessageAction(message: message)
        try await action.perform(in: context)
    }

    @available(iOS 15, *)
    func sendWelcomeMessage(
        _ welcomeMessage: Data,
        in context: NotificationContext
    ) async throws {
        var action = SendMLSWelcomeAction(welcomeMessage: welcomeMessage)
        try await action.perform(in: context)
    }

}
