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

// MARK: - Encrypted data for recipients

public protocol EncryptedPayloadGenerator {

    typealias Payload = (data: Data, strategy: MissingClientsStrategy)

    /// Produces a payload with encrypted data and the strategy to use to handle missing clients.

    func encryptForTransport() async -> Payload?

    /// Produces a payload with encrypted data and the strategy to use to handle missing clients.
    /// This variant creates a payload with qualified idenitifier suitable for federated requests.

    func encryptForTransportQualified() async -> Payload?

    var debugInfo: String { get }

}

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

// MARK: - Proteus

extension ZMClientMessage: EncryptedPayloadGenerator {

    public func encryptForTransport() async -> Payload? {
        guard
            let context = managedObjectContext,
            let conversation = await context.perform({ self.conversation })
        else {
            return nil
        }

        let underlyingMessage = await context.perform {
            self.updateUnderlayingMessageBeforeSending(in: context)
            return self.underlyingMessage
        }
        return await underlyingMessage?.encryptForTransport(for: conversation, in: context)
    }

    public func encryptForTransportQualified() async -> Payload? {
        guard
            let context = managedObjectContext,
            let conversation = await context.perform({ self.conversation })
        else {
            return nil
        }

        let underlyingMessage = await context.perform { self.updateUnderlayingMessageBeforeSending(in: context)
            return self.underlyingMessage
        }
        return await underlyingMessage?.encryptForTransport(for: conversation, in: context, useQualifiedIdentifiers: true)
    }

    public var debugInfo: String {
        return underlyingMessage?.safeForLoggingDescription ?? ""
    }

}

extension ZMAssetClientMessage: EncryptedPayloadGenerator {

    public func encryptForTransport() async -> Payload? {
        guard
            let context = managedObjectContext,
            let conversation = await context.perform({ self.conversation })
        else {
            return nil
        }

        let underlyingMessage = await context.perform { self.updateUnderlayingMessageBeforeSending(in: context)
            return self.underlyingMessage
        }
        return await underlyingMessage?.encryptForTransport(for: conversation, in: context)
    }

    public func encryptForTransportQualified() async -> Payload? {
        guard
            let context = managedObjectContext,
            let conversation = await context.perform({ self.conversation })
        else {
            return nil
        }

        let underlyingMessage = await context.perform { self.updateUnderlayingMessageBeforeSending(in: context)
            return self.underlyingMessage
        }
        return await underlyingMessage?.encryptForTransport(for: conversation, in: context, useQualifiedIdentifiers: true)
    }

    public var debugInfo: String {
        return "\(String(describing: underlyingMessage))"
    }

}

extension GenericMessage {

    /// This method needs to be async because CoreCrypto methods need to be async and it uses Proteus
    private typealias EncryptionFunction = (ProteusSessionID, Data) async throws -> Data?
    /// This is legacy encryption for CryptoBox - non async
    private typealias LegacyEncryptionFunction = (ProteusSessionID, Data) throws -> Data?

    /// Attempts to generate an encrypted payload for recipients in the given conversation.
    public func encryptForTransport(
        for conversation: ZMConversation,
        in context: NSManagedObjectContext,
        useQualifiedIdentifiers: Bool = false,
        externalData: Data? = nil
    ) async -> EncryptedPayloadGenerator.Payload? {

        let selfUser = await context.perform { ZMUser.selfUser(in: context) }
        let (users, missingClientsStrategy) = await context.perform { recipientUsersForMessage(in: conversation, selfUser: selfUser) }
        let recipients = await context.perform { users }

        var encryptedData: Data?

        let proteusProvider = await context.perform { context.proteusProvider }
        await proteusProvider.performAsync(
            withProteusService: { proteusService in
                encryptedData = await encrypt(
                    using: proteusService,
                    for: recipients,
                    with: missingClientsStrategy,
                    externalData: externalData,
                    useQualifiedIdentifiers: useQualifiedIdentifiers,
                    in: context
                )
            },
            withKeyStore: { keyStore in
                encryptedData = await context.perform {
                    legacyEncrypt(
                        using: keyStore,
                        for: recipients,
                        with: missingClientsStrategy,
                        externalData: externalData,
                        useQualifiedIdentifiers: useQualifiedIdentifiers,
                        in: context
                    )
                }
            }
        )

        guard let encryptedData else {
            return nil
        }

        return (encryptedData, missingClientsStrategy)
    }

