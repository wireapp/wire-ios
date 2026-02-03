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

public class SearchTask {

    public enum Task {
        case search(searchRequest: SearchRequest)
        case lookup(qualifiedID: QualifiedID)
    }

    public typealias ResultHandler = (_ partialResult: SearchResult, _ isCompleted: Bool) -> Void

    private let apiVersion: WireTransport.APIVersion?
    private let transportSession: TransportSessionType
    private let contextProvider: ContextProvider
    private let searchUsersCache: SearchUsersCache?

    private let task: Task
    private var userLookupTaskIdentifier: ZMTaskIdentifier?
    private var directoryTaskIdentifier: ZMTaskIdentifier?
    private var teamMembershipTaskIdentifier: ZMTaskIdentifier?
    private var handleTaskIdentifier: ZMTaskIdentifier?
    private var servicesTaskIdentifier: ZMTaskIdentifier?
    private var resultHandlers: [ResultHandler] = []
    private var aggregatedResult = SearchResult(
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
                resultHandlers.forEach { $0(aggregatedResult, isCompleted) }

                if isCompleted {
                    resultHandlers.removeAll()
                }
            }
        }
    }

    convenience init(
        request: SearchRequest,
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        apiVersion: WireTransport.APIVersion?
    ) {
        self.init(
            task: .search(searchRequest: request),
            contextProvider: contextProvider,
            transportSession: transportSession,
            searchUsersCache: searchUsersCache,
            apiVersion: apiVersion
        )
    }

    convenience init(
        qualifiedID: QualifiedID,
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        apiVersion: WireTransport.APIVersion?
    ) {
        self.init(
            task: .lookup(qualifiedID: qualifiedID),
            contextProvider: contextProvider,
            transportSession: transportSession,
            searchUsersCache: searchUsersCache,
            apiVersion: apiVersion
        )
    }

    public init(
        task: Task,
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        apiVersion: WireTransport.APIVersion?
    ) {
        self.task = task
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
        guard case let .lookup(qualifiedID) = task else { return }

        tasksRemaining += 1

        let searchContext = contextProvider.newBackgroundContext()
        let viewContext = contextProvider.viewContext
        searchContext.perform { [self] in
            let selfUser = ZMUser.selfUser(in: searchContext)

            var options = SearchOptions()

            options.updateForSelfUserTeamRole(selfUser: selfUser)

            /// search for the local user with matching user ID and active
            let activeMembers = teamMembers(
                matchingQuery: "",
                team: selfUser.team,
                searchOptions: options,
                in: searchContext
            )
            let teamMembers = activeMembers.filter { $0.remoteIdentifier == qualifiedID.uuid }
            let connectedUsers = connectedUsers(matchingQuery: "", hostedOnDomain: nil, in: searchContext)
                .filter { $0.remoteIdentifier == qualifiedID.uuid }

            viewContext.performGroupedBlock { [self] in

                let copiedTeamMembers = teamMembers.compactMap(\.user)
                    .compactMap { viewContext.object(with: $0.objectID) as? Member }
                let copiedConnectedUsers = connectedUsers
                    .compactMap { viewContext.object(with: $0.objectID) as? ZMUser }

                if !copiedTeamMembers.isEmpty {
                    print("#### \(#function):\(#line) copiedTeamMembers: \(copiedTeamMembers)") // TODO: revert d03e77adff1bf197fd56a3a9e91d364922c74654
                }
                if !copiedConnectedUsers.isEmpty {
                    print("#### \(#function):\(#line) copiedConnectedUsers: \(copiedConnectedUsers)")
                }

                let partialResult = SearchResult(
                    context: viewContext,
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

                aggregatedResult = aggregatedResult
                    .union(withLocalResult: partialResult.copy(on: viewContext))

                tasksRemaining -= 1
            }
        }
    }

    func performLocalSearch() {
        guard case let .search(request) = task else { return }

        tasksRemaining += 1

        let searchContext = contextProvider.newBackgroundContext()
        let viewContext = contextProvider.viewContext
        searchContext.perform { [self] in

            var team: Team?
            if let teamObjectID = request.team?.objectID {
                team = (try? searchContext.existingObject(with: teamObjectID)) as? Team
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

            viewContext.performGroupedBlock { [self] in

                let copiedConnectedUsers = connectedUsers
                    .compactMap { viewContext.object(with: $0.objectID) as? ZMUser }
                let searchConnectedUsers = copiedConnectedUsers
                    .map {
                        ZMSearchUser(
                            contextProvider: contextProvider,
                            user: $0,
                            searchUsersCache: searchUsersCache
                        )
                    }
                    .filter { !$0.hasEmptyName }

                let copiedteamMembers = teamMembers.compactMap {
                    viewContext.object(with: $0.objectID) as? Member
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

                if !copiedConnectedUsers.isEmpty {
                    print("### \(#function):\(#line) copiedConnectedUsers: \(copiedConnectedUsers)")
                }
                if !searchConnectedUsers.isEmpty {
                    print("### \(#function):\(#line) searchConnectedUsers: \(searchConnectedUsers)")
                }
                if !copiedteamMembers.isEmpty {
                    print("### \(#function):\(#line) copiedteamMembers: \(copiedteamMembers)")
                }
                if !searchTeamMembers.isEmpty {
                    print("### \(#function):\(#line) searchTeamMembers: \(searchTeamMembers)")
                }

                let partialResult = SearchResult(
                    context: viewContext,
                    contacts: searchConnectedUsers,
                    teamMembers: searchTeamMembers,
                    directory: [],
                    conversations: conversations,
                    services: [],
                    searchUsersCache: searchUsersCache
                )

                aggregatedResult = aggregatedResult
                    .union(withLocalResult: partialResult.copy(on: viewContext))

                tasksRemaining -= 1
            }
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

    func teamMembers(
        matchingQuery query: String,
        team: Team?,
        searchOptions: SearchOptions,
        in context: NSManagedObjectContext
    ) -> [Member] {
        var partialResult = team?.members(matchingQuery: query) ?? []
        if !partialResult.isEmpty {
            print("### \(#function):\(#line) partialResult: \(partialResult)")
        }

        if searchOptions.contains(.excludeNonActiveTeamMembers) {
            partialResult = filterNonActiveTeamMembers(
                members: partialResult,
                in: context
            )
            if !partialResult.isEmpty {
                print("### \(#function):\(#line) partialResult: \(partialResult)")
            }
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
            if !partialResult.isEmpty {
                print("### \(#function):\(#line) partialResult: \(partialResult)")
            }
        }

        return partialResult
    }

    func connectedUsers(
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

    func conversations(
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
        if !conversations.isEmpty {
            print("### \(#function):\(#line) conversations: \(conversations)")
        }

        if query.isHandleQuery {
            // if we are searching for a username only include conversations with matching displayName
            conversations = conversations.filter { ($0.displayName ?? "").contains(query.string) }
        }
        if !conversations.isEmpty {
            print("### \(#function):\(#line) conversations: \(conversations)")
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
        if !matching.isEmpty {
            print("### \(#function):\(#line) matching: \(matching)")
        }
        if !nonMatching.isEmpty {
            print("### \(#function):\(#line) nonMatching: \(nonMatching)")
        }

        return matching + nonMatching
    }

}

extension SearchTask {

    func performUserLookup() {
        guard
            case let .lookup(qualifiedID) = task,
            let apiVersion
        else { return }

        tasksRemaining += 1

        let searchContext = contextProvider.newBackgroundContext()
        searchContext.perform { [self] in
            let request = type(of: self).searchRequestForUser(qualifiedID: qualifiedID, apiVersion: apiVersion)
            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in
                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let self,
                    let payload = response.payload?.asDictionary(),
                    let partialResult = SearchResult(
                        userLookupPayload: payload,
                        contextProvider: contextProvider,
                        searchUsersCache: searchUsersCache
                    )
                else { return }

                print("### \(#function):\(#line) partialResult: \(partialResult)")

                let updatedResult = aggregatedResult.union(withDirectoryResult: partialResult)
                aggregatedResult = updatedResult
            })

            request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
                self?.userLookupTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }

    }

    // GET /users/:id has been removed in v1.
    // We should use the qualified endpoint GET /users/:domain/:id instead.
    // https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/603095166/API+changes+v1+v2
    static func searchRequestForUser(qualifiedID: QualifiedID, apiVersion: APIVersion) -> ZMTransportRequest {
        (apiVersion <= .v1)
            ? .init(getFromPath: "/users/\(qualifiedID.uuid.transportString())", apiVersion: apiVersion.rawValue)
            : .init(
                getFromPath: "/users/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())",
                apiVersion: apiVersion.rawValue
            )
    }

}

extension SearchTask {

    func performRemoteSearch() {
        guard
            let apiVersion,
            apiVersion >= .v1,
            case let .search(searchRequest) = task,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            !searchRequest.searchOptions.isDisjoint(with: [.directory, .teamMembers, .federated])
        else {
            return
        }

        tasksRemaining += 1

        let searchContext = contextProvider.newBackgroundContext()
        searchContext.perform { [self] in
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
                    completeRemoteSearch()
                    return
                }

                print("### \(#function):\(#line) partialResult: \(partialResult)")

                if searchRequest.searchOptions.contains(.teamMembers) {
                    performTeamMembershipLookup(on: partialResult, searchRequest: searchRequest)
                } else {
                    completeRemoteSearch(searchResult: partialResult)
                }
            })

            request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
                self?.directoryTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    func performTeamMembershipLookup(on searchResult: SearchResult, searchRequest: SearchRequest) {
        let teamMembersIDs = searchResult.teamMembers.compactMap(\.remoteIdentifier)

        guard
            let apiVersion,
            let teamID = ZMUser.selfUser(in: contextProvider.viewContext).team?.remoteIdentifier,
            !teamMembersIDs.isEmpty
        else {
            completeRemoteSearch(searchResult: searchResult)
            return
        }

        let request = type(of: self).fetchTeamMembershipRequest(
            teamID: teamID,
            teamMemberIDs: teamMembersIDs,
            apiVersion: apiVersion
        )

        request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in
            guard let self else { return }

            guard
                let rawData = response.rawData,
                let payload = MembershipListPayload(rawData)
            else {
                completeRemoteSearch()
                return
            }

            var updatedResult = searchResult
            print("### \(#function):\(#line) updatedResult: \(updatedResult)")
            updatedResult.extendWithMembershipPayload(payload: payload)
            print("### \(#function):\(#line) updatedResult: \(updatedResult)")
            updatedResult.filterBy(
                searchOptions: searchRequest.searchOptions,
                query: searchRequest.query.string,
                contextProvider: contextProvider
            )
            print("### \(#function):\(#line) updatedResult: \(updatedResult)")

            completeRemoteSearch(searchResult: updatedResult)

        })

        let searchContext = contextProvider.newBackgroundContext()
        request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
            self?.teamMembershipTaskIdentifier = taskIdentifier
        })

        transportSession.enqueueOneTime(request)
    }

    func completeRemoteSearch(searchResult: SearchResult? = nil) {
        defer {
            tasksRemaining -= 1
        }

        if let searchResult {
            aggregatedResult = aggregatedResult.union(withDirectoryResult: searchResult)
        }
    }

    static func searchRequestInDirectory(
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

        let path = url.string?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        return ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
    }

    static func fetchTeamMembershipRequest(
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

    func performRemoteSearchForTeamUser() {
        guard
            let apiVersion,
            apiVersion <= .v1,
            case let .search(searchRequest) = task,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.directory)
        else { return }

        tasksRemaining += 1

        let searchContext = contextProvider.newBackgroundContext()
        searchContext.perform { [self] in
            let request = type(of: self).searchRequestInDirectory(
                withHandle: searchRequest.query.string,
                apiVersion: apiVersion
            )

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let self,
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
                guard let partialResult = SearchResult(
                    payload: documentPayload,
                    query: searchRequest.query,
                    searchOptions: searchRequest.searchOptions,
                    contextProvider: contextProvider,
                    searchUsersCache: searchUsersCache
                ) else {
                    return
                }

                print("### \(#function):\(#line) partialResult: \(partialResult)")

                if let user = partialResult.directory.first, !user.isSelfUser {
                    let prevResult = aggregatedResult
                    // prepend result to prevResult only if it doesn't contain it
                    if !prevResult.directory.contains(user) {
                        aggregatedResult = SearchResult(
                            context: prevResult.context,
                            contacts: prevResult.contacts,
                            teamMembers: prevResult.teamMembers,
                            directory: partialResult.directory + prevResult.directory,
                            conversations: prevResult.conversations,
                            services: prevResult.services,
                            searchUsersCache: searchUsersCache
                        )
                        print("### \(#function):\(#line) aggregatedResult: \(aggregatedResult)")
                    }
                }
            })

            request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
                self?.handleTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    static func searchRequestInDirectory(withHandle handle: String, apiVersion: APIVersion) -> ZMTransportRequest {
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

    func performRemoteSearchForServices() {
        let searchContext = contextProvider.newBackgroundContext()
        let teamIdentifier = searchContext.performAndWait {
            ZMUser.selfUser(in: searchContext).team?.remoteIdentifier
        }
        guard
            let apiVersion,
            let teamIdentifier,
            case let .search(searchRequest) = task,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.services)
        else { return }

        tasksRemaining += 1

        searchContext.perform { [self] in

            let request = type(of: self).servicesSearchRequest(
                teamIdentifier: teamIdentifier,
                query: searchRequest.query.string,
                apiVersion: apiVersion
            )

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let self,
                    let payload = response.payload?.asDictionary(),
                    let partialResult = SearchResult(
                        servicesPayload: payload,
                        query: searchRequest.query.string,
                        contextProvider: contextProvider,
                        searchUsersCache: searchUsersCache
                    )
                else {
                    return
                }

                let updatedResult = aggregatedResult.union(withServiceResult: partialResult)
                print("### \(#function):\(#line) updatedResult: \(updatedResult)")
                aggregatedResult = updatedResult
            })

            request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
                self?.servicesTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    static func servicesSearchRequest(
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
        let urlStr = url.string?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        return ZMTransportRequest(getFromPath: urlStr, apiVersion: apiVersion.rawValue)
    }
}

public extension ZMSearchUser {

    var hasEmptyName: Bool {
        guard let name else {
            return true
        }
        return name.isEmpty
    }

}
