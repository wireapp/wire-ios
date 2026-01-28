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
import WireUtilities

public final class SearchTask {

    public enum `Type` {
        case search(searchRequest: SearchRequest)
        case lookup(qualifiedID: QualifiedID)
    }

    public typealias ResultHandler = (_ incrementalResult: SearchResult, _ isCompleted: Bool) -> Void

    private let apiVersion: WireTransport.APIVersion?
    private let transportSession: TransportSessionType
    private let contextProvider: ContextProvider
    private let searchUsersCache: SearchUsersCache?

    private let type: `Type`
    private var userLookupTaskIdentifier: ZMTaskIdentifier?
    private var directoryTaskIdentifier: ZMTaskIdentifier?
    private var teamMembershipTaskIdentifier: ZMTaskIdentifier?
    private var handleTaskIdentifier: ZMTaskIdentifier?
    private var servicesTaskIdentifier: ZMTaskIdentifier?
    private var resultHandlers: [ResultHandler] = []
    private var result = SearchResult(
        context: .init(concurrencyType: .privateQueueConcurrencyType),
        contacts: [],
        teamMembers: [],
        directory: [],
        conversations: [],
        services: [],
        searchUsersCache: nil
    )

    private let tasksRemainingLock = NSRecursiveLock()
    private var _tasksRemaining = 0
    private var tasksRemaining: Int {
        get {
            tasksRemainingLock.withLock {
                _tasksRemaining
            }
        }
        set {
            let oldValue = tasksRemainingLock.withLock {
                let oldValue = _tasksRemaining
                _tasksRemaining = newValue
                return oldValue
            }
            // only trigger handles if decrement to 0
            if oldValue > newValue {
                let isCompleted = newValue == 0
                resultHandlers.forEach { $0(result, isCompleted) }

                if isCompleted {
                    resultHandlers.removeAll()
                }
            }
        }
    }

    public init(
        type: `Type`,
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        apiVersion: WireTransport.APIVersion?
    ) {
        self.type = type
        self.transportSession = transportSession
        self.contextProvider = contextProvider
        self.searchUsersCache = searchUsersCache
        self.apiVersion = apiVersion
    }

    public func addResultHandler(_ resultHandler: @escaping ResultHandler) {
        resultHandlers.append(resultHandler)
    }

    /// Cancel a previously started task
    public func cancel() {
        resultHandlers.removeAll()

        teamMembershipTaskIdentifier.map(transportSession.cancelTask)
        userLookupTaskIdentifier.map(transportSession.cancelTask)
        directoryTaskIdentifier.map(transportSession.cancelTask)
        servicesTaskIdentifier.map(transportSession.cancelTask)
        handleTaskIdentifier.map(transportSession.cancelTask)

        tasksRemaining = 0
    }

    /// Start the search task. Results will be sent to the result handlers
    /// added via the `onResult()` method.
    public func start() {
        // search services
        performRemoteSearchForServices()

        // search People or groups
        performLocalLookup()
        performLocalSearch()

        // v1
        performRemoteSearchForTeamUser()

        // v2+
        performRemoteSearch()
        performUserLookup()
    }
}

extension SearchTask {