    /// Attempts to generate an encrypted payload for the given set of users.

    public func encryptForTransport(
        forBroadcastRecipients recipients: Set<ZMUser>,
        useQualifiedIdentifiers: Bool = false,
        in context: NSManagedObjectContext
    ) async -> EncryptedPayloadGenerator.Payload? {
        // It's important to ignore all irrelevant missing clients, because otherwise the backend will enforce that
        // the message is sent to all team members and contacts.
        let qualifiedIds = recipients.compactMap({ user in
            user.qualifiedID
        })
        let missingClientsStrategy = MissingClientsStrategy.ignoreAllMissingClientsNotFromUsers(userIds: Set(qualifiedIds))

        let messageRecipients = await context.perform { recipients.mapToDictionary { $0.clients } }
        var encryptedData: Data?

        let proteusProvider = await context.perform { context.proteusProvider }
        await proteusProvider.performAsync(
            withProteusService: { proteusService in
                encryptedData = await encrypt(
                    using: proteusService,
                    for: messageRecipients,
                    with: missingClientsStrategy,
                    useQualifiedIdentifiers: useQualifiedIdentifiers,
                    in: context
                )
            },
            withKeyStore: { keyStore in
                await context.perform {
                    encryptedData = legacyEncrypt(
                        using: keyStore,
                        for: messageRecipients,
                        with: missingClientsStrategy,
                        useQualifiedIdentifiers: useQualifiedIdentifiers,
                        in: context
                    )
                }
            }
        )

        guard let encryptedData else {
            return nil
        }

        return (encryptedData, missingClientsStrategy)
    }

    /// Attempts to generate an encrypted payload for the given collection of user clients.

    public func encryptForTransport(
        for recipients: [ZMUser: Set<UserClient>],
        useQualifiedIdentifiers: Bool = false,
        in context: NSManagedObjectContext
    ) async -> EncryptedPayloadGenerator.Payload? {
        // We're targeting a specific client so we want to ignore all missing clients.
        let missingClientsStrategy = MissingClientsStrategy.ignoreAllMissingClients
        var encryptedData: Data?

        let proteusProvider = await context.perform { context.proteusProvider }
        await proteusProvider.performAsync(
            withProteusService: { proteusService in
                encryptedData = await encrypt(
                    using: proteusService,
                    for: recipients,
                    with: missingClientsStrategy,
                    useQualifiedIdentifiers: useQualifiedIdentifiers,
                    in: context
                )
            },
            withKeyStore: { keyStore in
                await context.perform {
                    encryptedData = legacyEncrypt(
                        using: keyStore,
                        for: recipients,
                        with: missingClientsStrategy,
                        useQualifiedIdentifiers: useQualifiedIdentifiers,
                        in: context
                    )
                }
            }
        )

        guard let encryptedData else {
            return nil
        }

        return (encryptedData, missingClientsStrategy)
    }

    private func encrypt(
        using proteusService: ProteusServiceInterface,
        for recipients: [ZMUser: Set<UserClient>],
        with missingClientsStrategy: MissingClientsStrategy,
        externalData: Data? = nil,
        useQualifiedIdentifiers: Bool = false,
        in context: NSManagedObjectContext
    ) async -> Data? {

        let selfClient = await context.perform {
            let user = ZMUser.selfUser(in: context).selfClient()
            if user?.remoteIdentifier != nil {
                return user
            }
            return nil
        }
        guard let selfClient else { return nil }

        var messageData: Data?

        if useQualifiedIdentifiers,
            let selfDomain = await context.perform({ ZMUser.selfUser(in: context).domain }) {

            let message = await proteusMessage(
                selfClient,
                selfDomain: selfDomain,
                recipients: recipients,
                missingClientsStrategy: missingClientsStrategy,
                externalData: externalData,
                context: context
            ) { sessionID, plainText in
                try await proteusService.encrypt(
                    data: plainText,
                    forSession: sessionID
                )
            }

            messageData = try? message.serializedData()

        } else {
            let message = await otrMessage(
                selfClient,
                recipients: recipients,
                missingClientsStrategy: missingClientsStrategy,
                externalData: externalData,
                context: context
            ) { sessionID, plainText in
                try await proteusService.encrypt(
                    data: plainText,
                    forSession: sessionID
                )
            }

            messageData = try? message.serializedData()
        }

        // Message too big?
        if let data = messageData, UInt(data.count) > ZMClientMessage.byteSizeExternalThreshold && externalData == nil {
            // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
            // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
            messageData = await self.encryptForTransportWithExternalDataBlob(
                for: recipients,
                with: missingClientsStrategy,
                useQualifiedIdentifiers: useQualifiedIdentifiers,
                in: context
            )
        }

        // Reset all failed sessions.
        await context.perform {
            recipients.values
                .flatMap { $0 }
                .forEach { $0.failedToEstablishSession = false }
        }
        return messageData
    }

