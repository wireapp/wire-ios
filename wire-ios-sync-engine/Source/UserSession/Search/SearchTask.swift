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
import WireFoundation
import WireLogging
import WireNetwork
import WireUtilities

public final class SearchTask {

    private let type: `Type`
    private let apiVersion: WireTransport.APIVersion?
    private let transportSession: TransportSessionType
    private let contextProvider: ContextProvider
    private let searchUsersCache: SearchUsersCache?
    private let searchAPI: any SearchAPI
    private let teamsAPI: any TeamsAPI
    private let usersAPI: any UsersAPI

    private var status = Status.pending

    public enum `Type` {
        case search(searchRequest: SearchRequest)
        case lookup(qualifiedID: WireDataModel.QualifiedID)
    }

    /// A closure which modifies the passed search result in order to unite the existing and the newly found results.
    ///
    /// The closure is used because there are four different ways of aggregating search results:
    /// - union(withLocalResult:)
    /// - union(withBotsResult:)
    /// - union(withDirectoryResult:)
    /// - union(prependingDirectory:)
    typealias SearchResultAggregator = (inout SearchResult) -> Void

    private enum Status {
        case pending
        case started(taskGroup: TaskGroup<SearchTask.SearchResultAggregator>)
    }

    init(
        type: Type,
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        searchUsersCache: SearchUsersCache?,
        apiVersion: WireTransport.APIVersion?,
        searchAPI: some SearchAPI,
        teamsAPI: some TeamsAPI,
        usersAPI: some UsersAPI
    ) {
        self.type = type
        self.transportSession = transportSession
        self.contextProvider = contextProvider
        self.searchUsersCache = searchUsersCache
        self.apiVersion = apiVersion
        self.searchAPI = searchAPI
        self.teamsAPI = teamsAPI
        self.usersAPI = usersAPI
    }

    /// Cancel a previously started task
    public func cancel() {
        guard case let .started(taskGroup) = status else { return }
        taskGroup.cancelAll()
    }

    /// Start the search task. Errors will be logged only.
    public func start() async -> SearchResult {
        guard case .pending = status else {
            assertionFailure()
            return SearchResult()
        }

        return await withTaskGroup(
            of: SearchResultAggregator.self,
            returning: SearchResult.self
        ) { @MainActor taskGroup in

            status = .started(taskGroup: taskGroup)

            // search bots
            taskGroup.addTask {
                do {
                    return try await self.performRemoteSearchForBots()
                } catch {
                    let errorType = Swift.type(of: error)
                    WireLogger.search.error("failed to search for bots: \(String(describing: errorType))")
                    return { _ in }
                }
            }

            // search People or groups
            taskGroup.addTask {
                await self.performLocalLookup()
            }
            taskGroup.addTask {
                await self.performLocalSearch()
            }

            // v1
            taskGroup.addTask {
                await self.performRemoteSearchForTeamUser()
            }

            // v2+
            taskGroup.addTask {
                do {
                    return try await self.performRemoteSearch()
                } catch {
                    let errorType = Swift.type(of: error)
                    WireLogger.search.error("failed to perform remote search: \(String(describing: errorType))")
                    return { _ in }
                }
            }
            taskGroup.addTask {
                do {
                    return try await self.performUserLookup()
                } catch {
                    let errorType = Swift.type(of: error)
                    WireLogger.search.error("failed to perform user lookup: \(String(describing: errorType))")
                    return { _ in }
                }
            }
            taskGroup.addTask {
                do {
                    return try await self.listAllAppsAndCollaboratorApps()
                } catch {
                    let errorType = Swift.type(of: error)
                    WireLogger.search
                        .error("failed to list all apps and collaborators: \(String(describing: errorType))")
                    return { _ in }
                }
            }

            var result = SearchResult()
            while let aggregator = await taskGroup.next() {
                aggregator(&result)
            }

            // add to search users cache
            let searchUserObserverCenter = self.contextProvider.viewContext.searchUserObserverCenter
            result.directory.forEach(searchUserObserverCenter.addSearchUser)
            result.bots.compactMap { $0 as? ZMSearchUser }.forEach(searchUserObserverCenter.addSearchUser)

            return result
        }
    }

