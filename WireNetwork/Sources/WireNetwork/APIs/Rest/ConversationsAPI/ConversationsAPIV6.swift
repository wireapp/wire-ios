//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

class ConversationsAPIV6: ConversationsAPIV5 {
    override var apiVersion: APIVersion { .v6 }

    // https://nginz-https.anta.wire.link/v12/api/swagger-ui/#/default/get-one-to-one-mls-conversation
    override func getMLSOneToOneConversation(
        userID: String,
        in domain: String
    ) async throws -> (Conversation, MLSPublicKeys?) {
        guard !userID.isEmpty, !domain.isEmpty else {
            throw ConversationsAPIError.userAndDomainShouldNotBeEmpty
        }

        let path = "\(oneToOneConversationsPath)/\(domain)/\(userID)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ConversationWithPublicKeys<ConversationV5>.self)
            .failure(code: .badRequest, label: "mls-not-enabled", error: ConversationsAPIError.mlsNotEnabled)
            .failure(code: .forbidden, label: "not-connected", error: ConversationsAPIError.usersNotConnected)
            .parse(code: response.statusCode, data: data)
    }
}

protocol DecodableConversation: Decodable, ToAPIModelConvertible where APIModel == Conversation {}

struct ConversationWithPublicKeys<T: DecodableConversation>: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case conversation
        case publicKeys = "public_keys"
    }

    struct RemovalKeys: Decodable {
        enum CodingKeys: String, CodingKey {
            case removalKeys = "removal"
        }

        var removalKeys: MLSPublicKeysV0
    }

    var conversation: T
    var publicKeys: MLSPublicKeysV0

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.conversation = try container.decode(T.self, forKey: .conversation)
        let removalKeys = try container.decode(RemovalKeys.self, forKey: .publicKeys)
        self.publicKeys = removalKeys.removalKeys
    }

    func toAPIModel() -> (Conversation, MLSPublicKeys) {
        (
            conversation.toAPIModel(),
            publicKeys.toAPIModel()
        )
    }
}