    private func legacyEncrypt(
        using keyStore: UserClientKeysStore,
        for recipients: [ZMUser: Set<UserClient>],
        with missingClientsStrategy: MissingClientsStrategy,
        externalData: Data? = nil,
        useQualifiedIdentifiers: Bool = false,
        in context: NSManagedObjectContext
    ) -> Data? {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient(), selfClient.remoteIdentifier != nil else {
            return Data?.none
        }

        var messageData: Data?
        keyStore.encryptionContext.perform { sessionsDirectory in

            // don't capture sessionsDirectory outside of this perform below
            let encryptionFunction: LegacyEncryptionFunction = { [weak sessionsDirectory] sessionID, plainText in
                guard let directory = sessionsDirectory else {
                    assertionFailure("should have sessionsDirectory from cryptobox")
                    return nil
                }
                return try directory.encryptCaching(
                    plainText,
                    for: sessionID.mapToEncryptionSessionID()
                )
            }

            if useQualifiedIdentifiers, let selfDomain = context.performAndWait({ ZMUser.selfUser(in: context).domain }) {
                let message = legacyProteusMessage(
                    selfClient,
                    selfDomain: selfDomain,
                    recipients: recipients,
                    missingClientsStrategy: missingClientsStrategy,
                    externalData: externalData,
                    context: context,
                    using: encryptionFunction
                )

                messageData = try? message.serializedData()

            } else {
                let message = legacyOtrMessage(
                    selfClient,
                    recipients: recipients,
                    missingClientsStrategy: missingClientsStrategy,
                    externalData: externalData,
                    context: context,
                    using: encryptionFunction
                )

                messageData = try? message.serializedData()
            }

            // Message too big?
            if let data = messageData, UInt(data.count) > ZMClientMessage.byteSizeExternalThreshold && externalData == nil {
                // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
                // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
                sessionsDirectory.discardCache()
                messageData = self.encryptForTransportWithExternalDataBlob(
                    for: recipients,
                    with: missingClientsStrategy,
                    useQualifiedIdentifiers: useQualifiedIdentifiers,
                    in: context
                )
            }
        }

        // Reset all failed sessions.
        recipients.values
            .flatMap { $0 }
            .forEach { $0.failedToEstablishSession = false }

        return messageData
    }

    private func proteusMessage(
        _ selfClient: UserClient,
        selfDomain: String,
        recipients: [ZMUser: Set<UserClient>],
        missingClientsStrategy: MissingClientsStrategy,
        externalData: Data?,
        context: NSManagedObjectContext,
        using encryptionFunction: EncryptionFunction
    ) async -> Proteus_QualifiedNewOtrMessage {
        let qualifiedUserEntries = await qualifiedUserEntriesWithEncryptedData(
            selfClient,
            selfDomain: selfDomain,
            recipients: recipients,
            context: context,
            using: encryptionFunction
        )

        // We do not want to send pushes for delivery receipts.
        let nativePush = !hasConfirmation

        return await context.perform {
            Proteus_QualifiedNewOtrMessage(
                withSender: selfClient,
                nativePush: nativePush,
                recipients: qualifiedUserEntries,
                missingClientsStrategy: missingClientsStrategy,
                blob: externalData
            )
        }
    }

    private func legacyProteusMessage(
           _ selfClient: UserClient,
           selfDomain: String,
           recipients: [ZMUser: Set<UserClient>],
           missingClientsStrategy: MissingClientsStrategy,
           externalData: Data?,
           context: NSManagedObjectContext,
           using encryptionFunction: LegacyEncryptionFunction
       ) -> Proteus_QualifiedNewOtrMessage {
           let qualifiedUserEntries = legacyQualifiedUserEntriesWithEncryptedData(
               selfClient,
               selfDomain: selfDomain,
               recipients: recipients,
               context: context,
               using: encryptionFunction
           )

           // We do not want to send pushes for delivery receipts.
           let nativePush = !hasConfirmation

           return context.performAndWait {
               Proteus_QualifiedNewOtrMessage(
                   withSender: selfClient,
                   nativePush: nativePush,
                   recipients: qualifiedUserEntries,
                   missingClientsStrategy: missingClientsStrategy,
                   blob: externalData
               )
           }
       }

