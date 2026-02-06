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

import CoreData
import Foundation
import WireUtilities
import WireNetwork
import WireFoundation
import WireLogging

public final class SearchTask {

    public enum `Type` {
        case search(searchRequest: SearchRequest)
        case lookup(qualifiedID: WireDataModel.QualifiedID)
    }

    private enum Status {
        case pending
        case started(taskGroup: ThrowingTaskGroup<SearchTask.SearchResultAggregator, any Error>)
    }

    private var status = Status.pending

    /// A closure which modifies the passed search result in order to unite the existing and the newly found results.
    ///
    /// The closure is used because there are four different ways of aggregating search results:
    /// - union(withLocalResult:)
    /// - union(withBotResult:)
    /// - union(withDirectoryResult:)
    /// - union(prependingDirectory:)
    typealias SearchResultAggregator = (inout SearchResult) -> Void

    private let apiVersion: WireTransport.APIVersion?
    private let transportSession: TransportSessionType
    private let contextProvider: ContextProvider
    private let searchUsersCache: SearchUsersCache?
    private let searchAPI: any SearchAPI

    private let type: `Type`

    init(
        type: Type,
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        apiVersion: WireTransport.APIVersion?,
        searchAPI: some SearchAPI
    ) {
        self.type = type
        self.transportSession = transportSession
        self.contextProvider = contextProvider
        self.searchUsersCache = searchUsersCache
        self.apiVersion = apiVersion
        self.searchAPI = searchAPI
    }

    /// Cancel a previously started task
    public func cancel() {
        guard case let .started(taskGroup) = status else {
            assertionFailure()
            return
        }

        taskGroup.cancelAll()
    }

    /// Start the search task. Errors will not be thrown.
    public func start() async throws -> SearchResult {
        guard case .pending = status else {
            assertionFailure()
            return SearchResult()
        }

        return try await withThrowingTaskGroup(
            of: SearchResultAggregator.self,
            returning: SearchResult.self
        ) { @MainActor taskGroup in

            status = .started(taskGroup: taskGroup)

            // search services
            taskGroup.addTask {
                try await self.performRemoteSearchForServices()
            }

            // search People or groups
            taskGroup.addTask {
                try await self.performLocalLookup()
            }
            taskGroup.addTask {
                try await self.performLocalSearch()
            }

            // v1
            taskGroup.addTask {
                try await self.performRemoteSearchForTeamUser()
            }

            // v2+
            taskGroup.addTask {
                try await self.performRemoteSearch() // TODO: clean up
                /*
                let result = await SearchContactsSubtask()
                    .perform()
                let partialResult = SearchResult(
                    context: contextProvider.viewContext,
                    contacts: [],
                    teamMembers: includeActiveTeamMembers ? searchUsers.filter(\.isTeamMember) : [],
                    directory: searchUsers.filter { !$0.isConnected && !$0.isTeamMember },
                    conversations: [],
                    services: [],
                    searchUsersCache: searchUsersCache
                )
                return { aggregatedResult in
                    aggregatedResult.union(withDirectoryResult: partialResult) // TODO: replace, put code here?
                }
                 */
            }
            taskGroup.addTask {
                try await self.performUserLookup()
            }

            var result = SearchResult()
            while let aggregator = try await taskGroup.next() {
                aggregator(&result)
            }

            // add to search users cache
            let searchUserObserverCenter = self.contextProvider.viewContext.searchUserObserverCenter
            result.directory.forEach(searchUserObserverCenter.addSearchUser)
            result.bots.compactMap { $0 as? ZMSearchUser }.forEach(searchUserObserverCenter.addSearchUser)

            return result
        }
    }
}

extension SearchTask {