    // MARK: -

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
                matchingQuery: "", // no query for lookup
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
        let (connectedUserIDs, teamMemberIDs, appIDs, conversationIDs) = await searchContext.perform { [self] in

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
            let apps = request.searchOptions.contains(.apps) ? apps(
                in: team,
                matching: request.normalizedQuery
            ) : []

            let conversations = request.searchOptions.contains(.conversations) ? conversations(
                matchingQuery: request.query,
                selfUser: selfUser,
                in: searchContext
            ) : []

            return (
                connectedUsers.map(\.objectID),
                teamMembers.map(\.objectID),
                apps.map(\.objectID),
                conversations.map(\.objectID)
            )

        }

        let viewContext = contextProvider.viewContext
        return await viewContext.perform { [self] in

            let copiedConversations = conversationIDs
                .compactMap { viewContext.object(with: $0) as? ZMConversation }
            let copiedConnectedUsers = connectedUserIDs
                .compactMap { viewContext.object(with: $0) as? ZMUser }
            let copiedApps = appIDs
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

            let copiedTeamMembers = teamMemberIDs.compactMap {
                contextProvider.viewContext.object(with: $0) as? Member
            }
            let searchTeamMembers = copiedTeamMembers
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
                conversations: copiedConversations,
                apps: copiedApps,
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
        var partialResult = team?.members(
            matchingQuery: query,
            filteredBy: .regular
        ) ?? []

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

    private func apps(
        in team: WireDataModel.Team?,
        matching query: String
    ) -> [ZMUser] {
        team?.members(
            matchingQuery: query,
            filteredBy: .app
        ).compactMap(\.user) ?? []
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

    // MARK: -

    func performUserLookup() async throws -> SearchResultAggregator {
        guard case var .lookup(qualifiedID) = type else {
            return { _ in }
        }

        let result = try await usersAPI.getUser(for: UserID(qualifiedID))
        qualifiedID = .init(uuid: result.id.id, domain: result.id.domain)

        let viewContext = contextProvider.viewContext
        return await viewContext.perform { [searchUsersCache] in
            let localUser = ZMUser.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: viewContext)

            let searchUser: ZMSearchUser
            if let cachedSearchUser = searchUsersCache?.object(forKey: qualifiedID.uuid as NSUUID) {
                cachedSearchUser.user = localUser
                searchUser = cachedSearchUser
            } else {
                searchUser = ZMSearchUser(
                    viewContext: viewContext,
                    user: result,
                    localUser: localUser,
                    searchUsersCache: searchUsersCache
                )
            }

            guard searchUser.user == nil || searchUser.user?.isTeamMember == false else {
                return { _ in }
            }

            // The directory/users endpoint returns the profile picture asset keys; without this the
            // restored SearchUserImageStrategy has no asset keys to fetch and the picture stays empty.
            if let assetKeys = SearchUserAssetKeys(result.assets) {
                searchUser.assetKeys = assetKeys
            }

            let partialResult = SearchResult(
                context: viewContext,
                contacts: [],
                teamMembers: [],
                directory: [searchUser],
                conversations: [],
                apps: [],
                bots: [],
                searchUsersCache: searchUsersCache
            )
            return { $0 = $0.union(withDirectoryResult: partialResult) }
        }

    }

    /// If no search query is provided we cannot use the search API.
    /// This func basically serves two purposes:
    /// - Apps added to the team don't trigger events, so this allows apps being added right now (while the iOS client
    /// is running) to be displayed in the search results.
    /// - In large teams apps might not be discovered without this code (2000 members cap).
    private func listAllAppsAndCollaboratorApps() async throws -> SearchResultAggregator {
        guard
            let apiVersion,
            apiVersion >= .v10, // collaborators: v10, apps: v15
            case let .search(searchRequest) = type,
            searchRequest.query.string.isEmpty,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.apps)
        else { return { _ in } }

        let searchContext = contextProvider.newBackgroundContext()
        let (teamID, selfUserDomain) = await searchContext.perform {
            let selfUser = ZMUser.selfUser(in: searchContext)
            let teamID = selfUser.team?.remoteIdentifier
            let domain = selfUser.domain ?? ""
            return (teamID, domain)
        }
        guard let teamID else { return { _ in } }

        let apps = if apiVersion >= .v15 {
            try await teamsAPI.getApps(for: teamID)
        } else { [] as [User] }

        try Task.checkCancellation()

        var collaboratorIDs = [UserID]()
        do {
            let appIDs = Set(apps.map(\.id.id))
            collaboratorIDs = try await teamsAPI.getCollaborators(for: teamID)
                .filter { collaboratorInfo in
                    !appIDs.contains(collaboratorInfo.userID)
                }
                .map { collaboratorInfo in
                    WireFoundation.QualifiedID(
                        id: collaboratorInfo.userID,
                        domain: selfUserDomain
                    )
                }
        } catch let error as FailureResponse {
            // at the time of writing this code there was a bug which forbid team members (except admins and owners) to
            // browse/fetch collaborators: https://github.com/wireapp/wire-server/pull/5239 WPB-25521
            if error.code == 403, error.label == "insufficient-permissions" {
                WireLogger.network.warn(
                    "Swallowing 403 error when getting collaborators, assuming it is bug WPB-25521",
                    attributes: .safePublic
                )
            } else {
                throw error
            }
        }

        try Task.checkCancellation()

        let collaborators = try await usersAPI.getUsers(userIDs: collaboratorIDs)
        if !collaborators.failed.isEmpty {
            WireLogger.network.warn("at least one collaborator's info couldn't be fetched", attributes: .safePublic)
        }

        try Task.checkCancellation()

        let viewContext = contextProvider.viewContext
        let searchUsers = await viewContext.perform { [searchUsersCache] in
            var searchUsers = [ZMSearchUser]()
            for app in apps + collaborators.found {
                guard app.type == .app else { continue }
                let localUser = ZMUser.fetch(with: app.id.id, domain: app.id.domain, in: viewContext)
                let searchUser: ZMSearchUser
                if let cachedSearchUser = searchUsersCache?.object(forKey: app.id.id as NSUUID) {
                    cachedSearchUser.user = localUser
                    searchUser = cachedSearchUser
                } else {
                    searchUser = ZMSearchUser(
                        viewContext: viewContext,
                        user: app,
                        localUser: localUser,
                        searchUsersCache: searchUsersCache
                    )
                }
                searchUsers += [searchUser]
            }
            return searchUsers
        }
        let partialResult = SearchResult(
            context: viewContext,
            contacts: [],
            teamMembers: [],
            directory: [],
            conversations: [],
            apps: searchUsers,
            bots: [],
            searchUsersCache: searchUsersCache
        )

        return { $0 = $0.union(withAppsResult: partialResult) }
    }

