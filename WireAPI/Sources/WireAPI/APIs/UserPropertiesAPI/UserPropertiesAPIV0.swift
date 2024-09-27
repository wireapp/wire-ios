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

// MARK: - UserPropertiesAPIV0

class UserPropertiesAPIV0: UserPropertiesAPI, VersionedAPI {
    // MARK: Lifecycle

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: Internal

    let httpClient: any HTTPClient

    var apiVersion: APIVersion {
        .v0
    }

    var areTypingIndicatorsEnabled: Bool {
        get async throws {
            let result = try await getProperty(forKey: .wireTypingIndicatorMode)
            guard case let .areTypingIndicatorsEnabled(isEnabled) = result else {
                throw UserPropertiesAPIError.invalidKey
            }

            return isEnabled
        }
    }

    var areReadReceiptsEnabled: Bool {
        get async throws {
            let result = try await getProperty(forKey: .wireReceiptMode)
            guard case let .areReadReceiptsEnabled(isEnabled) = result else {
                throw UserPropertiesAPIError.invalidKey
            }

            return isEnabled
        }
    }

    func getLabels() async throws -> [ConversationLabel] {
        let result = try await getProperty(forKey: .labels)

        guard case let .conversationLabels(labels) = result else {
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

// MARK: - UserPropertiesResponseAPIV0

protocol UserPropertiesResponseAPIV0: Decodable, ToAPIModelConvertible {
    var value: UserProperty { get }
}

extension UserPropertiesResponseAPIV0 {
    func toAPIModel() -> UserProperty {
        value
    }
}

// MARK: - ReceiptModeResponseV0

struct ReceiptModeResponseV0: UserPropertiesResponseAPIV0 {
    // MARK: Lifecycle

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        self.value = .areReadReceiptsEnabled(value == 1)
    }

    // MARK: Internal

    let value: UserProperty
}

// MARK: - TypeIndicatorModeResponseV0

struct TypeIndicatorModeResponseV0: UserPropertiesResponseAPIV0 {
    // MARK: Lifecycle

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        self.value = .areTypingIndicatorsEnabled(value == 1)
    }

    // MARK: Internal

    let value: UserProperty
}

// MARK: - LabelsResponseV0

struct LabelsResponseV0: UserPropertiesResponseAPIV0 {
    // MARK: Lifecycle

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

        self.value = .conversationLabels(conversationLabels)
    }

    // MARK: Internal

    let value: UserProperty
}

// MARK: - LabelsPayloadV0

struct LabelsPayloadV0: Decodable {
    struct Label: Decodable {
        let id: UUID
        let type: Int16
        let name: String?
        let conversations: [UUID]
    }

    let labels: [Label]
}