    private func legacyOtrMessage(
           _ selfClient: UserClient,
           recipients: [ZMUser: Set<UserClient>],
           missingClientsStrategy: MissingClientsStrategy,
           externalData: Data?,
           context: NSManagedObjectContext,
           using encryptionFunction: LegacyEncryptionFunction
       ) -> Proteus_NewOtrMessage {
           let userEntries = legacyUserEntriesWithEncryptedData(
               selfClient,
               recipients: recipients,
               context: context,
               using: encryptionFunction
           )

           // We do not want to send pushes for delivery receipts.
           let nativePush = !hasConfirmation

           let message = context.performAndWait {
               let message = Proteus_NewOtrMessage(
                withSenderId: selfClient.clientId.client,
                   nativePush: nativePush,
                   recipients: userEntries,
                   missingClientsStrategy: missingClientsStrategy,
                   blob: externalData
               )
               return message
           }

           return message
       }

    /// Returns a message for the given recipients.

    private func otrMessage(
        _ selfClient: UserClient,
        recipients: [ZMUser: Set<UserClient>],
        missingClientsStrategy: MissingClientsStrategy,
        externalData: Data?,
        context: NSManagedObjectContext,
        using encryptionFunction: EncryptionFunction
    ) async -> Proteus_NewOtrMessage {
        let userEntries = await userEntriesWithEncryptedData(
            selfClient,
            recipients: recipients,
            context: context,
            using: encryptionFunction
        )

        // We do not want to send pushes for delivery receipts.
        let nativePush = !hasConfirmation

        let message = await context.perform {
            let message = Proteus_NewOtrMessage(
                withSenderId: selfClient.clientId.client,
                nativePush: nativePush,
                recipients: userEntries,
                missingClientsStrategy: missingClientsStrategy,
                blob: externalData
            )

            return message
        }

        return message
    }

    private func qualifiedUserEntriesWithEncryptedData(
        _ selfClient: UserClient,
        selfDomain: String,
        recipients: [ZMUser: Set<UserClient>],
        context: NSManagedObjectContext,
        using encryptionFunction: EncryptionFunction
    ) async -> [Proteus_QualifiedUserEntry] {

        let recipientsByDomain = await context.perform {
            Dictionary(grouping: recipients) { element -> String in
                element.key.domain ?? selfDomain
            }
        }

        var qualifiedUserEntries = [Proteus_QualifiedUserEntry]()
        for (domain, recipients) in recipientsByDomain {

            var userEntries = [Proteus_UserEntry]()
            for (user, clients) in recipients {
                guard await context.perform({ !user.isAccountDeleted }) else { continue }

                let clientEntries = await clientEntriesWithEncryptedData(
                    selfClient,
                    userClients: clients,
                    context: context,
                    using: encryptionFunction
                )
                if !clientEntries.isEmpty {
                    let userEntry = await context.perform { Proteus_UserEntry(withUser: user, clientEntries: clientEntries) }
                    userEntries.append(userEntry)
                }
            }
            qualifiedUserEntries.append(.init(withDomain: domain, userEntries: userEntries))
        }
        return qualifiedUserEntries
    }

    private func legacyQualifiedUserEntriesWithEncryptedData(
        _ selfClient: UserClient,
        selfDomain: String,
        recipients: [ZMUser: Set<UserClient>],
        context: NSManagedObjectContext,
        using encryptionFunction: LegacyEncryptionFunction
    ) -> [Proteus_QualifiedUserEntry] {
        let recipientsByDomain = context.performAndWait {
            Dictionary(grouping: recipients) { element -> String in
                element.key.domain ?? selfDomain
            }
        }

        return recipientsByDomain.compactMap { domain, recipients in
            let userEntries: [Proteus_UserEntry] = recipients.compactMap { user, clients in
                guard context.performAndWait({ !user.isAccountDeleted }) else { return nil }

                let clientEntries = legacyClientEntriesWithEncryptedData(
                    selfClient,
                    userClients: clients,
                    context: context,
                    using: encryptionFunction
                )

                guard !clientEntries.isEmpty else { return nil }

                return context.performAndWait { Proteus_UserEntry(withUser: user, clientEntries: clientEntries) }
            }

            return Proteus_QualifiedUserEntry(withDomain: domain, userEntries: userEntries)
        }
    }

