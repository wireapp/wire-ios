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

import WireDataModel
import WireTransport

private let zmLog = ZMSLog(tag: "Dependencies")

public protocol OTREntity: AnyObject {
    /// NSManagedObjectContext which the OTR entity is associated with.
    var context: NSManagedObjectContext { get }

    /// Conversation in which the OTR entity is sent. If the OTR entity is not associated with
    /// any conversation this property should return nil.
    var conversation: ZMConversation? { get }

    /// Other entities which has to complete an update before this entity can be processed, i.e. another message
    /// needs to be sent first because it was scheduled for sending before this message.
    var dependentObjectNeedingUpdateBeforeProcessing: NSObject? { get }

    /// This message entity has expired and no more attempt will be made to sent it
    var isExpired: Bool { get }

    /// This message entity should be ignored for security level check
    var shouldIgnoreTheSecurityLevelCheck: Bool { get }

    /// Date when the message will expire unless it has been sent by then.
    var expirationDate: Date? { get }

    /// The reason why a message did expire
    var expirationReasonCode: NSNumber? { get set }

    /// Add clients as missing recipients for this entity. If we want to resend
    /// the entity, we need to make sure those missing recipients are fetched
    /// or sending the entity will fail again.
    func missesRecipients(_ recipients: Set<WireDataModel.UserClient>!)

    /// if the BE tells us that these users are not in the
    /// conversation anymore, it means that we are out of sync
    /// with the list of participants
    func detectedRedundantUsers(_ users: [ZMUser])

    func delivered(with response: ZMTransportResponse)

    /// Add users who didn't receive the message to failedToSendRecipients
    func addFailedToSendRecipients(_ recipients: [ZMUser])

    /// Mark the message as expired
    func expire()
}

/// HTTP status of a request that has
private let ClientNotAuthorizedResponseStatus = 403

/// Label for clients that are missing from the uploaded payload
private let MissingLabel = "missing"

/// Label for clients that were deleted and are still present in the uploaded payload
private let DeletedLabel = "deleted"

/// Label for clients whose user was removed from the conversation but we still think it is in the conversation
private let RedundantLabel = "redundant"

/// Label error for uploading a message with a client that does not exist
private let UnknownClientLabel = "unknown-client"

/// Error label
private let ErrorLabel = "label"

