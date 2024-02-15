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

public class SearchTask {

    public enum Task {
        case search(searchRequest: SearchRequest)
        case lookup(userId: UUID)
    }

    public typealias ResultHandler = (_ result: SearchResult, _ isCompleted: Bool) -> Void

    fileprivate let transportSession: TransportSessionType
    fileprivate let searchContext: NSManagedObjectContext
    fileprivate let contextProvider: ContextProvider
    fileprivate let task: Task
    fileprivate var userLookupTaskIdentifier: ZMTaskIdentifier?
    fileprivate var directoryTaskIdentifier: ZMTaskIdentifier?
    fileprivate var teamMembershipTaskIdentifier: ZMTaskIdentifier?
    fileprivate var handleTaskIdentifier: ZMTaskIdentifier?
    fileprivate var servicesTaskIdentifier: ZMTaskIdentifier?
    fileprivate var resultHandlers: [ResultHandler] = []
    fileprivate var result = SearchResult(
        contacts: [],
        teamMembers: [],
        addressBook: [],
        directory: [],
        conversations: [],
        services: []
    )

    fileprivate var tasksRemaining = 0 {
        didSet {
            // only trigger handles if decrement to 0
            if oldValue > tasksRemaining {
                let isCompleted = tasksRemaining == 0
                resultHandlers.forEach { $0(result, isCompleted) }

                if isCompleted {
                    resultHandlers.removeAll()
                }
            }
        }
    }

    convenience init(request: SearchRequest,
                     searchContext: NSManagedObjectContext,
                     contextProvider: ContextProvider,
                     transportSession: TransportSessionType) {
        self.init(task: .search(searchRequest: request), searchContext: searchContext, contextProvider: contextProvider, transportSession: transportSession)
    }

    convenience init(lookupUserId userId: UUID,
                     searchContext: NSManagedObjectContext,
                     contextProvider: ContextProvider,
                     transportSession: TransportSessionType) {
        self.init(task: .lookup(userId: userId), searchContext: searchContext, contextProvider: contextProvider, transportSession: transportSession)
    }

    public init(task: Task, searchContext: NSManagedObjectContext, contextProvider: ContextProvider, transportSession: TransportSessionType) {
        self.task = task
        self.transportSession = transportSession
        self.searchContext = searchContext
        self.contextProvider = contextProvider
    }

    public func addResultHandler(_ resultHandler: @escaping ResultHandler) {
        resultHandlers.append(resultHandler)
    }

    /// Cancel a previously started task
    public func cancel() {
        resultHandlers.removeAll()

        teamMembershipTaskIdentifier.flatMap(transportSession.cancelTask)
        userLookupTaskIdentifier.flatMap(transportSession.cancelTask)
        directoryTaskIdentifier.flatMap(transportSession.cancelTask)
        servicesTaskIdentifier.flatMap(transportSession.cancelTask)
        handleTaskIdentifier.flatMap(transportSession.cancelTask)

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
        performUserLookup()
        performRemoteSearchForTeamUser()
        // v2+
        performRemoteSearch()
    }
}

extension SearchTask {

    /// look up a user ID from contacts and teamMembers locally.
    private func performLocalLookup() {
         guard case .lookup(let userId) = task else { return }

        tasksRemaining += 1

        searchContext.performGroupedBlock { [self] in
            let selfUser = ZMUser.selfUser(in: searchContext)

            var options = SearchOptions()

            options.updateForSelfUserTeamRole(selfUser: selfUser)

            /// search for the local user with matching user ID and active
            let one2oneGroupConversationUsers = oneToOneGroupConversationUsers(selfUser: selfUser)
            let connectedUsers = connectedUsers(matchingQuery: "").filter { $0.remoteIdentifier == userId }

            contextProvider.viewContext.performGroupedBlock { [self] in

                let copiedOne2oneConversationUsers = one2oneGroupConversationUsers.compactMap { contextProvider.viewContext.object(with: $0.objectID) as? ZMUser }
                let copiedConnectedUsers = connectedUsers.compactMap { contextProvider.viewContext.object(with: $0.objectID) as? ZMUser }

                let result = SearchResult(
                    contacts: copiedConnectedUsers.map { ZMSearchUser(contextProvider: contextProvider, user: $0) },
                    teamMembers: copiedOne2oneConversationUsers.map { ZMSearchUser(contextProvider: contextProvider, user: $0) },
                    addressBook: [],
                    directory: [],
                    conversations: [],
                    services: []
                )

                self.result = self.result.union(withLocalResult: result.copy(on: contextProvider.viewContext))

                tasksRemaining -= 1
            }
        }
    }

