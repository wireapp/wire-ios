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

import WireDataModel

final class UpdateConversationProtocolActionHandler: ActionHandler<UpdateConversationProtocolAction> {

    typealias EventPayload = [AnyHashable: Any]

    // MARK: - Methods

    override func request(
        for action: Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        var action = action

        guard apiVersion >= .v5 else {
            action.fail(with: .endpointUnavailable)
            return .none
        }

        let path = "/conversations/\(action.domain)/\(action.conversationID.transportString())/protocol"
        let payload = ["protocol": action.messageProtocol.stringValue] as ZMTransportData

        return .init(
            path: "",
            method: .put,
            payload: payload,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: Action
    ) {
        var action = action

        /*
        response.httpStatus, response.payloadLabel()

        if let error = Action.Failure(from: response) {
            action.fail(with: error)
        } else {
            guard
                let payload = response.payload?.asDictionary(),
                let eventsData = payload["events"] as? [EventPayload]
            else {
                action.fail(with: .malformedResponse)
                return
            }

            let updateEvents = eventsData.compactMap { eventData in
                ZMUpdateEvent(
                    uuid: nil,
                    payload: eventData,
                    transient: false,
                    decrypted: false,
                    source: .download
                )
            }

            action.succeed(with: updateEvents)
        }
         */
    }

}
