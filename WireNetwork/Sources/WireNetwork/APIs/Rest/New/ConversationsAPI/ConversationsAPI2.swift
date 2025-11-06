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

struct ConversationsAPI2: Sendable {

    private let apiService: APIService
    private let apiVersionProvider: @Sendable () async throws -> APIVersion

    init(
        apiService: APIService,
        apiVersionProvider: @escaping @Sendable () async throws -> APIVersion
    ) {
        self.apiVersionProvider = apiVersionProvider
        self.apiService = apiService
    }

    // MARK: - Endpoints

    func getConversationIdentifiers() async throws -> PayloadPager<[QualifiedID]> {
        try await GetConversationIdentifiersEndpoint(
            apiVersion: apiVersionProvider(),
            apiService: apiService
        )()
    }

    func getConversations(
        for identifiers: [QualifiedID]
    ) async throws -> ConversationList {
        try await GetConversationsEndpoint(
            apiVersion: try await apiVersionProvider(),
            apiService: apiService
        )(for: identifiers)
    }

}