    /// Look up a user ID from contacts and teamMembers locally.
    private func performLocalLookup() async -> SearchResultAggregator {

        guard case let .lookup(qualifiedID) = type else {
            return { _ in }
        }

        let searchContext = contextProvider.newBackgroundContext()
        let (teamMemberIDs, connectedUserIDs) = await searchContext.perform {

            let selfUser = ZMUser.selfUser(in: searchContext)

            var options = SearchOptions()
            options.updateForSelfUserTeamRole(selfUser: selfUser)

            /// search for the local user with matching user ID and active
            let activeMembers = self.teamMembers(
                matchingQuery: "",
                team: selfUser.team,
                searchOptions: options,
                in: searchContext
            )
            let teamMembers = activeMembers
                .filter { $0.remoteIdentifier == qualifiedID.uuid }
                .compactMap(\.user)
            let connectedUsers = self.connectedUsers(matchingQuery: "", hostedOnDomain: nil, in: searchContext)
                .filter { $0.remoteIdentifier == qualifiedID.uuid }
            return (teamMembers.map(\.objectID), connectedUsers.map(\.objectID))

        }

        let viewContext = contextProvider.viewContext
        return await viewContext.perform { () -> SearchResultAggregator in

            let copiedTeamMembers = teamMemberIDs
                .compactMap { viewContext.object(with: $0) as? Member }
            let copiedConnectedUsers = connectedUserIDs
                .compactMap { viewContext.object(with: $0) as? ZMUser }

            let result = SearchResult(
                context: viewContext,
                contacts: copiedConnectedUsers.map {
                    ZMSearchUser(
                        contextProvider: self.contextProvider,
                        user: $0,
                        searchUsersCache: self.searchUsersCache
                    )
                },
                teamMembers: copiedTeamMembers.compactMap(\.user).map {
                    ZMSearchUser(
                        contextProvider: self.contextProvider,
                        user: $0,
                        searchUsersCache: self.searchUsersCache
                    )
                },
                directory: [],
                conversations: [],
                apps: [],
                bots: [],
                searchUsersCache: self.searchUsersCache
            )

            return { $0 = $0.union(withLocalResult: result.copy(on: viewContext)) }

        }

    }

    func performLocalSearch() async -> SearchResultAggregator {
        guard case let .search(request) = type else {
            return { _ in }
        }

        let searchContext = contextProvider.newBackgroundContext()
        let (connectedUserIDs, teamMemberIDs, conversationIDs) = await searchContext.perform { [self] in

            var team: WireDataModel.Team?
            if let teamObjectID = request.team?.objectID {
                team = (try? searchContext.existingObject(with: teamObjectID)) as? WireDataModel.Team
            }

            let selfUser = ZMUser.selfUser(in: searchContext)
            let connectedUsers = request.searchOptions
                .contains(.contacts) ? connectedUsers(
                    matchingQuery: request.normalizedQuery,
                    hostedOnDomain: request.searchDomain,
                    in: searchContext
                ) : []
            let teamMembers = request.searchOptions.contains(.teamMembers) ? teamMembers(
                matchingQuery: request.normalizedQuery,
                team: team,
                searchOptions: request.searchOptions,
                in: searchContext
            ) : []

            let conversations = request.searchOptions.contains(.conversations) ? conversations(
                matchingQuery: request.query,
                selfUser: selfUser,
                in: searchContext
            ) : []

            return (
                connectedUsers.map(\.objectID),
                teamMembers.map(\.objectID),
                conversations.map(\.objectID)
            )

        }

        let viewContext = contextProvider.viewContext
        return await viewContext.perform { [self] in

            let copiedConnectedUsers = connectedUserIDs
                .compactMap { viewContext.object(with: $0) as? ZMUser }
            let searchConnectedUsers = copiedConnectedUsers
                .map {
                    ZMSearchUser(
                        contextProvider: contextProvider,
                        user: $0,
                        searchUsersCache: searchUsersCache
                    )
                }
                .filter { $0.name?.isEmpty == false }

            let copiedteamMembers = teamMemberIDs.compactMap {
                contextProvider.viewContext.object(with: $0) as? Member
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
                conversations: conversationIDs.compactMap { viewContext.object(with: $0) as? ZMConversation },
                apps: [],
                bots: [],
                searchUsersCache: searchUsersCache
            )

            return { $0 = $0.union(withLocalResult: result.copy(on: viewContext)) }

        }
    }

    private func filterNonActiveTeamMembers(
        members: [Member],
        in context: NSManagedObjectContext
    ) -> [Member] {
        let activeConversations = ZMUser.selfUser(in: context).activeConversations
        let activeContacts = Set(activeConversations.flatMap(\.localParticipants))
        let selfUser = ZMUser.selfUser(in: context)

        return members.filter {
            guard let user = $0.user else { return false }
            return selfUser.membership?.createdBy == user || activeContacts.contains(user)
        }
    }