    func performLocalSearch() {
        guard case .search(let request) = task else { return }

        tasksRemaining += 1

        searchContext.performGroupedBlock { [self] in

            let selfUser = ZMUser.selfUser(in: searchContext)
            let connectedUsers = request.searchOptions.contains(.contacts) ? connectedUsers(matchingQuery: request.normalizedQuery) : []
            let one2oneGroupConversationUsers = oneToOneGroupConversationUsers(selfUser: selfUser)
            let conversations = request.searchOptions.contains(.conversations) ? conversations(matchingQuery: request.query, selfUser: selfUser) : []

            contextProvider.viewContext.performGroupedBlock { [self] in

                let copiedConnectedUsers = connectedUsers.compactMap { contextProvider.viewContext.object(with: $0.objectID) as? ZMUser }
                let searchConnectedUsers = copiedConnectedUsers
                    .map { ZMSearchUser(contextProvider: contextProvider, user: $0) }
                    .filter { !$0.hasEmptyName }
                let copiedOne2oneConversationUsers = one2oneGroupConversationUsers.compactMap { contextProvider.viewContext.object(with: $0.objectID) as? ZMUser }
                let searchOne2oneConversationUsers = copiedOne2oneConversationUsers
                    .map { ZMSearchUser(contextProvider: contextProvider, user: $0) }
                    .filter { !$0.hasEmptyName }

                let result = SearchResult(
                    contacts: searchConnectedUsers,
                    teamMembers: searchOne2oneConversationUsers,
                    addressBook: [],
                    directory: [],
                    conversations: conversations,
                    services: []
                )

                self.result = self.result.union(withLocalResult: result.copy(on: contextProvider.viewContext))

                if request.searchOptions.contains(.addressBook) {
                    self.result = self.result.extendWithContactsFromAddressBook(request.normalizedQuery, contextProvider: contextProvider)
                }

                tasksRemaining -= 1
            }
        }
    }

    private func filterNonActiveTeamMembers(members: [Member]) -> [Member] {
        let activeConversations = ZMUser.selfUser(in: searchContext).activeConversations
        let activeContacts = Set(activeConversations.flatMap { $0.localParticipants })
        let selfUser = ZMUser.selfUser(in: searchContext)

        return members.filter {
            guard let user = $0.user else { return false }
            return selfUser.membership?.createdBy == user || activeContacts.contains(user)
        }
    }

    func connectedUsers(matchingQuery query: String) -> [ZMUser] {
        let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(withSearch: query))
        return searchContext.fetchOrAssert(request: fetchRequest) as? [ZMUser] ?? []
    }

    func oneToOneGroupConversationUsers(selfUser: ZMUser) -> Set<ZMUser> {
        let fetchRequest = ZMConversation.sortedFetchRequest(with: ZMConversation.predicateForTeamOneToOneConversation())
        let conversations = searchContext.fetchOrAssert(request: fetchRequest) as? [ZMConversation] ?? []
        return conversations
            .reduce(Set()) { users, conversation in
                users.union(conversation.localParticipants)
            }
            .subtracting([selfUser])
    }

    func conversations(matchingQuery query: SearchRequest.Query, selfUser: ZMUser) -> [ZMConversation] {
        // swiftlint:disable todo_requires_jira_link
        // TODO: use the interface with tean param?
        // swiftlint:enable todo_requires_jira_link
        let fetchRequest = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(forSearchQuery: query.string, selfUser: selfUser))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: ZMNormalizedUserDefinedNameKey, ascending: true)]

        var conversations = searchContext.fetchOrAssert(request: fetchRequest) as? [ZMConversation] ?? []

        if query.isHandleQuery {
            // if we are searching for a username only include conversations with matching displayName
            conversations = conversations.filter { ($0.displayName ?? "").contains(query.string) }
        }

        let matchingPredicate = ZMConversation.userDefinedNamePredicate(forSearch: query.string)
        var matching: [ZMConversation] = []
        var nonMatching: [ZMConversation] = []

        // re-sort conversations without a matching userDefinedName to the end of the result list
        conversations.forEach { (conversation) in
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

    func performUserLookup() {
        guard
            case .lookup(let userId) = task,
            let apiVersion = BackendInfo.apiVersion,
            apiVersion <= .v1
        else { return }

        tasksRemaining += 1

        searchContext.performGroupedBlock { [self] in
            let request  = type(of: self).searchRequestForUser(withUUID: userId, apiVersion: apiVersion)

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in
                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let contextProvider = self?.contextProvider,
                    let payload = response.payload?.asDictionary(),
                    let result = SearchResult(userLookupPayload: payload, contextProvider: contextProvider)
                else {
                        return
                }

                if let updatedResult = self?.result.union(withDirectoryResult: result) {
                    self?.result = updatedResult
                }
            })

            request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
                self?.userLookupTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }

    }

    static func searchRequestForUser(withUUID uuid: UUID, apiVersion: APIVersion) -> ZMTransportRequest {
        .init(getFromPath: "/users/\(uuid.transportString())", apiVersion: apiVersion.rawValue)
    }

}

extension SearchTask {