    /// look up a user ID from contacts and teamMembers locally.
    private func performLocalLookup() {
        guard case let .lookup(qualifiedID) = type else { return }

        tasksRemaining += 1

        contextProvider.searchContext.performGroupedBlock { [self] in
            let selfUser = ZMUser.selfUser(in: contextProvider.searchContext)

            var options = SearchOptions()

            options.updateForSelfUserTeamRole(selfUser: selfUser)

            /// search for the local user with matching user ID and active
            let activeMembers = teamMembers(matchingQuery: "", team: selfUser.team, searchOptions: options)
            let teamMembers = activeMembers.filter { $0.remoteIdentifier == qualifiedID.uuid }
            let connectedUsers = connectedUsers(matchingQuery: "", hostedOnDomain: nil)
                .filter { $0.remoteIdentifier == qualifiedID.uuid }

            contextProvider.viewContext.performGroupedBlock { [self] in

                let copiedTeamMembers = teamMembers.compactMap(\.user)
                    .compactMap { contextProvider.viewContext.object(with: $0.objectID) as? Member }
                let copiedConnectedUsers = connectedUsers
                    .compactMap { contextProvider.viewContext.object(with: $0.objectID) as? ZMUser }

                let result = SearchResult(
                    context: contextProvider.viewContext,
                    contacts: copiedConnectedUsers.map {
                        ZMSearchUser(
                            contextProvider: contextProvider,
                            user: $0,
                            searchUsersCache: searchUsersCache
                        )
                    },
                    teamMembers: copiedTeamMembers.compactMap(\.user).map {
                        ZMSearchUser(
                            contextProvider: contextProvider,
                            user: $0,
                            searchUsersCache: searchUsersCache
                        )
                    },
                    directory: [],
                    conversations: [],
                    services: [],
                    searchUsersCache: searchUsersCache
                )

                self.result = self.result.union(withLocalResult: result.copy(on: contextProvider.viewContext))

                tasksRemaining -= 1
            }
        }
    }

    /*private*/ func performLocalSearch() { // TODO: make private
        guard case let .search(request) = type else { return }

        tasksRemaining += 1

        contextProvider.searchContext.performGroupedBlock { [self] in

            var team: Team?
            if let teamObjectID = request.team?.objectID {
                team = (try? contextProvider.searchContext.existingObject(with: teamObjectID)) as? Team
            }

            let selfUser = ZMUser.selfUser(in: contextProvider.searchContext)
            let connectedUsers = request.searchOptions
                .contains(.contacts) ? connectedUsers(
                    matchingQuery: request.normalizedQuery,
                    hostedOnDomain: request.searchDomain
                ) : []
            let teamMembers = request.searchOptions.contains(.teamMembers) ? teamMembers(
                matchingQuery: request.normalizedQuery,
                team: team,
                searchOptions: request.searchOptions
            ) : []

            let conversations = request.searchOptions.contains(.conversations) ? conversations(
                matchingQuery: request.query,
                selfUser: selfUser
            ) : []

            contextProvider.viewContext.performGroupedBlock { [self] in

                let copiedConnectedUsers = connectedUsers
                    .compactMap { contextProvider.viewContext.object(with: $0.objectID) as? ZMUser }
                let searchConnectedUsers = copiedConnectedUsers
                    .map {
                        ZMSearchUser(
                            contextProvider: contextProvider,
                            user: $0,
                            searchUsersCache: searchUsersCache
                        )
                    }
                    .filter { $0.name?.isEmpty == false }

                let copiedteamMembers = teamMembers.compactMap {
                    contextProvider.viewContext.object(with: $0.objectID) as? Member
                }
                let searchTeamMembers = copiedteamMembers
                    .compactMap(\.user)
                    .map {
                        ZMSearchUser(
                            contextProvider: contextProvider,
                            user: $0,
                            searchUsersCache: searchUsersCache
                        )
                    }

                let result = SearchResult(
                    context: contextProvider.viewContext,
                    contacts: searchConnectedUsers,
                    teamMembers: searchTeamMembers,
                    directory: [],
                    conversations: conversations,
                    services: [],
                    searchUsersCache: searchUsersCache
                )

                self.result = self.result.union(withLocalResult: result.copy(on: contextProvider.viewContext))

                tasksRemaining -= 1
            }
        }
    }

    private func filterNonActiveTeamMembers(members: [Member]) -> [Member] {
        let activeConversations = ZMUser.selfUser(in: contextProvider.searchContext).activeConversations
        let activeContacts = Set(activeConversations.flatMap(\.localParticipants))
        let selfUser = ZMUser.selfUser(in: contextProvider.searchContext)

        return members.filter {
            guard let user = $0.user else { return false }
            return selfUser.membership?.createdBy == user || activeContacts.contains(user)
        }
    }