    private func userEntriesWithEncryptedData(
        _ selfClient: UserClient,
        recipients: [ZMUser: Set<UserClient>],
        context: NSManagedObjectContext,
        using encryptionFunction: EncryptionFunction
    ) async -> [Proteus_UserEntry] {

        var userEntries = [Proteus_UserEntry]()
        for (user, clients) in recipients {
            guard await context.perform({ !user.isAccountDeleted }) else { continue }

            let clientEntries = await clientEntriesWithEncryptedData(
                selfClient,
                userClients: clients,
                context: context,
                using: encryptionFunction
            )
            if !clientEntries.isEmpty {
                await context.perform {
                    userEntries.append(.init(withUser: user, clientEntries: clientEntries))
                }
            }
        }
        return userEntries
    }

    private func legacyUserEntriesWithEncryptedData(
         _ selfClient: UserClient,
         recipients: [ZMUser: Set<UserClient>],
         context: NSManagedObjectContext,
         using encryptionFunction: LegacyEncryptionFunction
     ) -> [Proteus_UserEntry] {
         context.performAndWait {
             recipients.compactMap { user, clients in
                 guard !user.isAccountDeleted else { return nil }

                 let clientEntries = legacyClientEntriesWithEncryptedData(
                    selfClient,
                    userClients: clients,
                    context: context,
                    using: encryptionFunction
                 )

                 guard !clientEntries.isEmpty else { return nil }

                 return Proteus_UserEntry(withUser: user, clientEntries: clientEntries)
             }
         }
     }

    private func clientEntriesWithEncryptedData(
        _ selfClient: UserClient,
        userClients: Set<UserClient>,
        context: NSManagedObjectContext,
        using encryptionFunction: EncryptionFunction
    ) async -> [Proteus_ClientEntry] {

        let filteredClientEntries = await context.perform {
            userClients.compactMap {
                if $0 != selfClient {
                    return ClientEntry(client: $0, context: context)
                } else {
                    return nil
                }
            }
        }

        var clientEntries = [Proteus_ClientEntry]()
        for client in filteredClientEntries {
            if let clientEntry = await clientEntry(for: client, using: encryptionFunction) {
                clientEntries.append(clientEntry)
            }
        }
        return clientEntries
    }

    private func legacyClientEntriesWithEncryptedData(
           _ selfClient: UserClient,
           userClients: Set<UserClient>,
           context: NSManagedObjectContext,
           using encryptionFunction: LegacyEncryptionFunction
       ) -> [Proteus_ClientEntry] {
           return userClients.compactMap { client in
               guard client != selfClient else { return nil }
               return legacyClientEntry(for: client, using: encryptionFunction)
           }
       }

    struct ClientEntry {
        var client: UserClient
        var context: NSManagedObjectContext

        var proteusSessionID: ProteusSessionID? {
            get async {
                await context.perform { client.proteusSessionID }
            }
        }

        var failedToEstablishSession: Bool {
            get async {
                await context.perform({ client.failedToEstablishSession })
            }
        }

        var loggedId: String {
            get async {
                await context.perform { String(describing: client.remoteIdentifier) }
            }
        }

        func proteusClientEntry(with data: Data) async -> Proteus_ClientEntry {
            let id = await context.perform {
                client.clientId
            }
            return Proteus_ClientEntry(withClientId: id, data: data)
        }
    }

    // Assumes it's not the self client.
    private func clientEntry(
        for client: ClientEntry,
        using encryptionFunction: EncryptionFunction
    ) async -> Proteus_ClientEntry? {
        guard let sessionID = await client.proteusSessionID else {
            return nil
        }

        guard await !client.failedToEstablishSession else {
            // If the session is corrupted, we will send a special payload.
            let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8)!
            WireLogger.proteus.error("Failed to encrypt payload: session is not established with client: \(await client.loggedId)")
            return await client.proteusClientEntry(with: data)
        }

