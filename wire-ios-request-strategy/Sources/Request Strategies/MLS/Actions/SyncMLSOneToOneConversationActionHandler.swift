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
import WireDataModel

final class SyncMLSOneToOneConversationActionHandler: ActionHandler<SyncMLSOneToOneConversationAction> {

    private lazy var processor = ConversationEventPayloadProcessor(
        mlsEventProcessor: MLSEventProcessor(context: context),
        removeLocalConversation: RemoveLocalConversationUseCase()
    )

    // MARK: - Request

    override func request(
        for action: SyncMLSOneToOneConversationAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard apiVersion >= .v5 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        let userID = action.userID.transportString()
        let domain = action.domain

        guard !domain.isEmpty else {
            action.fail(with: .invalidDomain)
            return nil
        }

        return ZMTransportRequest(
            getFromPath: "/conversations/one2one/\(domain)/\(userID)",
            apiVersion: apiVersion.rawValue
        )
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: SyncMLSOneToOneConversationAction
    ) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard
                let apiVersion = APIVersion(rawValue: response.apiVersion),
                let data = response.rawData,
                !data.isEmpty
            else {
                action.fail(with: .invalidResponse)
                return
            }

            let decoder = JSONDecoder.defaultDecoder
            decoder.setAPIVersion(apiVersion)

            switch apiVersion {
            case .v0, .v1, .v2, .v3, .v4:
                action.fail(with: .endpointUnavailable)

            case .v5:
                guard let payload = Payload.Conversation(data, decoder: decoder) else {
                    action.fail(with: .invalidResponse)
                    return
                }
                updateOrCreateConversation(
                    action: action,
                    payload: payload)

            case .v6:
                guard
                    let result = Payload.ConversationWithRemovalKeys(data, decoder: decoder),
                    let payload = result.conversation
                else {
                    action.fail(with: .invalidResponse)
                    return
                }
                let publicKeys = result.publicKeys?.toBackendMLSPublicKeys()
                updateOrCreateConversation(
                    action: action,
                    payload: payload,
                    publicKeys: publicKeys)
            }

        case (400, "mls-not-enabled"):
            action.fail(with: .mlsNotEnabled)

        case (403, "not-connected"):
            action.fail(with: .usersNotConnected)

        default:
            let errorInfo = response.errorInfo
            action.fail(with: .unknown(status: errorInfo.status, label: errorInfo.label, message: errorInfo.message))
        }
    }

    private func updateOrCreateConversation(
        action: SyncMLSOneToOneConversationAction,
        payload: Payload.Conversation,
        publicKeys: BackendMLSPublicKeys? = nil
    ) {
        Task { [action] in
            var action = action

            // TODO: [WPB-7415] backend doesn't always include the other member
            var payload = payload
            payload.addMissingMember(userID: QualifiedID(uuid: action.userID, domain: action.domain))

            guard
                let conversation = await processor.updateOrCreateConversation(
                    from: payload,
                    in: context
                ),
                let groupID = await context.perform({ conversation.mlsGroupID })
            else {
                action.fail(with: .failedToProcessResponse)
                return
            }

            action.succeed(with: (groupID: groupID, publicKeys: publicKeys))
        }

    }
}

private extension Payload.Conversation {

    mutating func addMissingMember(userID: QualifiedID) {
        guard
            let selfMember = members?.selfMember,
            members?.others.isEmpty == true
        else { return }

        members = Payload.ConversationMembers(
            selfMember: selfMember,
            others: [Payload.ConversationMember(
                id: userID.uuid,
                qualifiedID: userID,
                target: nil,
                qualifiedTarget: nil,
                service: nil,
                mutedStatus: nil,
                mutedReference: nil,
                archived: nil,
                archivedReference: nil,
                hidden: nil,
                hiddenReference: nil,
                conversationRole: nil
            )]
        )
    }
}

extension Payload {

    struct ConversationWithRemovalKeys: Codable {

        enum CodingKeys: String, CodingKey {
            case conversation
            case publicKeys = "public_keys"
        }

        let conversation: Payload.Conversation?
        let publicKeys: ExternalSenderKeys?

    }

}

private extension Payload.ExternalSenderKeys {

    func toBackendMLSPublicKeys() -> BackendMLSPublicKeys? {
        let ed25519RemovalKey = removal.ed25519
            .flatMap(\.base64DecodedBytes)
            .map(\.data)

        let ed448RemovalKey = removal.ed448
            .flatMap(\.base64DecodedBytes)
            .map(\.data)

        let p256RemovalKey = removal.p256
            .flatMap(\.base64DecodedBytes)
            .map(\.data)

        let p384RemovalKey = removal.p384
            .flatMap(\.base64DecodedBytes)
            .map(\.data)

        let p521RemovalKey = removal.p521
            .flatMap(\.base64DecodedBytes)
            .map(\.data)

        return BackendMLSPublicKeys(removal:
                .init(ed25519: ed25519RemovalKey,
                      ed448: ed448RemovalKey,
                      p256: p256RemovalKey,
                      p384: p384RemovalKey,
                      p521: p521RemovalKey))
    }

}
