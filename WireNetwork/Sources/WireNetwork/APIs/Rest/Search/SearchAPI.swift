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

// sourcery: AutoMockable
/// An API access object for endpoints concerning people and apps search.
public protocol SearchAPI {

    func searchContacts(
        query: String,
        domain: String,
        type: UserType
    ) async throws -> ContactSearchResult

    /// - Parameters:
    ///   - fetchLimit: min: 1, max: 500, default 15 on API side
    func searchContacts(
        query: String,
        domain: String,
        type: UserType,
        fetchLimit: Int?
    ) async throws -> ContactSearchResult

}

public extension SearchAPI {

    func searchContacts(
        query: String,
        domain: String,
        type: UserType
    ) async throws -> ContactSearchResult {
        try await searchContacts(
            query: query,
            domain: domain,
            type: type,
            fetchLimit: nil
        )
    }

}
