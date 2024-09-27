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

// MARK: - SearchDirectory

@objcMembers
public class SearchDirectory: NSObject {
    let searchContext: NSManagedObjectContext
    let contextProvider: ContextProvider
    let transportSession: TransportSessionType

    var isTornDown = false

    private let refreshUsersMissingMetadataAction: RecurringAction
    private let refreshConversationsMissingMetadataAction: RecurringAction

    private let searchUsersCache: SearchUsersCache?

    deinit {
        assert(isTornDown, "`tearDown` must be called before SearchDirectory is deinitialized")
    }

    public convenience init(userSession: ZMUserSession) {
        self.init(
            searchContext: userSession.searchManagedObjectContext,
            contextProvider: userSession,
            transportSession: userSession.transportSession,
            searchUsersCache: userSession.searchUsersCache,
            refreshUsersMissingMetadataAction: userSession.refreshUsersMissingMetadataAction,
            refreshConversationsMissingMetadataAction: userSession.refreshConversationsMissingMetadataAction
        )
    }

    init(
        searchContext: NSManagedObjectContext,
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        refreshUsersMissingMetadataAction: RecurringAction,
        refreshConversationsMissingMetadataAction: RecurringAction
    ) {
        self.searchContext = searchContext
        self.contextProvider = contextProvider
        self.transportSession = transportSession
        self.searchUsersCache = searchUsersCache

        self.refreshUsersMissingMetadataAction = refreshUsersMissingMetadataAction
        self.refreshConversationsMissingMetadataAction = refreshConversationsMissingMetadataAction
    }

    /// Perform a search request.
    ///
    /// Returns a SearchTask which should be retained until the results arrive.
    public func perform(_ request: SearchRequest) -> SearchTask {
        let task = SearchTask(
            task: .search(searchRequest: request),
            searchContext: searchContext,
            contextProvider: contextProvider,
            transportSession: transportSession,
            searchUsersCache: searchUsersCache
        )

        task.addResultHandler { [weak self] result, _ in
            self?.observeSearchUsers(result)
        }

        return task
    }

    /// Lookup a user by user Id and returns a search user in the directory results. If the user doesn't exists
    /// an empty directory result is returned.
    ///
    /// Returns a SearchTask which should be retained until the results arrive.
    public func lookup(userId: UUID) -> SearchTask {
        let task = SearchTask(
            task: .lookup(userId: userId),
            searchContext: searchContext,
            contextProvider: contextProvider,
            transportSession: transportSession,
            searchUsersCache: searchUsersCache
        )

        task.addResultHandler { [weak self] result, _ in
            self?.observeSearchUsers(result)
        }

        return task
    }

    func observeSearchUsers(_ result: SearchResult) {
        let searchUserObserverCenter = contextProvider.viewContext.searchUserObserverCenter
        result.directory.forEach(searchUserObserverCenter.addSearchUser)
        result.services.compactMap { $0 as? ZMSearchUser }.forEach(searchUserObserverCenter.addSearchUser)
    }

    public func updateIncompleteMetadataIfNeeded() {
        refreshUsersMissingMetadataAction()
        refreshConversationsMissingMetadataAction()
    }
}

// MARK: TearDownCapable

extension SearchDirectory: TearDownCapable {
    /// Tear down the SearchDirectory.
    ///
    /// NOTE: this must be called before releasing the instance
    public func tearDown() {
        // Evict all cached search users
        searchUsersCache?.removeAllObjects()

        // Reset search user observer center to remove unnecessarily observed search users
        contextProvider.viewContext.searchUserObserverCenter.reset()

        isTornDown = true
    }
}
