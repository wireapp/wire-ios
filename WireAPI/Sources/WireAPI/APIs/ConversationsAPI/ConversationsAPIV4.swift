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

class ConversationsAPIV4: ConversationsAPIV3 {
    override var apiVersion: APIVersion { .v4 }

    override func getConversationGuestLink(
        conversationID: String
    ) async throws -> String? {
        let path = "\(pathPrefix)\(basePath)/\(conversationID)/code"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ConversationCodeV4.self) // New change in v4
            .failure(
                code: .badRequest,
                label: "cnv",
                error: ConversationsAPIError.invalidConversationID
            ) // Dedicated error code in v4
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .failure(
                code: .notFound,
                label: "no-conversation-code",
                error: ConversationsAPIError.conversationCodeNotFound
            )
            .failure(code: .conflict, label: "guest-links-disabled", error: ConversationsAPIError.guestLinksDisabled)
            .parse(code: response.statusCode, data: data)
    }
}

struct ConversationCodeV4: Decodable, ToAPIModelConvertible {

    let code: String
    let hasPassword: Bool // Introduced in v4
    let key: String
    let uri: String?

    enum CodingKeys: String, CodingKey {
        case code
        case hasPassword = "has_password"
        case key
        case uri
    }

    func toAPIModel() -> String? {
        uri
    }
}
