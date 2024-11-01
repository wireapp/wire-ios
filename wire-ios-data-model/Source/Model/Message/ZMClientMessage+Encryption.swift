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

import Foundation
import WireCryptobox

private var zmLog = ZMSLog(tag: "message encryption")

public let ZMFailedToCreateEncryptedMessagePayloadString = "💣"

/// Strategy for handling missing clients.
///
/// When sending a message through the backend, the backend might warn us that some user clients that
/// were supposed to be there are missing (e.g. another user added a new client that we don't yet know about).
/// The various strategies give a hint to the backend of how we want to handle missing clients.

public enum MissingClientsStrategy: Equatable {

    /// Fail the request if there is any missing client.

    case doNotIgnoreAnyMissingClient

    /// Fail the request if there is any missing client for the given user, but ignore missing clients of
    /// any other user.

    case ignoreAllMissingClientsNotFromUsers(userIds: Set<QualifiedID>)

    /// Do not fail the request, no matter which clients are missing.

    case ignoreAllMissingClients

}

// FUTUREWORK: remove this code duplication (it's duplicated on ZMAssetClientMessage)
extension ZMClientMessage {

    func updateUnderlayingMessageBeforeSending(in context: NSManagedObjectContext) {
        if conversation?.conversationType == .oneOnOne {
            // Update expectsReadReceipt flag to reflect the current user setting
            if var updatedGenericMessage = underlyingMessage {
                updatedGenericMessage.setExpectsReadConfirmation(ZMUser.selfUser(in: context).readReceiptsEnabled)
                do {
                    try setUnderlyingMessage(updatedGenericMessage)
                } catch {
                    Logging.messageProcessing.warn("Failed to update generic message. Reason: \(error.localizedDescription)")
                }
            }
        }

        if let legalHoldStatus = conversation?.legalHoldStatus {
            // Update the legalHoldStatus flag to reflect the current known legal hold status
            if var updatedGenericMessage = underlyingMessage {
                updatedGenericMessage.setLegalHoldStatus(legalHoldStatus.denotesEnabledComplianceDevice ? .enabled : .disabled)
                do {
                    try setUnderlyingMessage(updatedGenericMessage)
                } catch {
                    Logging.messageProcessing.warn("Failed to update generic message. Reason: \(error.localizedDescription)")
                }
            }
        }
    }

}

extension ZMAssetClientMessage {

    func updateUnderlayingMessageBeforeSending(in context: NSManagedObjectContext) {
        if conversation?.conversationType == .oneOnOne {
            // Update expectsReadReceipt flag to reflect the current user setting
            if var updatedGenericMessage = underlyingMessage {
                updatedGenericMessage.setExpectsReadConfirmation(ZMUser.selfUser(in: context).readReceiptsEnabled)
                do {
                    try setUnderlyingMessage(updatedGenericMessage)
                } catch {
                    Logging.messageProcessing.warn("Failed to update generic message. Reason: \(error.localizedDescription)")
                }
            }
        }

        if let legalHoldStatus = conversation?.legalHoldStatus {
            // Update the legalHoldStatus flag to reflect the current known legal hold status
            if var updatedGenericMessage = underlyingMessage {
                updatedGenericMessage.setLegalHoldStatus(legalHoldStatus.denotesEnabledComplianceDevice ? .enabled : .disabled)
                do {
                    try setUnderlyingMessage(updatedGenericMessage)
                } catch {
                    Logging.messageProcessing.warn("Failed to update generic message. Reason: \(error.localizedDescription)")
                }
            }
        }
    }

}

extension GenericMessage {