    private func teamMembers(
        matchingQuery query: String,
        team: WireDataModel.Team?,
        searchOptions: SearchOptions,
        in context: NSManagedObjectContext
    ) -> [Member] {
        var partialResult = team?.members(matchingQuery: query) ?? []

        if searchOptions.contains(.excludeNonActiveTeamMembers) {
            partialResult = filterNonActiveTeamMembers(
                members: partialResult,
                in: context
            )
        }

        if searchOptions.contains(.excludeNonActivePartners) {
            let query = query.strippingLeadingAtSign()
            let selfUser = ZMUser.selfUser(in: context)
            let activeConversations = ZMUser.selfUser(in: context).activeConversations
            let activeContacts = Set(activeConversations.flatMap(\.localParticipants))

            partialResult = partialResult.filter { membership in
                if let user = membership.user {
                    user.teamRole != .partner || user.handle == query || membership
                        .createdBy == selfUser || activeContacts.contains(user)
                } else {
                    false
                }
            }
        }

        return partialResult
    }

    private func connectedUsers(
        matchingQuery query: String,
        hostedOnDomain: String?,
        in context: NSManagedObjectContext
    ) -> [ZMUser] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = if let hostedOnDomain {
            ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(
                withSearch: query,
                hostedOnDomain: hostedOnDomain
            ))
        } else {
            ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(withSearch: query))
        }

        return context.fetchOrAssert(request: fetchRequest) as? [ZMUser] ?? []
    }

    private func conversations(
        matchingQuery query: SearchRequest.Query,
        selfUser: ZMUser,
        in context: NSManagedObjectContext
    ) -> [ZMConversation] {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: use the interface with team param?
        let fetchRequest = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(
            forSearchQuery: query.string,
            selfUser: selfUser
        ))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: ZMNormalizedUserDefinedNameKey, ascending: true)]

        var conversations = context.fetchOrAssert(request: fetchRequest) as? [ZMConversation] ?? []

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

    func performUserLookup() async -> SearchResultAggregator {
        guard
            case let .lookup(qualifiedID) = type,
            let apiVersion
        else { return { _ in } }

        return await withCheckedContinuation { continuation in

            let request = Self.searchRequestForUser(qualifiedID: qualifiedID, apiVersion: apiVersion)
            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                guard
                    let self,
                    let payload = response.payload?.asDictionary(),
                    let partialResult = SearchResult(
                        userLookupPayload: payload,
                        contextProvider: contextProvider,
                        searchUsersCache: searchUsersCache
                    )
                else { return continuation.resume(returning: { _ in }) }

                continuation.resume(returning: { $0 = $0.union(withDirectoryResult: partialResult) })
            })

            transportSession.enqueueOneTime(request)
        }

    }

    // GET /users/:id has been removed in v1.
    // We should use the qualified endpoint GET /users/:domain/:id instead.
    // https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/603095166/API+changes+v1+v2
    private static func searchRequestForUser(
        qualifiedID: WireDataModel.QualifiedID,
        apiVersion: WireTransport.APIVersion
    ) -> ZMTransportRequest {
        (apiVersion <= .v1)
            ? .init(getFromPath: "/users/\(qualifiedID.uuid.transportString())", apiVersion: apiVersion.rawValue)
            : .init(
                getFromPath: "/users/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())",
                apiVersion: apiVersion.rawValue
            )
    }

}

extension SearchTask {

