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

class SearchAPIV1: SearchAPIV0 {

    override var apiVersion: APIVersion {
        .v1
    }

    var basePath: String {
        "/search/contacts"
    }

    // MARK: -

    override func searchContacts(
        query: String,
        domain: String,
        type: UserType,
        fetchLimit: Int?
    ) async throws -> ContactSearchResult {

        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "q", value: query))

        let userType = UserTypeV1(type)
        queryItems.append(URLQueryItem(name: "type", value: userType.rawValue))

        if !domain.isEmpty {
            queryItems.append(URLQueryItem(name: "domain", value: domain))
        }

        if let fetchLimit {
            queryItems.append(URLQueryItem(name: "size", value: String(fetchLimit)))
        }

        var urlComponents = URLComponents()
        urlComponents.path = "\(pathPrefix)\(basePath)"
        urlComponents.queryItems = queryItems

        guard let path = urlComponents.string?.replacingOccurrences(of: "+", with: "%2B") else {
            throw SearchAPIError.invalidRequest
        }

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: SearchResultContactV1.self)
            .failure(code: .forbidden, error: SearchAPIError.insufficientPermissions)
            .parse(code: response.statusCode, data: data)

    }

}

private enum UserTypeV1: String, Codable {

    case regular
    case app
    case bot

    init(_ apiModel: UserType) {
        switch apiModel {
        case .regular:
            self = .regular
        case .app:
            self = .app
        case .bot:
            self = .bot
        }
    }

    func toAPIModel() -> UserType {
        switch self {
        case .regular:
            .regular
        case .app:
            .app
        case .bot:
            .bot
        }
    }

}

private struct SearchResultContactV1: Decodable, ToAPIModelConvertible {

    let documents: [ContactV1]

    enum CodingKeys: String, CodingKey {
        case documents
    }

    func toAPIModel() -> ContactSearchResult {
        ContactSearchResult(
            documents: documents.map { $0.toAPIModel() }
        )
    }

}

private struct ContactV1: Decodable, ToAPIModelConvertible {

    let id: UUID
    let qualifiedID: QualifiedIDV0?
    let name: String
    let handle: String?
    let team: UUID?
    let accentID: Int?
    let type: UserTypeV1?

    enum CodingKeys: String, CodingKey {
        case id
        case qualifiedID = "qualified_id"
        case name
        case handle
        case accentID = "accent_id"
        case team
        case type
    }

    func toAPIModel() -> ContactSearchResult.Contact {
        .init(
            id: id,
            qualifiedID: qualifiedID?.toAPIModel(),
            name: name,
            handle: handle,
            team: team,
            accentID: accentID,
            type: type?.toAPIModel() ?? .regular
        )
    }

}
