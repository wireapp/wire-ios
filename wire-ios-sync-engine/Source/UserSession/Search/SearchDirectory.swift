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
import WireNetwork
import WireDataModel
import WireTransport

public final class SearchDirectory {

    private let contextProvider: ContextProvider
    private let transportSession: TransportSessionType
    private let apiVersion: WireTransport.APIVersion?
    private let searchAPI: any SearchAPI

    private var isTornDown = false

    private let refreshUsersMissingMetadataAction: RecurringAction
    private let refreshConversationsMissingMetadataAction: RecurringAction

    private let searchUsersCache: SearchUsersCache?

    deinit {
        assert(isTornDown, "`tearDown` must be called before SearchDirectory is deinitialized")
    }

    public convenience init(
        userSession: ZMUserSession,
        searchAPI: some SearchAPI
    ) {
        self.init(
            contextProvider: userSession,
            transportSession: userSession.transportSession,
            searchUsersCache: userSession.searchUsersCache,
            refreshUsersMissingMetadataAction: userSession.refreshUsersMissingMetadataAction,
            refreshConversationsMissingMetadataAction: userSession.refreshConversationsMissingMetadataAction,
            apiVersion: userSession.resolvedBackendMetadata.apiVersion,
            searchAPI: searchAPI
        )
    }

    init(
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        refreshUsersMissingMetadataAction: RecurringAction,
        refreshConversationsMissingMetadataAction: RecurringAction,
        apiVersion: WireTransport.APIVersion?,
        searchAPI: some SearchAPI
    ) {
        self.contextProvider = contextProvider
        self.transportSession = transportSession
        self.searchUsersCache = searchUsersCache
        self.apiVersion = apiVersion
        self.searchAPI = searchAPI

        self.refreshUsersMissingMetadataAction = refreshUsersMissingMetadataAction
        self.refreshConversationsMissingMetadataAction = refreshConversationsMissingMetadataAction
    }

    public func createSearchTask(with request: SearchRequest) -> SearchTask {
        SearchTask(
            type: .search(searchRequest: request),
            contextProvider: contextProvider,
            transportSession: transportSession,
            searchUsersCache: searchUsersCache,
            apiVersion: apiVersion,
            searchAPI: searchAPI
        )
    }

    /// Lookup a user by user Id and domain (qualifiedID), returns a search user in the directory results. If the user
    /// doesn't exists
    /// an empty directory result is returned.
    public func createLookupTask(with qualifiedID: QualifiedID) -> SearchTask {
        SearchTask(
            type: .lookup(qualifiedID: qualifiedID),
            contextProvider: contextProvider,
            transportSession: transportSession,
            searchUsersCache: searchUsersCache,
            apiVersion: apiVersion,
            searchAPI: searchAPI
        )
    }

    public func updateIncompleteMetadataIfNeeded() async {
        await refreshUsersMissingMetadataAction()
        await refreshConversationsMissingMetadataAction()
    }
}

public extension SearchDirectory {

    /// Tear down the SearchDirectory.
    ///
    /// NOTE: this must be called before releasing the instance

    func tearDown() {
        let tearDown = { [self] in
            // Evict all cached search users
            searchUsersCache?.removeAllObjects()

            // Reset search user observer center to remove unnecessarily observed search users
            contextProvider.viewContext.searchUserObserverCenter.reset()

            isTornDown = true
        }
        if Thread.isMainThread {
            tearDown()
        } else {
            DispatchQueue.main.async(execute: tearDown)
        }
    }

}
