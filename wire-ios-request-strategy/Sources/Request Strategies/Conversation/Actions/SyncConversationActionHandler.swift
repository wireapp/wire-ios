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

final class SyncConversationActionHandler: ActionHandler<SyncConversationAction> {
    // MARK: Internal

    // MARK: - Request generation

    struct RequestPayload: Codable, Equatable {
        let qualified_ids: [QualifiedID]
    }

    // MARK: - Response handling

    struct ResponsePayload: Codable {
        let found: [Payload.Conversation]
        let failed: [QualifiedID]
        let not_found: [QualifiedID]
    }

    override func request(
        for action: SyncConversationAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard let payload = RequestPayload(qualified_ids: [action.qualifiedID]).payloadString() else {
            action.fail(with: .malformedRequestPayload)
            return nil
        }

        switch apiVersion {
        case .v0,
             .v1:
            return ZMTransportRequest(
                path: "/conversations/list/v2",
                method: .post,
                payload: payload as ZMTransportData,
                apiVersion: apiVersion.rawValue
            )

        case .v2,
             .v3,
             .v4,
             .v5,
             .v6:
            return ZMTransportRequest(
                path: "/conversations/list",
                method: .post,
                payload: payload as ZMTransportData,
                apiVersion: apiVersion.rawValue
            )
        }
    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: SyncConversationAction
    ) {
        var action = action

        switch response.httpStatus {
        case 200:
            guard
                let data = response.rawData,
                let payload = ResponsePayload(data)
            else {
                action.fail(with: .invalidResponsePayload)
                return
            }

            guard let conversationData = payload.found.first else {
                action.fail(with: .conversationNotFound)
                return
            }

            Task { [action, context] in
                await processor.updateOrCreateConversation(
                    from: conversationData,
                    in: context
                )
                await context.perform {
                    do {
                        try context.save()
                    } catch {
                        Logging.network.warn("SyncConversationActionHandler: failed to save context: \(error)")
                        assertionFailure("SyncConversationActionHandler: failed to save context: \(error)")
                    }
                }

                var action = action
                action.succeed()
            }

        case 400:
            action.fail(with: .invalidBody)

        default:
            let error = response.errorInfo
            action.fail(with: .unknownError(code: error.status, label: error.label, message: error.message))
        }
    }

    // MARK: Private

    private lazy var processor = ConversationEventPayloadProcessor(
        mlsEventProcessor: MLSEventProcessor(context: context),
        removeLocalConversation: RemoveLocalConversationUseCase()
    )
}
