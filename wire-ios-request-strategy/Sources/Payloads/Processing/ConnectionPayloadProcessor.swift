//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class ConnectionPayloadProcessor {

    func processPayload(
        _ payload: Payload.UserConnectionEvent,
        in context: NSManagedObjectContext
    ) {
        updateOrCreateConnection(
            from: payload.connection,
            in: context
        )
    }

    func updateOrCreateConnection(
        from payload: Payload.Connection,
        in context: NSManagedObjectContext
    ) {
        guard let userID = payload.to ?? payload.qualifiedTo?.uuid else {
            Logging.eventProcessing.error("Missing to field in connection payload, aborting...")
            return
        }

        let connection = ZMConnection.fetchOrCreate(
            userID: userID,
            domain: payload.qualifiedTo?.domain,
            in: context
        )

        guard let conversationID = payload.conversationID ?? payload.qualifiedConversationID?.uuid else {
            Logging.eventProcessing.error("Missing conversation field in connection payload, aborting...")
            return
        }

        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: payload.qualifiedConversationID?.domain,
            in: context
        )

        conversation.needsToBeUpdatedFromBackend = true
        conversation.lastModifiedDate = payload.lastUpdate
        conversation.addParticipantAndUpdateConversationState(user: connection.to, role: nil)

        connection.conversation = conversation
        connection.status = payload.status.internalStatus
        connection.lastUpdateDateInGMT = payload.lastUpdate

        if connection.status == .accepted {
            processAcceptedConnection(
                connection,
                in: context
            )
        }
    }

    // Actually... where do we update the conversation? Because we need to make
    // sure that we don't use proteus.
    // And we need to set the protocol to mls

    private func processAcceptedConnection(
        _ connection: ZMConnection,
        in context: NSManagedObjectContext
    ) {
        guard
            let conversation = connection.conversation,
            let otherUser = connection.to,
            let otherUserID = otherUser.remoteIdentifier,
            let otherUserDomain = otherUser.domain?.nilIfEmpty ?? BackendInfo.domain
        else {
            return
        }

        let selfUser = ZMUser.selfUser(in: context)
        let selfProtocols = selfUser.supportedProtocols
        let otherProtocols = otherUser.supportedProtocols
        let commonProtocols = selfProtocols.intersection(otherProtocols)

        if commonProtocols.contains(.mls) {
            let otherUserQualifiedID = QualifiedID(
                uuid: otherUserID,
                domain: otherUserDomain
            )

            processMLSOneToOne(
                with: otherUserQualifiedID,
                in: context
            )

        } else if commonProtocols.contains(.proteus) {
            // nothing more to do
        } else {
            conversation.isForcedReadOnly = true
        }

//        // todo: sync one to one handler
//        // there's no handler instance for this yet. But maybe it's not needed actually...
//        fetchSupportedProtocols(for: otherUser, in: context) { [weak self] result in
//            guard let self else { return }
//
//            switch result {
//            case .success(let supportedProtocols):
//                otherUser.supportedProtocols = supportedProtocols
//
//
//
//            case .failure:
//                // TODO: handle
//                break
//            }
//        }
    }

    private func fetchSupportedProtocols(
        for user: ZMUser,
        in context: NSManagedObjectContext,
        resultHandler: @escaping (Swift.Result<Set<MessageProtocol>, FetchSupportedProtocolsAction.Failure>) -> Void
    ) {
        guard
            let userID = user.remoteIdentifier,
            let domain = user.domain?.nilIfEmpty ?? BackendInfo.domain
        else {
            // TODO: error?
            return
        }

        var action = FetchSupportedProtocolsAction(
            userID: QualifiedID(
                uuid: userID,
                domain: domain
            )
        )

        action.perform(
            in: context.notificationContext,
            resultHandler: resultHandler
        )
    }

    private func processMLSOneToOne(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) {
        guard let mlsService = context.mlsService else { return }

        Task {
            try? await mlsService.establishOneToOneGroupIfNeeded(with: userID)
        }
    }

}