extension OTREntity {
    /// Which object this message depends on when sending
    public func dependentObjectNeedingUpdateBeforeProcessingOTREntity(in conversation: ZMConversation)
        -> ZMManagedObject? {
        // If we receive a missing payload that includes users that are not part of the conversation,
        // we need to refetch the conversation before recreating the message payload.
        // Otherwise we end up in an endless loop receiving missing clients error
        if conversation.needsToBeUpdatedFromBackend || conversation.needsToVerifyLegalHold {
            zmLog.debug("conversation needs to be update from backend")
            return conversation
        }

        if conversation.conversationType == .oneOnOne || conversation.conversationType == .connection,
           conversation.oneOnOneUser?.connection?.needsToBeUpdatedFromBackend == true {
            zmLog.debug("connection needs to be update from backend")
            return conversation.oneOnOneUser?.connection
        }

        return dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: conversation.localParticipants)
    }

    /// Which objects this message depends on when sending it to a list recipients
    public func dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: Set<ZMUser>) -> ZMManagedObject? {
        let recipientClients = recipients.flatMap {
            Array($0.clients)
        }

        // If we discovered a new client we need fetch the client details before retrying
        if let newClient = recipientClients.first(where: { $0.needsToBeUpdatedFromBackend }) {
            return newClient
        }

        return nil
    }

    typealias ClientChanges = (missingClients: Set<UserClient>, deletedClients: Set<UserClient>)

    func processEmptyUploadResponse(
        _ response: ZMTransportResponse,
        in conversation: ZMConversation,
        clientRegistrationDelegate: ClientRegistrationDelegate
    ) -> ClientChanges {
        guard !detectedDeletedSelfClient(in: response) else {
            clientRegistrationDelegate.didDetectCurrentClientDeletion()
            return (missingClients: Set(), deletedClients: Set())
        }

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
            return (missingClients: Set(), deletedClients: Set())
        }

        let processor = MessageSendingStatusPayloadProcessor()

        var clientListByUser = Payload.ClientListByUser()
        switch apiVersion {
        case .v0:
            guard
                let payload = response.payload as? [String: AnyObject],
                let clientListByUserID = payload[MissingLabel] as? Payload.ClientListByUserID
            else {
                return (missingClients: Set(), deletedClients: Set())
            }

            clientListByUser = processor.materializingUsers(
                from: clientListByUserID,
                withDomain: nil,
                in: context
            )

        case .v1, .v2, .v3:
            guard let payload = Payload.MessageSendingStatusV1(
                response,
                decoder: .defaultDecoder
            ) else {
                return (missingClients: Set(), deletedClients: Set())
            }

            clientListByUser = processor.missingClientListByUser(
                from: payload.toAPIModel(),
                context: context
            )

        case .v4, .v5, .v6:
            guard let payload = Payload.MessageSendingStatusV4(response) else {
                return (missingClients: Set(), deletedClients: Set())
            }

            clientListByUser = processor.missingClientListByUser(
                from: payload.toAPIModel(),
                context: context
            )
        }

        return parseMissingClients(clientListByUser, in: conversation)
    }

    private func parseMissingClients(
        _ clientListByUser: Payload.ClientListByUser,
        in conversation: ZMConversation
    ) -> ClientChanges {
        // 1) Parse the payload

        var changes: ZMConversationRemoteClientChangeSet = []
        var allMissingClients: Set<UserClient> = []
        var allDeletedClients: Set<UserClient> = []
        var redundantUsers = conversation.localParticipants

        redundantUsers.remove(ZMUser.selfUser(in: context))

        for (user, remoteClientIdentifiers) in clientListByUser {
            if user.isSelfUser { continue }

            redundantUsers.remove(user)

            let remoteIdentifiers = Set(remoteClientIdentifiers)
            let localIdentifiers = Set(user.clients.compactMap(\.remoteIdentifier))

            // Compute changes
            let deletedClients = localIdentifiers.subtracting(remoteIdentifiers)
            if !deletedClients.isEmpty { changes.insert(.deleted) }

            let missingClients = remoteIdentifiers.subtracting(localIdentifiers)
            if !missingClients.isEmpty { changes.insert(.missing) }

            // Process deletions
            for deletedClientID in deletedClients {
                if let client = UserClient.fetchUserClient(
                    withRemoteId: deletedClientID,
                    forUser: user,
                    createIfNeeded: false
                ) {
                    allDeletedClients.insert(client)
                }
            }

            // Process missing clients
            let userMissingClients: [UserClient] = missingClients.map {
                let client = UserClient.fetchUserClient(withRemoteId: $0, forUser: user, createIfNeeded: true)!
                client.discoveredByMessage = self as? ZMOTRMessage
                return client
            }

            if !userMissingClients.isEmpty {
                allMissingClients.formUnion(userMissingClients)
            }
        }

        let redundantClients = Set(redundantUsers.flatMap(\.clients))
        allDeletedClients = allDeletedClients.union(redundantClients)

        return (missingClients: allMissingClients, deletedClients: allDeletedClients)
    }

    private func detectedDeletedSelfClient(in response: ZMTransportResponse) -> Bool {
        // In case the self client got deleted remotely we will receive an event through the push channel and log out.
        // If we for some reason miss the push the BE will repond with a 403 and 'unknown-client' label to our
        // next sending attempt and we will logout and delete the current selfClient then
        if response.httpStatus == ClientNotAuthorizedResponseStatus,
           let payload = response.payload as? [String: AnyObject],
           let label = payload[ErrorLabel] as? String,
           label == UnknownClientLabel {
            true
        } else {
            false
        }
    }

    /// Adds clients to those missing for this message
    func registersNewMissingClients(_ missingClients: Set<UserClient>) {
        guard !missingClients.isEmpty else { return }

        let selfClient = ZMUser.selfUser(in: self.context).selfClient()!
        selfClient.missesClients(missingClients)
        self.missesRecipients(missingClients)

        selfClient.addNewClientsToIgnored(missingClients)
    }
}