    private func teamMembers(matchingQuery query: String, team: Team?, searchOptions: SearchOptions) -> [Member] {
        var result = team?.members(matchingQuery: query) ?? []

        if searchOptions.contains(.excludeNonActiveTeamMembers) {
            result = filterNonActiveTeamMembers(members: result)
        }

        if searchOptions.contains(.excludeNonActivePartners) {
            let query = query.strippingLeadingAtSign()
            let selfUser = ZMUser.selfUser(in: contextProvider.searchContext)
            let activeConversations = ZMUser.selfUser(in: contextProvider.searchContext).activeConversations
            let activeContacts = Set(activeConversations.flatMap(\.localParticipants))

            result = result.filter { membership in
                if let user = membership.user {
                    user.teamRole != .partner || user.handle == query || membership
                        .createdBy == selfUser || activeContacts.contains(user)
                } else {
                    false
                }
            }
        }

        return result
    }

    private func connectedUsers(matchingQuery query: String, hostedOnDomain: String?) -> [ZMUser] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = if let hostedOnDomain {
            ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(
                withSearch: query,
                hostedOnDomain: hostedOnDomain
            ))
        } else {
            ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(withSearch: query))
        }

        return contextProvider.searchContext.fetchOrAssert(request: fetchRequest) as? [ZMUser] ?? []
    }

    private func conversations(matchingQuery query: SearchRequest.Query, selfUser: ZMUser) -> [ZMConversation] {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: use the interface with team param?
        let fetchRequest = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(
            forSearchQuery: query.string,
            selfUser: selfUser
        ))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: ZMNormalizedUserDefinedNameKey, ascending: true)]

        var conversations = contextProvider.searchContext.fetchOrAssert(request: fetchRequest) as? [ZMConversation] ?? []

        if query.isHandleQuery {
            // if we are searching for a username only include conversations with matching displayName
            conversations = conversations.filter { ($0.displayName ?? "").contains(query.string) }
        }

        let matchingPredicate = ZMConversation.userDefinedNamePredicate(forSearch: query.string)
        var matching: [ZMConversation] = []
        var nonMatching: [ZMConversation] = []

        // re-sort conversations without a matching userDefinedName to the end of the result list
        conversations.forEach { conversation in
            if matchingPredicate.evaluate(with: conversation) {
                matching.append(conversation)
            } else {
                nonMatching.append(conversation)
            }
        }

        return matching + nonMatching
    }

}

extension SearchTask {

    /*private*/ func performUserLookup() { // TODO: make private
        guard
            case let .lookup(qualifiedID) = type,
            let apiVersion
        else { return }

        tasksRemaining += 1

        contextProvider.searchContext.performGroupedBlock { [self] in
            let request = Self.searchRequestForUser(qualifiedID: qualifiedID, apiVersion: apiVersion)
            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in
                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let contextProvider = self?.contextProvider,
                    let payload = response.payload?.asDictionary(),
                    let result = SearchResult(
                        userLookupPayload: payload,
                        contextProvider: contextProvider,
                        searchUsersCache: self?.searchUsersCache
                    )
                else { return }

                if let updatedResult = self?.result.union(withDirectoryResult: result) {
                    self?.result = updatedResult
                }
            })

            request.add(ZMTaskCreatedHandler(on: contextProvider.searchContext) { [weak self] taskIdentifier in
                self?.userLookupTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }

    }

    // GET /users/:id has been removed in v1.
    // We should use the qualified endpoint GET /users/:domain/:id instead.
    // https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/603095166/API+changes+v1+v2
    private static func searchRequestForUser(qualifiedID: QualifiedID, apiVersion: APIVersion) -> ZMTransportRequest {
        (apiVersion <= .v1)
            ? .init(getFromPath: "/users/\(qualifiedID.uuid.transportString())", apiVersion: apiVersion.rawValue)
            : .init(
                getFromPath: "/users/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())",
                apiVersion: apiVersion.rawValue
            )
    }

}

extension SearchTask {

