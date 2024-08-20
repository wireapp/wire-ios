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

class ConversationsAPIV2: ConversationsAPIV1 {
    override var apiVersion: APIVersion { .v2 }

    override func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers)
        let body = try JSONEncoder.defaultEncoder.encode(parameters)

        // New change for v2
        let resourcePath = "\(pathPrefix)/conversations/list"

        let request = HTTPRequest(
            path: resourcePath,
            method: .post,
            body: body
        )
        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: QualifiedConversationListV0.self)
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .parse(response)
    }
}
