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
    ) async throws -> (SearchResult, isCompleted: Bool)
}

public class SearchUsersUseCase: SearchUsersUseCaseProtocol {

    private let userSession: UserSession
    private var pendingSearchTask: SearchTask?

    private lazy var searchDirectory: SearchDirectory? = {
        guard let session = userSession as? ZMUserSession else {
            return nil
        }

        return SearchDirectory(userSession: session)
    }()

    deinit {
        searchDirectory?.tearDown()
    }

    public init(userSession: UserSession) {
        self.userSession = userSession
    }

    public func invoke(
        query: String,
        options: SearchOptions,
        filterConversation: ZMConversation?
    ) async throws -> (SearchResult, isCompleted: Bool) {

        pendingSearchTask?.cancel()
        let selfUser = userSession.selfUser
        var options = options
        options.updateForSelfUserTeamRole(selfUser: selfUser)
        let (query, searchDomain) = SearchRequest.parseQuery(query.trim())

        let request = SearchRequest(
            query: query,
            searchDomain: isOtherDomainSearchAllowed(conversation: filterConversation) ? searchDomain : selfUser.domain,
            searchOptions: options,
            team: selfUser.membership?.team
        )
        searchDirectory?.updateIncompleteMetadataIfNeeded()

        return try await withCheckedThrowingContinuation { continuation in
            let task = searchDirectory?.perform(request)
            task?.addResultHandler { result, isCompleted in
                continuation.resume(returning: (result, isCompleted))
            }
            task?.start()
            pendingSearchTask = task
        }
    }

    private func isOtherDomainSearchAllowed(conversation: ZMConversation?) -> Bool {
        guard let conversation else {
            return userSession.isFederationUsageAllowed
        }
        return conversation.isAllowedToAddFederatedUsers
    }

}

public extension UserSession {

    var isFederationUsageAllowed: Bool {
        guard BackendInfo.isMLSEnabled else {
            // Usage of federation is allowed if MLS is not enabled
            return true
        }
        return mlsFeature.config.defaultProtocol != .proteus
    }

}

private extension ZMConversation {

    var isAllowedToAddFederatedUsers: Bool {
        guard BackendInfo.isMLSEnabled else {
            // Usage of federation is allowed if MLS is not enabled
            return true
        }
        return messageProtocol != .proteus
    }

}