    public func recipientUsersForMessage(in conversation: ZMConversation, selfUser: ZMUser) -> (users: [ZMUser: Set<UserClient>], strategy: MissingClientsStrategy) {
        let (services, otherUsers) = conversation.localParticipants.categorizeServicesAndUser()

        func recipientForButtonActionMessage() -> Set<ZMUser> {
            guard
                case .buttonAction? = content,
                let managedObjectContext = conversation.managedObjectContext,
                let message = ZMMessage.fetch(withNonce: UUID(uuidString: buttonAction.referenceMessageID), for: conversation, in: managedObjectContext),
                let sender = message.sender
            else {
                fatal("buttonAction needs a recipient")
            }

            return [sender]
        }

        func recipientForConfirmationMessage() -> Set<ZMUser>? {
            guard
                hasConfirmation,
                let managedObjectContext = conversation.managedObjectContext,
                let message = ZMMessage.fetch(withNonce: UUID(uuidString: confirmation.firstMessageID), for: conversation, in: managedObjectContext),
                let sender = message.sender
                else {
                    return nil
            }

            return [sender]
        }

        func recipientForOtherUsers() -> Set<ZMUser>? {
            guard conversation.connectedUser != nil || (otherUsers.isEmpty == false) else { return nil }
            if let connectedUser = conversation.connectedUser { return [connectedUser] }
            return Set(otherUsers)
        }

        func recipientsForDeletedEphemeral() -> Set<ZMUser>? {
            guard
                case .deleted? = content,
                conversation.conversationType == .group
            else {
                return nil
            }

            let nonce = UUID(uuidString: self.deleted.messageID)

            guard
                let managedObjectContext = conversation.managedObjectContext,
                let message = ZMMessage.fetch(withNonce: nonce, for: conversation, in: managedObjectContext),
                message.destructionDate != nil
            else {
                return nil
            }

            guard let sender = message.sender else {
                zmLog.error("sender of deleted ephemeral message \(String(describing: self.deleted.messageID)) is already cleared \n ConvID: \(String(describing: conversation.remoteIdentifier)) ConvType: \(conversation.conversationType.rawValue)")
                WireLogger.proteus.error("sender of deleted ephemeral message \(String(describing: self.deleted.messageID)) is already cleared \n ConvID: \(String(describing: conversation.remoteIdentifier)) ConvType: \(conversation.conversationType.rawValue)")
                return [selfUser]
            }

            // If self deletes their own message, we want to send a delete message for everyone, so return nil.
            guard !sender.isSelfUser else { return nil }

            // Otherwise we delete only for self and the sender, all other recipients are unaffected.
            return [sender, selfUser]
        }

        func allAuthorizedRecipients() -> Set<ZMUser> {
            if let connectedUser = conversation.connectedUser { return [connectedUser, selfUser] }

            func mentionedServices() -> Set<ZMUser> {
                return services.filter { service in
                    self.textData?.mentions.contains { $0.userID == service.remoteIdentifier?.transportString() } ?? false
                }
            }

            let authorizedServices = ZMUser.servicesMustBeMentioned ? mentionedServices() : services

            return otherUsers.union(authorizedServices).union([selfUser])
        }

        var recipientUsers = Set<ZMUser>()

        switch content {
        case .confirmation?:
            guard let recipients = recipientForConfirmationMessage() ?? recipientForOtherUsers() else {
                let confirmationInfo = ", original message: \(String(describing: self.confirmation.firstMessageID))"
                fatal("confirmation need a recipient\n ConvType: \(conversation.conversationType.rawValue) \(confirmationInfo)")
            }
            recipientUsers = recipients
        case .buttonAction?:
            recipientUsers = recipientForButtonActionMessage()
        default:
            if let deletedEphemeral = recipientsForDeletedEphemeral() {
                recipientUsers = deletedEphemeral
            } else {
                recipientUsers = allAuthorizedRecipients()
            }
        }

        let hasRestrictions: Bool = {
            if conversation.connectedUser != nil { return recipientUsers.count != 2 }
            return recipientUsers.count != conversation.localParticipants.count
        }()

        let strategy: MissingClientsStrategy
        if hasRestrictions {
            let qualifiedIds = recipientUsers.compactMap({ user in
                user.qualifiedID
            })
            strategy = .ignoreAllMissingClientsNotFromUsers(userIds: Set(qualifiedIds))
        } else {
            strategy = .doNotIgnoreAnyMissingClient
        }

        return (recipientUsers.mapToDictionary { $0.clients }, strategy)
    }
}

// MARK: - MLS

/// A type that can generate payloads encrypted via mls.

public protocol MLSEncryptedPayloadGenerator {

    typealias EncryptionFunction = (Data) async throws -> Data

    /// Encrypts data via MLS for sending to the backend.
    ///
    /// - Parameters:
    ///   - encrypt a function that encrpyts data using mls.
    ///
    /// - Returns:
    ///   Data encrypted with mls.
    ///
    /// - Throws: An `MLSEncryptedPayloadGeneratorError` or any error thrown from
    ///   the `encrypt` function.

    func encryptForTransport(using encrypt: EncryptionFunction) async throws -> Data

}

public enum MLSEncryptedPayloadGeneratorError: Error {

    case noContext
    case noUnencryptedData

}

extension ZMClientMessage: MLSEncryptedPayloadGenerator {

    public func encryptForTransport(using encrypt: EncryptionFunction) async throws -> Data {
        guard let context = managedObjectContext else {
            throw MLSEncryptedPayloadGeneratorError.noContext
        }

        let genericMessage = await context.perform {
            self.updateUnderlayingMessageBeforeSending(in: context)
            return self.underlyingMessage
        }

        guard let genericMessage else {
            throw MLSEncryptedPayloadGeneratorError.noUnencryptedData
        }

        return try await genericMessage.encryptForTransport(using: encrypt)
    }

}

extension ZMAssetClientMessage: MLSEncryptedPayloadGenerator {

    public func encryptForTransport(using encrypt: EncryptionFunction) async throws -> Data {
        guard let context = managedObjectContext else {
            throw MLSEncryptedPayloadGeneratorError.noContext
        }

        let genericMessage = await context.perform {
            self.updateUnderlayingMessageBeforeSending(in: context)
            return self.underlyingMessage
        }

        guard let genericMessage else {
            throw MLSEncryptedPayloadGeneratorError.noUnencryptedData
        }

        return try await genericMessage.encryptForTransport(using: encrypt)
    }

}

extension GenericMessage: MLSEncryptedPayloadGenerator {

    public func encryptForTransport(using encrypt: MLSEncryptedPayloadGenerator.EncryptionFunction) async throws -> Data {
        let unencryptedData = try unencryptedData()
        return try await encrypt(unencryptedData)
    }

    private func unencryptedData() throws -> Data {
        do {
            return try serializedData()
        } catch {
            zmLog.warn("failed to get unencrypted data from generic message: \(String(describing: error))")
            throw MLSEncryptedPayloadGeneratorError.noUnencryptedData
        }
    }

}