    func performRemoteSearch() async throws -> SearchResultAggregator {
        guard
            let apiVersion,
            apiVersion >= .v1,
            case let .search(searchRequest) = type,
            !searchRequest.query.string.isEmpty, // backend won't return anything for empty queries
            !searchRequest.searchOptions.contains(.localResultsOnly),
            !searchRequest.searchOptions.isDisjoint(with: [.directory, .teamMembers, .federated])
        else {
            return { _ in }
        }

        // TODO: similar to this
        /*
            do {
                let contacts = try await searchAPI.searchContacts(
                    query: searchRequest.query.string.lowercased(),
                    domain: searchRequest.searchDomain ?? "",
                    type: .regular // TODO: correct?
                ).documents

                try _Concurrency.Task.checkCancellation()

                let queryLowercased = searchRequest.query.string.lowercased()
                let filteredContacts = contacts.filter { contact in
                    return !searchRequest.query.isHandleQuery ||
                    contact.name.hasPrefix("@") ||
                    (contact.handle?.lowercased().contains(queryLowercased) ?? false)
                }

                let searchUsers = filteredContacts.compactMap { filteredContact in
                    guard let id = filteredContact.id else { return ZMSearchUser?.none }
                    let accentColor = if let accentID = filteredContact.accentID, let rawValue = Int16(exactly: accentID), let accentColor = AccentColor(
                        rawValue: rawValue
                    ) { accentColor } else { AccentColor.default }
                    let localUser = ZMUser.fetch(
                        with: id,
                        domain: filteredContact.qualifiedID?.domain,
                        in: contextProvider.viewContext
                    )
                    if let searchUser = searchUsersCache?.object(forKey: id as NSUUID) {
                        searchUser.user = localUser
                        return searchUser
                    } else {
                        return ZMSearchUser(
                            contextProvider: contextProvider,
                            name: filteredContact.name,
                            handle: filteredContact.handle,
                            accentColor: .from(accentColor: accentColor),
                            remoteIdentifier: filteredContact.id,
                            domain: filteredContact.qualifiedID?.domain,
                            teamIdentifier: filteredContact.team,
                            user: localUser,
                            searchUsersCache: searchUsersCache
                        )
                    }
                }

                try _Concurrency.Task.checkCancellation()

                let searchOptions = searchRequest.searchOptions
                let includeActiveTeamMembers = searchOptions.contains(.teamMembers) &&
                searchOptions.isDisjoint(with: .excludeNonActiveTeamMembers)
                let searchResult = SearchResult(
                    context: contextProvider.viewContext,
                    contacts: [],
                    teamMembers: includeActiveTeamMembers ? searchUsers.filter(\.isTeamMember) : [],
                    directory: searchUsers.filter { !$0.isConnected && !$0.isTeamMember },
                    conversations: [],
                    services: [],
                    searchUsersCache: searchUsersCache
                )

                try _Concurrency.Task.checkCancellation()

                if searchRequest.searchOptions.contains(.teamMembers) {
                    performTeamMembershipLookup(on: searchResult, searchRequest: searchRequest)
                } else {
                    completeRemoteSearch(searchResult: searchResult)
                }
         */

        return await withCheckedContinuation { continuation in

            let request = Self.searchRequestInDirectory(withRequest: searchRequest, apiVersion: apiVersion)

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in
                guard let self else { return }

                guard
                    let payload = response.payload?.asDictionary(),
                    let partialResult = SearchResult(
                        payload: payload,
                        query: searchRequest.query,
                        searchOptions: searchRequest.searchOptions,
                        contextProvider: contextProvider,
                        searchUsersCache: searchUsersCache
                    )
                else {
                    return continuation.resume(returning: { _ in })
                }

                if searchRequest.searchOptions.contains(.teamMembers) {
                    Task {
                        let aggregator = await self.performTeamMembershipLookup(
                            on: partialResult,
                            searchRequest: searchRequest
                        )
                        continuation.resume(returning: aggregator)
                    }
                } else {
                    continuation.resume(returning: { $0 = $0.union(withDirectoryResult: partialResult) })
                }
            })