    // MARK: -

    func performRemoteSearch() async throws -> SearchResultAggregator {
        guard
            let apiVersion,
            apiVersion >= .v1,
            case let .search(searchRequest) = type,
            !searchRequest.query.string.isEmpty, // backend won't return anything for empty queries
            !searchRequest.searchOptions.contains(.localResultsOnly),
            !searchRequest.searchOptions.isDisjoint(with: [.directory, .teamMembers, .federated, .apps])
        else {
            return { _ in }
        }

        let queryLowercased = searchRequest.query.string.lowercased()
        let searchDomain = searchRequest.searchDomain ?? ""
        let searchForApps = searchRequest.searchOptions.contains(.apps)
        let contacts = try await searchAPI.searchContacts(
            query: queryLowercased,
            domain: searchDomain,
            type: searchForApps ? .app : .regular
        ).documents

        let filteredContacts = contacts.filter { contact in
            !searchRequest.query.isHandleQuery ||
                contact.name.hasPrefix("@") ||
                (contact.handle?.lowercased().contains(queryLowercased) ?? false)
        }

        try Task.checkCancellation()

        let viewContext = contextProvider.viewContext
        let searchUsers = await viewContext.perform { [searchUsersCache] in
            filteredContacts.compactMap { filteredContact in
                guard let id = filteredContact.id else { return ZMSearchUser?.none }

                let domain = filteredContact.qualifiedID?.domain
                let localUser = ZMUser.fetch(with: id, domain: domain, in: viewContext)

                if let cachedSearchUser = searchUsersCache?.object(forKey: id as NSUUID) {
                    cachedSearchUser.user = localUser
                    return cachedSearchUser

                } else {
                    let accentColorRawValue = filteredContact.accentID.flatMap(Int16.init(exactly:))
                    let accentColor = accentColorRawValue.flatMap(AccentColor.init(rawValue:))
                    return ZMSearchUser(
                        viewContext: viewContext,
                        name: filteredContact.name,
                        handle: filteredContact.handle,
                        accentColor: accentColor.map(ZMAccentColor.from(accentColor:)),
                        remoteIdentifier: filteredContact.id,
                        domain: domain,
                        teamIdentifier: filteredContact.team,
                        providerIdentifier: nil,
                        user: localUser,
                        searchUsersCache: searchUsersCache,
                        type: .init(filteredContact.type)
                    )
                }
            }
        }

        try Task.checkCancellation()

        // The contacts-search endpoint omits profile asset keys; enrich directory hits via the
        // users endpoint so the restored SearchUserImageStrategy can download the pictures.
        await enrichAssetKeys(for: searchUsers, on: viewContext)

        try Task.checkCancellation()

        let searchOptions = searchRequest.searchOptions
        let includeActiveTeamMembers = searchOptions.contains(.teamMembers) &&
            searchOptions.isDisjoint(with: .excludeNonActiveTeamMembers)
        let partialResult = await viewContext.perform { [searchUsersCache] in
            SearchResult(
                context: viewContext,
                contacts: [],
                teamMembers: includeActiveTeamMembers ? searchUsers.filter(\.isTeamMember) : [],
                directory: searchUsers.filter { !$0.isConnected && !$0.isTeamMember },
                conversations: [],
                apps: searchUsers.filter(\.isApp),
                bots: [],
                searchUsersCache: searchUsersCache
            )
        }

        try Task.checkCancellation()

        if searchRequest.searchOptions.contains(.teamMembers) {
            return try await performTeamMembershipLookup(on: partialResult, searchRequest: searchRequest)
        } else if searchForApps {
            return { $0 = $0.union(withAppsResult: partialResult) }
        } else {
            return { $0 = $0.union(withDirectoryResult: partialResult) }
        }
    }

