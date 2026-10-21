//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

class ConversationsAPIV7: ConversationsAPIV6 {

    override var apiVersion: APIVersion { .v7 }
    override var oneToOneConversationsPath: String {
        "\(pathPrefix)/one2one-conversations"
    }

    override func updateRole(
        _ role: String,
        userID: UserID,
        conversationID: ConversationID
    ) async throws {
        let parameters = ConversationUpdateRoleV0(role: role)
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/\(conversationID.domain)/\(conversationID.id)/members/\(userID.domain)/\(userID.id)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        try ResponseParser()
            .success(code: .ok)
            .failure(code: .forbidden, label: "invalid-op", error: ConversationsAPIError.invalidOperation)
            .failure(code: .forbidden, label: "action-denied", error: ConversationsAPIError.insufficientAuthorization)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .parse(code: response.statusCode, data: data)
    }
}