    /*private*/ func performRemoteSearch() { // TODO: make private
        guard
            let apiVersion,
            apiVersion >= .v1,
            case let .search(searchRequest) = type,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            !searchRequest.searchOptions.isDisjoint(with: [.directory, .teamMembers, .federated])
        else {
            return
        }

        tasksRemaining += 1

        contextProvider.searchContext.performGroupedBlock { [self] in
            let request = Self.searchRequestInDirectory(withRequest: searchRequest, apiVersion: apiVersion)

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                guard
                    let contextProvider = self?.contextProvider,
                    let payload = response.payload?.asDictionary(),
                    let result = SearchResult(
                        payload: payload,
                        query: searchRequest.query,
                        searchOptions: searchRequest.searchOptions,
                        contextProvider: contextProvider,
                        searchUsersCache: self?.searchUsersCache
                    )
                else {
                    self?.completeRemoteSearch()
                    return
                }

                if searchRequest.searchOptions.contains(.teamMembers) {
                    self?.performTeamMembershipLookup(on: result, searchRequest: searchRequest)
                } else {
                    self?.completeRemoteSearch(searchResult: result)
                }
            })

            request.add(ZMTaskCreatedHandler(on: contextProvider.searchContext) { [weak self] taskIdentifier in
                self?.directoryTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    private func performTeamMembershipLookup(on searchResult: SearchResult, searchRequest: SearchRequest) {
        let teamMembersIDs = searchResult.teamMembers.compactMap(\.remoteIdentifier)

        guard
            let apiVersion,
            let teamID = ZMUser.selfUser(in: contextProvider.viewContext).team?.remoteIdentifier,
            !teamMembersIDs.isEmpty
        else {
            completeRemoteSearch(searchResult: searchResult)
            return
        }

        let request = Self.fetchTeamMembershipRequest(
            teamID: teamID,
            teamMemberIDs: teamMembersIDs,
            apiVersion: apiVersion
        )

        request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in
            guard
                let contextProvider = self?.contextProvider,
                let rawData = response.rawData,
                let payload = MembershipListPayload(rawData)
            else {
                self?.completeRemoteSearch()
                return
            }

            var updatedResult = searchResult
            updatedResult.extendWithMembershipPayload(payload: payload)
            updatedResult.filterBy(
                searchOptions: searchRequest.searchOptions,
                query: searchRequest.query.string,
                contextProvider: contextProvider
            )

            self?.completeRemoteSearch(searchResult: updatedResult)

        })

        request.add(ZMTaskCreatedHandler(on: contextProvider.searchContext) { [weak self] taskIdentifier in
            self?.teamMembershipTaskIdentifier = taskIdentifier
        })

        transportSession.enqueueOneTime(request)
    }

    private func completeRemoteSearch(searchResult: SearchResult? = nil) {
        defer {
            tasksRemaining -= 1
        }

        if let searchResult {
            result = result.union(withDirectoryResult: searchResult)
        }
    }

    private static func searchRequestInDirectory(
        withRequest searchRequest: SearchRequest,
        fetchLimit: Int = 10,
        apiVersion: APIVersion
    ) -> ZMTransportRequest {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "q", value: searchRequest.query.string))

        if let searchDomain = searchRequest.searchDomain {
            queryItems.append(URLQueryItem(name: "domain", value: searchDomain))
        }

        queryItems.append(URLQueryItem(name: "size", value: String(fetchLimit)))

        var url = URLComponents()
        url.path = "/search/contacts"
        url.queryItems = queryItems

        let path = url.string ?? ""
        return ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
    }

    private static func fetchTeamMembershipRequest(
        teamID: UUID,
        teamMemberIDs: [UUID],
        apiVersion: APIVersion
    ) -> ZMTransportRequest {

        let path = "/teams/\(teamID.transportString())/get-members-by-ids-using-post"
        let payload = [
            "user_ids": teamMemberIDs.map { $0.transportString() }
        ]

        let request = ZMTransportRequest(
            path: path,
            method: .post,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
        request.contentHintForRequestLoop = "\(payload.hashValue)"
        return request
    }

}

extension SearchTask {

    /*private*/ func performRemoteSearchForTeamUser() { // TODO: make private
        guard
            let apiVersion,
            apiVersion <= .v1,
            case let .search(searchRequest) = type,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.directory)
        else { return }

        tasksRemaining += 1

