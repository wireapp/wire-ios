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

    let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    // MARK: - Fetch user property
    
    func getProperty(forKey key: UserPropertyKey) async throws -> UserProperty {
        let request = HTTPRequest(
            path: "\(pathPrefix)/properties/\(key.rawValue)",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)
        
        switch key {
        case .wireReceiptMode:
            return try getProperty(response: response, payload: ReceiptModeResponseV0.self)
        case .wireTypingIndicatorMode:
            return try getProperty(response: response, payload: TypeIndicatorModeResponseV0.self)
        case .labels:
            return try getProperty(response: response, payload: LabelsResponseV0.self)
        }
    }
    
    func getProperty<Payload: UserPropertiesResponseAPIV0>(
        response: HTTPResponse,
        payload: Payload.Type
    ) throws -> UserProperty where Payload.APIModel == UserProperty {
        try ResponseParser()
            .success(code: 200, type: payload)
            .failure(code: 404, error: UserPropertiesAPIError.propertyNotFound)
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
        self.value = .areReadRecieptsEnabled(value == 1)
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
        let payload = try container.decode(LabelsPayload.self)
        
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
}