    private func performTeamMembershipLookup(
        on searchResult: SearchResult,
        searchRequest: SearchRequest
    ) async throws -> SearchResultAggregator {

        let viewContext = contextProvider.viewContext
        let (teamMembersIDs, teamID) = await viewContext.perform { [viewContext] in
            let teamMembersIDs = searchResult.teamMembers.compactMap(\.remoteIdentifier)
            let teamID = ZMUser.selfUser(in: viewContext).team?.remoteIdentifier
            return (teamMembersIDs, teamID)
        }

        guard
            let teamID,
            !teamMembersIDs.isEmpty
        else {
            return { $0 = $0.union(withDirectoryResult: searchResult) }
        }

        let remoteTeamMembers = try await teamsAPI.getTeamMembers(of: teamID, for: teamMembersIDs)

        return await viewContext.perform { [contextProvider] in
            var searchResult = searchResult
            searchResult.extendWithMembership(remoteTeamMembers: remoteTeamMembers)
            searchResult.filterBy(
                searchOptions: searchRequest.searchOptions,
                query: searchRequest.query.string,
                contextProvider: contextProvider
            )
            return { $0 = $0.union(withDirectoryResult: searchResult) }
        }

    }

    // MARK: -

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

    // This is specific to API v1, so it's most likely already dead code.
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

    // MARK: -

    func performRemoteSearchForBots() async throws -> SearchResultAggregator {

        let searchContext = contextProvider.newBackgroundContext()
        let teamIdentifier = await searchContext.perform {
            ZMUser.selfUser(in: searchContext).team?.remoteIdentifier
        }

        guard
            let teamIdentifier,
            case let .search(searchRequest) = type,
            !searchRequest.searchOptions.contains(.localResultsOnly),
            searchRequest.searchOptions.contains(.bots)
        else {
            return { _ in }
        }

        let viewContext = contextProvider.viewContext
        var partialResult = SearchResult(
            context: viewContext,
            contacts: [],
            teamMembers: [],
            directory: [],
            conversations: [],
            apps: [],
            bots: [],
            searchUsersCache: searchUsersCache
        )

        let prefix = searchRequest.query.string.trimmingCharacters(in: .whitespacesAndNewlines)
        for try await profiles in try teamsAPI.getWhitelistedBots(for: teamIdentifier, with: prefix) {
            await viewContext.perform { [searchUsersCache] in
                partialResult.bots += profiles.compactMap { profile in

                    let localUser = ZMUser.fetch(
                        with: profile.id,
                        domain: profile.qualifiedID?.domain,
                        in: viewContext
                    )

                    if let searchUser = searchUsersCache?.object(forKey: profile.id as NSUUID) {
                        searchUser.user = localUser
                        return searchUser
                    } else {
                        let accentColorRawValue = profile.accentID.flatMap(Int16.init(exactly:))
                        let accentColor = accentColorRawValue.flatMap(AccentColor.init(rawValue:))
                        let searchUser = ZMSearchUser(
                            viewContext: viewContext,
                            name: profile.name,
                            handle: profile.handle,
                            accentColor: accentColor.map(ZMAccentColor.from(accentColor:)),
                            remoteIdentifier: profile.id,
                            domain: profile.qualifiedID?.domain,
                            teamIdentifier: profile.teamID,
                            providerIdentifier: profile.provider.transportString(),
                            user: localUser,
                            searchUsersCache: searchUsersCache,
                            type: localUser?.type,
                            summary: profile.summary,
                            isDeleted: profile.isDeleted
                        )
                        searchUser.assetKeys = SearchUserAssetKeys(profile.assets)
                        return searchUser
                    }
                }
            }
        }

        return { $0 = $0.union(withBotsResult: partialResult) }
    }

