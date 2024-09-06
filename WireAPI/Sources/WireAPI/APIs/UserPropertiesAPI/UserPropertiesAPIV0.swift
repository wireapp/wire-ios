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

class UserPropertiesAPIV0: UserPropertiesAPI, VersionedAPI {

    let httpClient: any HTTPClient

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    var areTypingIndicatorsEnabled: Bool {
        get async throws {
            let result = try await getProperty(forKey: .wireTypingIndicatorMode)
            guard case .areTypingIndicatorsEnabled(let isEnabled) = result else {
                throw UserPropertiesAPIError.invalidKey
            }

            return isEnabled
        }
    }

    var areReadReceiptsEnabled: Bool {
        get async throws {
            let result = try await getProperty(forKey: .wireReceiptMode)
            guard case .areReadReceiptsEnabled(let isEnabled) = result else {
                throw UserPropertiesAPIError.invalidKey
            }

            return isEnabled
        }
    }

    func getLabels() async throws -> [ConversationLabel] {
        let result = try await getProperty(forKey: .labels)

        guard case .conversationLabels(let labels) = result else {
            throw UserPropertiesAPIError.invalidKey
        }

        return labels
    }

    // MARK: - Fetch user property

    func getProperty(forKey key: UserProperty.Key) async throws -> UserProperty {
        let request = HTTPRequest(
            path: "\(pathPrefix)/properties/\(key.rawValue)",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch key {
        case .wireReceiptMode:
            return try parseResponse(response, forPayloadType: ReceiptModeResponseV0.self)
        case .wireTypingIndicatorMode:
            return try parseResponse(response, forPayloadType: TypeIndicatorModeResponseV0.self)
        case .labels:
            return try parseResponse(response, forPayloadType: LabelsResponseV0.self)
        }
    }

    func parseResponse<Payload: UserPropertiesResponseAPIV0>(
        _ response: HTTPResponse,
        forPayloadType type: Payload.Type
    ) throws -> UserProperty where Payload.APIModel == UserProperty {
        try ResponseParser()
            .success(code: .ok, type: type)
            .failure(code: .notFound, error: UserPropertiesAPIError.propertyNotFound)
            .parse(response)
    }

}

protocol UserPropertiesResponseAPIV0: Decodable, ToAPIModelConvertible {
    var value: UserProperty { get }
}

extension UserPropertiesResponseAPIV0 {
    func toAPIModel() -> UserProperty {
        value
    }
}

struct ReceiptModeResponseV0: UserPropertiesResponseAPIV0 {
    let value: UserProperty

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        self.value = .areReadReceiptsEnabled(value == 1)
    }
}

struct TypeIndicatorModeResponseV0: UserPropertiesResponseAPIV0 {
    let value: UserProperty

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        self.value = .areTypingIndicatorsEnabled(value == 1)
    }
}

struct LabelsResponseV0: UserPropertiesResponseAPIV0 {
    let value: UserProperty

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let payload = try container.decode(LabelsPayloadV0.self)

        let conversationLabels = payload.labels.map {
            ConversationLabel(
                id: $0.id,
                name: $0.name,
                type: $0.type,
                conversationIDs: $0.conversations
            )
        }

        value = .conversationLabels(conversationLabels)
    }
}

struct LabelsPayloadV0: Decodable {

    let labels: [Label]

    struct Label: Decodable {

        let id: UUID
        let type: Int16
        let name: String?
        let conversations: [UUID]

    }

}
