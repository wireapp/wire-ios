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

final class ConversationsAPIV15: ConversationsAPIV14 {
    override var apiVersion: APIVersion { .v17 }
    
    // TODO move to API 17
    override func updateConversationDescripton(conversationID: QualifiedID, currentVersion: Int, ciphertext: String) async throws {
        
        let parameters = UpdateConversationDescriptionParametersV15(
            version: currentVersion,
            ciphertext: ciphertext
        )
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/\(conversationID.domain)/\(conversationID.id)/description"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        try ResponseParser()
            .success(code: .ok, type: IgnoredPayload.self)
            .success(code: .noContent)
            .failure(code: .forbidden, label: "invalid-op", error: ConversationsAPIError.invalidOperation)
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(code: .forbidden, label: "action-denied", error: ConversationsAPIError.insufficientAuthorization)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .parse(code: response.statusCode, data: data)

        /// We need a type for parsing the payload, however, we are not interested in anything for now, so no
        /// properties.
        struct IgnoredPayload: Decodable, ToAPIModelConvertible {
            func toAPIModel() {}
        }
    }
    
    override func getConversationDescription(conversationID: QualifiedID) async throws -> ConversationDescription {
        let path = "\(pathPrefix)\(basePath)/\(conversationID.domain)/\(conversationID.id)/description"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
            )
            
            
            return try ResponseParser()
                .success(code: .ok, type: ConversationDescriptionV15.self)
                .parse(code: response.statusCode, data: data)
    }
}

private struct ConversationDescriptionV15: Decodable, Sendable, Equatable, ToAPIModelConvertible {
    let ciphertext: String
    let version: Int
    
    
    func toAPIModel() -> ConversationDescription {
        ConversationDescription(ciphertext: ciphertext, version: version)
    }
}

private struct UpdateConversationDescriptionParametersV15: Encodable {
    let version: Int
    let ciphertext: String

    enum CodingKeys: String, CodingKey {
        case version = "base_version"
        case ciphertext = "ciphertext"
    }
}
