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
import WireUtilities

public protocol SearchUsersUseCaseProtocol {

    func invoke(
        query: String,
        options: SearchOptions,
        filterConversation: ZMConversation?
    ) async throws -> SearchResult
}

public class SearchUsersUseCase: SearchUsersUseCaseProtocol {

    private let context: NSManagedObjectContext
    private let searchDirectory: SearchDirectory?
    private let isFederationUsageAllowed: Bool
    private var pendingSearchTask: SearchTask?

    deinit {
        searchDirectory?.tearDown()
    }

    public init(
        context: NSManagedObjectContext,
        searchDirectory: SearchDirectory?,
        isFederationUsageAllowed: Bool
    ) {
        self.context = context
        self.searchDirectory = searchDirectory
        self.isFederationUsageAllowed = isFederationUsageAllowed
    }

    public func invoke(
        query: String,
        options: SearchOptions,
        filterConversation: ZMConversation?
    ) async throws -> SearchResult {
        searchDirectory?.updateIncompleteMetadataIfNeeded()
        pendingSearchTask?.cancel()

        let (query, searchDomain) = SearchRequest.parseQuery(query.trim())

        let (selfDomain, team) = await context.perform {
            let selfUser = ZMUser.selfUser(in: self.context)
            return (selfUser.domain, selfUser.membership?.team)
        }

        let request = SearchRequest(
            query: query,
            searchDomain: isOtherDomainSearchAllowed(conversation: filterConversation) ? searchDomain : selfDomain,
            searchOptions: options,
            team: team
        )

        return try await withCheckedThrowingContinuation { continuation in
            let task = searchDirectory?.perform(request)
            task?.addResultHandler { result, isCompleted in
                if isCompleted {
                    continuation.resume(returning: result)
                }
            }
            task?.start()
            pendingSearchTask = task
        }
    }

    private func isOtherDomainSearchAllowed(conversation: ZMConversation?) -> Bool {
        guard let conversation else {
            return isFederationUsageAllowed
        }
        return conversation.isAllowedToAddFederatedUsers
    }

}

public extension UserSession {

    var isFederationUsageAllowed: Bool {
        guard BackendInfo.isMLSEnabled else {
            // If there is no MLS removal key configured,federation search is allowed.
            return true
        }
        return mlsFeature.config.defaultProtocol != .proteus
    }

}

private extension ZMConversation {

    var isAllowedToAddFederatedUsers: Bool {
        guard BackendInfo.isMLSEnabled else {
            // If there is no MLS removal key configured,federation search is allowed.
            return true
        }
        return messageProtocol != .proteus
    }

}
