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

final class SearchAPIV15: SearchAPIV14 {

    override var apiVersion: APIVersion {
        .v15
    }

    // MARK: -

    override func searchContacts(
        query: String,
        domain: String?,
        size: Int?
    ) async throws -> SearchContactsResult {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "q", value: query))

        if let domain {
            queryItems.append(URLQueryItem(name: "domain", value: domain))
        }

        if let size {
            queryItems.append(URLQueryItem(name: "size", value: String(size)))
        }

        var urlComponents = URLComponents()
        urlComponents.path = "/search/contacts"
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
            .success(code: .ok, type: SearchResultContactV15.self)
            .failure(code: .forbidden, error: SearchAPIError.insufficientPermissions)
            .parse(code: response.statusCode, data: data)
    }

}

struct SearchResultContactV15: Decodable, ToAPIModelConvertible {

    let documents: [ContactV15]
    let found: Int
    let returned: Int
    let took: Int
    let hasMore: Bool
    let pagingState: String?
    let searchPolicy: String

    enum CodingKeys: String, CodingKey {
        case documents
        case found
        case returned
        case took
        case hasMore = "has_more"
        case pagingState = "paging_state"
        case searchPolicy = "search_policy"
    }

    func toAPIModel() -> SearchContactsResult {
        SearchContactsResult(
            documents: documents.map { $0.toAPIModel() },
            found: found,
            returned: returned,
            took: took,
            hasMore: hasMore,
            pagingState: pagingState,
            searchPolicy: searchPolicy
        )
    }
}

struct ContactV15: Decodable, ToAPIModelConvertible {

    let qualifiedID: QualifiedIDV0
    let name: String
    let handle: String?
    let accentID: Int?
    let team: UUID?
    let type: String

    enum CodingKeys: String, CodingKey {
        case qualifiedID = "qualified_id"
        case name
        case handle
        case accentID = "accent_id"
        case team
        case type
    }

    func toAPIModel() -> Contact {
        Contact(
            qualifiedID: qualifiedID.toAPIModel(),
            name: name,
            handle: handle,
            accentID: accentID,
            team: team,
            type: type
        )
    }
}