    // MARK: -

    /// Fetches profile-picture asset keys for search hits that don't have them yet (i.e. directory
    /// hits without a backing `ZMUser`). The contacts-search endpoint omits these keys, so without
    /// this step `SearchUserImageStrategy` has nothing to download and the profile picture stays
    /// empty.
    private func enrichAssetKeys(
        for searchUsers: [ZMSearchUser],
        on viewContext: NSManagedObjectContext
    ) async {
        let userIDsToFetch: [UserID] = await viewContext.perform {
            searchUsers.compactMap { searchUser -> UserID? in
                guard searchUser.assetKeys == nil,
                      searchUser.user == nil,
                      let uuid = searchUser.remoteIdentifier,
                      let domain = searchUser.domain,
                      !domain.isEmpty
                else { return nil }
                return UserID(id: uuid, domain: domain)
            }
        }

        guard !userIDsToFetch.isEmpty else { return }

        let usersByID: [UUID: User]
        do {
            let userList = try await usersAPI.getUsers(userIDs: userIDsToFetch)
            usersByID = Dictionary(
                userList.found.map { ($0.id.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
        } catch {
            WireLogger.search.warn(
                "failed to enrich search users with asset keys: \(String(describing: error))"
            )
            return
        }

        await viewContext.perform {
            for searchUser in searchUsers where searchUser.assetKeys == nil {
                guard let uuid = searchUser.remoteIdentifier,
                      let user = usersByID[uuid],
                      let assetKeys = SearchUserAssetKeys(user.assets)
                else { continue }
                searchUser.assetKeys = assetKeys
            }
        }
    }

}

private extension SearchResult {

    mutating func extendWithMembership(remoteTeamMembers: [TeamMember]) {
        remoteTeamMembers.forEach { remoteTeamMember in
            let searchUser = teamMembers.first(where: { $0.remoteIdentifier == remoteTeamMember.userID })
            let permissions = remoteTeamMember.permissions.flatMap { Permissions(rawValue: $0.selfPermissions) }
            searchUser?.updateWithTeamMembership(permissions: permissions, createdBy: remoteTeamMember.creatorID)
        }
    }

}

private extension SearchUserAssetKeys {

    init?(_ userAssets: [UserAsset]) {
        guard !userAssets.isEmpty else { return nil }

        var preview = String?.none
        var complete = String?.none

        for userAsset in userAssets {
            guard userAsset.type == .image else { continue }

            switch userAsset.size {
            case .preview:
                preview = userAsset.key
            case .complete:
                complete = userAsset.key
            }
        }

        guard preview != nil || complete != nil else { return nil }

        self.init(
            preview: preview,
            complete: complete
        )

    }

}

private extension TypeOfUser {

    init(_ type: WireNetwork.UserType) {
        switch type {
        case .regular:
            self = .regular
        case .app:
            self = .app
        case .bot:
            self = .bot
        }
    }

}

private extension ZMSearchUser {

    convenience init(
        viewContext: NSManagedObjectContext,
        user: WireNetwork.User,
        localUser: ZMUser?,
        searchUsersCache: SearchUsersCache?
    ) {
        let accentColor = Int16(exactly: user.accentID).flatMap(AccentColor.init(rawValue:))
        let qualifiedID = WireDataModel.QualifiedID(uuid: user.id.id, domain: user.id.domain)
        self.init(
            viewContext: viewContext,
            name: user.name,
            handle: user.handle,
            accentColor: accentColor.map(ZMAccentColor.from(accentColor:)),
            remoteIdentifier: qualifiedID.uuid,
            domain: qualifiedID.domain,
            teamIdentifier: user.teamID,
            providerIdentifier: user.service?.provider.transportString(),
            user: localUser,
            searchUsersCache: searchUsersCache,
            type: user.type.map(TypeOfUser.init) ?? localUser?.type,
            summary: localUser?.appInfo?.appDescription,
            isDeleted: user.deleted ?? false
        )
    }

}