        contextProvider.searchContext.performGroupedBlock { [self] in
            let request = Self.searchRequestInDirectory(
                withHandle: searchRequest.query.string,
                apiVersion: apiVersion
            )

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let contextProvider = self?.contextProvider,
                    let payload = response.payload?.asArray(),
                    let userPayload = (payload.first as? ZMTransportData)?.asDictionary()
                else {
                    return
                }

                guard
                    let handle = userPayload["handle"] as? String,
                    let name = userPayload["name"] as? String,
                    let id = userPayload["id"] as? String
                else {
                    return
                }

                let document = ["handle": handle, "name": name, "id": id]
                let documentPayload = ["documents": [document]]
                guard let result = SearchResult(
                    payload: documentPayload,
                    query: searchRequest.query,
                    searchOptions: searchRequest.searchOptions,
                    contextProvider: contextProvider,
                    searchUsersCache: self?.searchUsersCache
                ) else {
                    return
                }

                if let user = result.directory.first, !user.isSelfUser {
                    if let prevResult = self?.result {
                        // prepend result to prevResult only if it doesn't contain it
                        if !prevResult.directory.contains(user) {
                            self?.result = SearchResult(
                                context: prevResult.context,
                                contacts: prevResult.contacts,
                                teamMembers: prevResult.teamMembers,
                                directory: result.directory + prevResult.directory,
                                conversations: prevResult.conversations,
                                services: prevResult.services,
                                searchUsersCache: self?.searchUsersCache
                            )
                        }
                    } else {
                        self?.result = result
                    }
                }
            })

            request.add(ZMTaskCreatedHandler(on: contextProvider.searchContext) { [weak self] taskIdentifier in
                self?.handleTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    private static func searchRequestInDirectory(withHandle handle: String, apiVersion: APIVersion) -> ZMTransportRequest {
        var handle = handle.lowercased()

        if handle.hasPrefix("@") {
            handle = String(handle[handle.index(after: handle.startIndex)...])
        }

        var url = URLComponents()
        url.path = "/users"
        url.queryItems = [URLQueryItem(name: "handles", value: handle)]
        let urlStr = url.string ?? "" // TODO: manually verify it's correct
        return ZMTransportRequest(getFromPath: urlStr, apiVersion: apiVersion.rawValue)
    }
}

extension SearchTask {

    /*private*/ func performRemoteSearchForServices() { // TODO: make private
        let teamIdentifier = contextProvider.searchContext.performAndWait {
            ZMUser.selfUser(in: contextProvider.searchContext).team?.remoteIdentifier
        }
        guard
            let apiVersion,
            let teamIdentifier,
            case let .search(searchRequest) = type,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.services)
        else { return }

        tasksRemaining += 1

        contextProvider.searchContext.performGroupedBlock { [self] in

            let request = Self.servicesSearchRequest(
                teamIdentifier: teamIdentifier,
                query: searchRequest.query.string,
                apiVersion: apiVersion
            )

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let contextProvider = self?.contextProvider,
                    let payload = response.payload?.asDictionary(),
                    let result = SearchResult(
                        servicesPayload: payload,
                        query: searchRequest.query.string,
                        contextProvider: contextProvider,
                        searchUsersCache: self?.searchUsersCache
                    )
                else {
                    return
                }

                if let updatedResult = self?.result.union(withServiceResult: result) {
                    self?.result = updatedResult
                }
            })

            request.add(ZMTaskCreatedHandler(on: contextProvider.searchContext) { [weak self] taskIdentifier in
                self?.servicesTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    /*private*/ static func servicesSearchRequest( // TODO: make private
        teamIdentifier: UUID,
        query: String,
        apiVersion: APIVersion
    ) -> ZMTransportRequest {
        var url = URLComponents()
        url.path = "/teams/\(teamIdentifier.transportString())/services/whitelisted"

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            url.queryItems = [URLQueryItem(name: "prefix", value: trimmedQuery)]
        }
        let urlStr = url.string ?? ""
        return ZMTransportRequest(getFromPath: urlStr, apiVersion: apiVersion.rawValue)
    }
}