        do {
            let plainText = try serializedData()
            let encryptedData = try await encryptionFunction(sessionID, plainText)
            guard let data = encryptedData else { return nil }
            return await client.proteusClientEntry(with: data)
        } catch {
            // this is handled by message sender, it's just that we don't throw the errors
            return nil
        }
    }

    private func legacyClientEntry(
           for client: UserClient,
           using encryptionFunction: LegacyEncryptionFunction
       ) -> Proteus_ClientEntry? {
           guard let sessionID = client.proteusSessionID else {
               return nil
           }

           guard !client.failedToEstablishSession else {
               // If the session is corrupted, we will send a special payload.
               let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8)!
               WireLogger.proteus.error("Failed to encrypt payload: session is not established with client: " + String(describing: client.remoteIdentifier))
               return Proteus_ClientEntry(withClientId: client.clientId, data: data)
           }

           do {
               let plainText = try serializedData()
               let encryptedData = try encryptionFunction(sessionID, plainText)
               guard let data = encryptedData else { return nil }
               return Proteus_ClientEntry(withClientId: client.clientId, data: data)
           } catch {
               WireLogger.proteus.error("failed to encrypt payload for a client: \(String(describing: error))")
               return nil
           }
       }

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

// MARK: - External

extension GenericMessage {

    /// Returns a message with recipients, with the content stored externally, and a strategy to handle missing clients.

    private func encryptForTransportWithExternalDataBlob(for conversation: ZMConversation, in context: NSManagedObjectContext) async -> EncryptedPayloadGenerator.Payload? {
        guard let encryptedDataWithKeys = GenericMessage.encryptedDataWithKeys(from: self) else { return nil }
        let externalGenericMessage = GenericMessage(content: External(withKeyWithChecksum: encryptedDataWithKeys.keys))
        return await externalGenericMessage.encryptForTransport(for: conversation, in: context, externalData: encryptedDataWithKeys.data)
    }

    private func encryptForTransportWithExternalDataBlob(
        for recipients: [ZMUser: Set<UserClient>],
        with missingClientsStrategy: MissingClientsStrategy,
        useQualifiedIdentifiers: Bool = false,
        in context: NSManagedObjectContext
    ) async -> Data? {
        guard
            let encryptedDataWithKeys = GenericMessage.encryptedDataWithKeys(from: self),
            let data = encryptedDataWithKeys.data,
            let keys = encryptedDataWithKeys.keys
        else {
            return nil
        }

        let externalGenericMessage = GenericMessage(content: External(withKeyWithChecksum: keys))
        var encryptedData: Data?

        let proteusProvider = await context.perform { context.proteusProvider }
        await proteusProvider.performAsync(
            withProteusService: { proteusService in
                encryptedData = await externalGenericMessage.encrypt(
                    using: proteusService,
                    for: recipients,
                    with: missingClientsStrategy,
                    externalData: data,
                    useQualifiedIdentifiers: useQualifiedIdentifiers,
                    in: context
                )
            },
            withKeyStore: { keyStore in
                encryptedData = externalGenericMessage.legacyEncrypt(
                    using: keyStore,
                    for: recipients,
                    with: missingClientsStrategy,
                    externalData: data,
                    useQualifiedIdentifiers: useQualifiedIdentifiers,
                    in: context
                )
            }
        )

        return encryptedData
    }

    private func encryptForTransportWithExternalDataBlob(
           for recipients: [ZMUser: Set<UserClient>],
           with missingClientsStrategy: MissingClientsStrategy,
           useQualifiedIdentifiers: Bool = false,
           in context: NSManagedObjectContext
       ) -> Data? {
           guard
               let encryptedDataWithKeys = GenericMessage.encryptedDataWithKeys(from: self),
               let data = encryptedDataWithKeys.data,
               let keys = encryptedDataWithKeys.keys
           else {
               return nil
           }

           let externalGenericMessage = GenericMessage(content: External(withKeyWithChecksum: keys))
           var encryptedData: Data?

           let proteusProvider = context.performAndWait { context.proteusProvider }
           proteusProvider.perform(
               withProteusService: { _ in
                   // nothing
                   assertionFailure("should not be called for CC Proteus")
               },
               withKeyStore: { keyStore in
                   encryptedData = externalGenericMessage.legacyEncrypt(
                       using: keyStore,
                       for: recipients,
                       with: missingClientsStrategy,
                       externalData: data,
                       useQualifiedIdentifiers: useQualifiedIdentifiers,
                       in: context
                   )
               }
           )

           return encryptedData
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