            transportSession.enqueueOneTime(request)
        }
    }

    private func performTeamMembershipLookup(
        on searchResult: SearchResult,
        searchRequest: SearchRequest
    ) async -> SearchResultAggregator {

        let viewContext = contextProvider.viewContext
        let (teamMembersIDs, teamID) = await contextProvider.viewContext.perform { [viewContext] in
            let teamMembersIDs = searchResult.teamMembers.compactMap(\.remoteIdentifier)
            let teamID = ZMUser.selfUser(in: viewContext).team?.remoteIdentifier
            return (teamMembersIDs, teamID)
        }

        guard
            let apiVersion,
            let teamID,
            !teamMembersIDs.isEmpty
        else {
            return { $0 = $0.union(withDirectoryResult: searchResult) }
        }

        let request = Self.fetchTeamMembershipRequest(
            teamID: teamID,
            teamMemberIDs: teamMembersIDs,
            apiVersion: apiVersion
        )

        return await withCheckedContinuation { continuation in

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                guard
                    let self,
                    let rawData = response.rawData,
                    let payload = MembershipListPayload(rawData)
                else { return continuation.resume(returning: { _ in }) }

                var updatedResult = searchResult
                updatedResult.extendWithMembershipPayload(payload: payload)
                updatedResult.filterBy(
                    searchOptions: searchRequest.searchOptions,
                    query: searchRequest.query.string,
                    contextProvider: contextProvider
                )

                continuation.resume(returning: { $0 = $0.union(withDirectoryResult: updatedResult) })

            })

            transportSession.enqueueOneTime(request)

        }

    }

    private static func searchRequestInDirectory(
        withRequest searchRequest: SearchRequest,
        fetchLimit: Int = 10,
        apiVersion: WireTransport.APIVersion
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

        let path = url.string?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        return ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
    }

    private static func fetchTeamMembershipRequest(
        teamID: UUID,
        teamMemberIDs: [UUID],
        apiVersion: WireTransport.APIVersion
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

    func performRemoteSearchForTeamUser() async -> SearchResultAggregator {
        guard
            let apiVersion,
            apiVersion <= .v1,
            case let .search(searchRequest) = type,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.directory)
        else { return { _ in } }

        let viewContext = contextProvider.viewContext
        return await withCheckedContinuation { continuation in

            let request = Self.searchRequestInDirectory(
                withHandle: searchRequest.query.string,
                apiVersion: apiVersion
            )

            request.add(ZMCompletionHandler(on: viewContext) { [weak self] response in

                guard
                    let self,
                    let payload = response.payload?.asArray(),
                    let userPayload = (payload.first as? ZMTransportData)?.asDictionary()
                else {
                    return continuation.resume(returning: { _ in })
                }

                guard
                    let handle = userPayload["handle"] as? String,
                    let name = userPayload["name"] as? String,
                    let id = userPayload["id"] as? String
                else {
                    return continuation.resume(returning: { _ in })
                }

                let document = ["handle": handle, "name": name, "id": id]
                let documentPayload = ["documents": [document]]
                guard let partialResult = SearchResult(
                    payload: documentPayload,
                    query: searchRequest.query,
                    searchOptions: searchRequest.searchOptions,
                    contextProvider: contextProvider,
                    searchUsersCache: searchUsersCache
                ) else {
                    return continuation.resume(returning: { _ in })
                }

                if let user = partialResult.directory.first, !user.isSelfUser {
                    let partialResult = SearchResult(
                        context: viewContext,
                        contacts: [],
                        teamMembers: [],
                        directory: partialResult.directory,
                        conversations: [],
                        apps: [],
                        bots: [],
                        searchUsersCache: searchUsersCache
                    )
                    continuation.resume(returning: { aggregatedResult in
                        if !aggregatedResult.directory.contains(user) {
                            aggregatedResult = aggregatedResult.union(prependingDirectory: partialResult)
                        }
                    })
                } else {
                    continuation.resume(returning: { _ in })
                }
            })

            transportSession.enqueueOneTime(request)
        }
    }

    private static func searchRequestInDirectory(
        withHandle handle: String,
        apiVersion: WireDataModel.APIVersion
    ) -> ZMTransportRequest {
        var handle = handle.lowercased()

        if handle.hasPrefix("@") {
            handle = String(handle[handle.index(after: handle.startIndex)...])
        }

        var url = URLComponents()
        url.path = "/users"
        url.queryItems = [URLQueryItem(name: "handles", value: handle)]
        let urlStr = url.string?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        return ZMTransportRequest(getFromPath: urlStr, apiVersion: apiVersion.rawValue)
    }
}

extension SearchTask {

    func performRemoteSearchForServices() async -> SearchResultAggregator {

        let searchContext = contextProvider.newBackgroundContext()
        let teamIdentifier = await searchContext.perform {
            ZMUser.selfUser(in: searchContext).team?.remoteIdentifier
        }

        guard
            let apiVersion,
            let teamIdentifier,
            case let .search(searchRequest) = type,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.bots)
        else { return { _ in } }

        return await withCheckedContinuation { continuation in

            let request = Self.servicesSearchRequest(
                teamIdentifier: teamIdentifier,
                query: searchRequest.query.string,
                apiVersion: apiVersion
            )

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                guard
                    let self,
                    let payload = response.payload?.asDictionary(),
                    let partialResult = SearchResult(
                        servicesPayload: payload,
                        query: searchRequest.query.string,
                        contextProvider: contextProvider,
                        searchUsersCache: searchUsersCache
                    )
                else { return continuation.resume(returning: { _ in }) }

                continuation.resume { $0 = $0.union(withBotResult: partialResult) }

            })

            transportSession.enqueueOneTime(request)

        }
    }

    static func servicesSearchRequest(
        teamIdentifier: UUID,
        query: String,
        apiVersion: WireTransport.APIVersion
    ) -> ZMTransportRequest {
        var url = URLComponents()
        url.path = "/teams/\(teamIdentifier.transportString())/services/whitelisted"

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            url.queryItems = [URLQueryItem(name: "prefix", value: trimmedQuery)]
        }
        let urlStr = url.string?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        return ZMTransportRequest(getFromPath: urlStr, apiVersion: apiVersion.rawValue)
    }
}
