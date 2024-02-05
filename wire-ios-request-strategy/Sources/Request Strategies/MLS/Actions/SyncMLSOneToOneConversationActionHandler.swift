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
            guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
                action.fail(with: .invalidResponse)
                return
            }

            let decoder = JSONDecoder.defaultDecoder
            decoder.setAPIVersion(apiVersion)

            guard
                let data = response.rawData,
                let payload = Payload.Conversation(
                    data,
                    decoder: decoder
                )
            else {
                action.fail(with: .invalidResponse)
                return
            }

            Task { [action] in
                var action = action

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

                action.succeed(with: groupID)
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
}