    func performRemoteSearch() {
        guard
            let apiVersion = BackendInfo.apiVersion,
            apiVersion >= .v1,
            case .search(let searchRequest) = task,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            !searchRequest.searchOptions.isDisjoint(with: [.directory, .teamMembers, .federated])
        else {
            return
        }

        tasksRemaining += 1

        searchContext.performGroupedBlock { [self] in
            let request = Self.searchRequestInDirectory(withRequest: searchRequest, apiVersion: apiVersion)

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                guard
                    let contextProvider = self?.contextProvider,
                    let payload = response.payload?.asDictionary(),
                    let result = SearchResult(
                        payload: payload,
                        query: searchRequest.query,
                        searchOptions: searchRequest.searchOptions,
                        contextProvider: contextProvider
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

            request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
                self?.directoryTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    func performTeamMembershipLookup(on searchResult: SearchResult, searchRequest: SearchRequest) {
        let teamMembersIDs = searchResult.teamMembers.compactMap(\.remoteIdentifier)

        guard
            let apiVersion = BackendInfo.apiVersion,
            let teamID = ZMUser.selfUser(in: contextProvider.viewContext).team?.remoteIdentifier,
            !teamMembersIDs.isEmpty
        else {
            completeRemoteSearch(searchResult: searchResult)
            return
        }

        let request = type(of: self).fetchTeamMembershipRequest(teamID: teamID, teamMemberIDs: teamMembersIDs, apiVersion: apiVersion)

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
            updatedResult.filterBy(searchOptions: searchRequest.searchOptions, query: searchRequest.query.string, contextProvider: contextProvider)

            self?.completeRemoteSearch(searchResult: updatedResult)

        })

        request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
            self?.teamMembershipTaskIdentifier = taskIdentifier
        })

        transportSession.enqueueOneTime(request)
    }

    func completeRemoteSearch(searchResult: SearchResult? = nil) {
        defer {
            tasksRemaining -= 1
        }

        if let searchResult = searchResult {
            result = result.union(withDirectoryResult: searchResult)
        }
    }

    static func searchRequestInDirectory(withRequest searchRequest: SearchRequest, fetchLimit: Int = 10, apiVersion: APIVersion) -> ZMTransportRequest {
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

    static func fetchTeamMembershipRequest(teamID: UUID, teamMemberIDs: [UUID], apiVersion: APIVersion) -> ZMTransportRequest {

        let path = "/teams/\(teamID.transportString())/get-members-by-ids-using-post"
        let payload = ["user_ids": teamMemberIDs.map { $0.transportString() }]

        return ZMTransportRequest(path: path, method: .post, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

}

extension SearchTask {

    func performRemoteSearchForTeamUser() {
        guard
            let apiVersion = BackendInfo.apiVersion,
            apiVersion <= .v1,
            case .search(let searchRequest) = task,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.directory)
        else { return }

        tasksRemaining += 1

        searchContext.performGroupedBlock { [self] in
            let request = type(of: self).searchRequestInDirectory(withHandle: searchRequest.query.string, apiVersion: apiVersion)

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
                    contextProvider: contextProvider
                ) else {
                    return
                }

                if let user = result.directory.first, !user.isSelfUser {
                    if let prevResult = self?.result {
                        // prepend result to prevResult only if it doesn't contain it
                        if !prevResult.directory.contains(user) {
                            self?.result = SearchResult(
                                contacts: prevResult.contacts,
                                teamMembers: prevResult.teamMembers,
                                addressBook: prevResult.addressBook,
                                directory: result.directory + prevResult.directory,
                                conversations: prevResult.conversations,
                                services: prevResult.services
                            )
                        }
                    } else {
                        self?.result = result
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
        guard
            let apiVersion = BackendInfo.apiVersion,
            case .search(let searchRequest) = task,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.services)
        else { return }

        tasksRemaining += 1

        searchContext.performGroupedBlock { [self] in
            let selfUser = ZMUser.selfUser(in: searchContext)
            guard let teamIdentifier = selfUser.team?.remoteIdentifier else { return }

            let request = type(of: self).servicesSearchRequest(teamIdentifier: teamIdentifier, query: searchRequest.query.string, apiVersion: apiVersion)

            request.add(ZMCompletionHandler(on: contextProvider.viewContext) { [weak self] response in

                defer {
                    self?.tasksRemaining -= 1
                }

                guard
                    let contextProvider = self?.contextProvider,
                    let payload = response.payload?.asDictionary(),
                    let result = SearchResult(servicesPayload: payload, query: searchRequest.query.string, contextProvider: contextProvider)
                    else {
                        return
                }

                if let updatedResult = self?.result.union(withServiceResult: result) {
                    self?.result = updatedResult
                }
            })

            request.add(ZMTaskCreatedHandler(on: searchContext) { [weak self] taskIdentifier in
                self?.servicesTaskIdentifier = taskIdentifier
            })

            transportSession.enqueueOneTime(request)
        }
    }

    static func servicesSearchRequest(teamIdentifier: UUID, query: String, apiVersion: APIVersion) -> ZMTransportRequest {
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

extension ZMSearchUser {

    public var hasEmptyName: Bool {
        guard let name = name else {
            return true
        }
        return name.isEmpty
    }

}
