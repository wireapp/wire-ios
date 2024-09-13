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
import WireTransport

final class FetchMLSConversationGroupInfoActionHandler: BaseFetchMLSGroupInfoActionHandler<
    FetchMLSConversationGroupInfoAction
> {
    override func request(
        for action: FetchMLSConversationGroupInfoAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard
            !action.domain.isEmpty,
            !action.conversationId.uuidString.isEmpty
        else {
            action.fail(with: .emptyParameters)
            return nil
        }

        return request(
            for: action,
            path: "/conversations/\(action.domain)/\(action.conversationId.transportString())/groupinfo",
            apiVersion: apiVersion,
            minRequiredAPIVersion: .v5
        )
    }
}
