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

public struct SearchResult {

    /// The managed object context the Core Data objects in the search result must be accessed on.

    public let context: NSManagedObjectContext

    /// Users already connected to.

    public var contacts: [ZMSearchUser]

    /// Users from the team.

    public var teamMembers: [ZMSearchUser]

    /// Non-connected users.

    public var directory: [ZMSearchUser]

    /// Group conversations.

    public var conversations: [ZMConversation]

    public var apps: [any UserType]

    /// Team collaborators (resolved from `/teams/:tid/collaborators`) whose profile is not app-typed,
    /// i.e. human users with team permissions who aren't full team members. These should be surfaced
    /// like regular contacts, never through the apps-specific UI.

    public var collaborators: [ZMSearchUser] = []

    public var bots: [any UserType]

    /// Cache for search users.

    let searchUsersCache: SearchUsersCache?

}

extension SearchResult {

    init() {
        self.context = .init(concurrencyType: .privateQueueConcurrencyType)
        self.contacts = []
        self.teamMembers = []
        self.directory = []
        self.conversations = []
        self.apps = []
        self.collaborators = []
        self.bots = []
        self.searchUsersCache = nil
    }

    public init?(
        payload: [AnyHashable: Any],
        query: SearchRequest.Query,
        searchOptions: SearchOptions,
        contextProvider: ContextProvider,
        searchUsersCache: SearchUsersCache?
    ) {
        guard let documents = payload["documents"] as? [[String: Any]] else {
            return nil
        }

        let filteredDocuments = documents.filter { document -> Bool in
            let name = document["name"] as? String
            let handle = document["handle"] as? String
            return !query.isHandleQuery || name?.hasPrefix("@") ?? true || handle?
                .contains(query.string.lowercased()) ?? false
        }

        let searchUsers = ZMSearchUser.searchUsers(
            from: filteredDocuments,
            contextProvider: contextProvider,
            searchUsersCache: searchUsersCache
        )

        self.context = contextProvider.viewContext
        self.contacts = []
        self.directory = searchUsers.filter { !$0.isConnected && !$0.isTeamMember }
        self.conversations = []
        self.apps = []
        self.collaborators = []
        self.bots = []
        self.searchUsersCache = searchUsersCache

        if searchOptions.contains(.teamMembers),
           searchOptions.isDisjoint(with: .excludeNonActiveTeamMembers) {
            self.teamMembers = searchUsers.filter(\.isTeamMember)
        } else {
            self.teamMembers = []
        }
    }

    mutating func extendWithMembershipPayload(payload: MembershipListPayload) {
        payload.members.forEach { membershipPayload in
            let searchUser = teamMembers.first(where: { $0.remoteIdentifier == membershipPayload.userID })
            let permissions = membershipPayload.permissions.flatMap { Permissions(rawValue: $0.selfPermissions) }
            searchUser?.updateWithTeamMembership(permissions: permissions, createdBy: membershipPayload.createdBy)
        }
    }

    mutating func filterBy(
        searchOptions: SearchOptions,
        query: String,
        contextProvider: ContextProvider
    ) {
        guard searchOptions.contains(.excludeNonActivePartners) else { return }

        let selfUser = ZMUser.selfUser(in: contextProvider.viewContext)
        let isHandleQuery = query.hasPrefix("@")
        let queryWithoutAtSymbol = (isHandleQuery ? String(query[query.index(after: query.startIndex)...]) : query)
            .lowercased()

        teamMembers = teamMembers.filter {
            $0.teamRole != .partner ||
                $0.teamCreatedBy == selfUser.remoteIdentifier ||
                isHandleQuery && $0.handle == queryWithoutAtSymbol
        }
    }

    func copy(on context: NSManagedObjectContext) -> SearchResult {

        let copiedConversations = conversations.compactMap {
            context.object(with: $0.objectID) as? ZMConversation
        }

        return SearchResult(
            context: context,
            contacts: contacts,
            teamMembers: teamMembers,
            directory: directory,
            conversations: copiedConversations,
            apps: apps,
            collaborators: collaborators,
            bots: bots,
            searchUsersCache: searchUsersCache
        )
    }

    func union(withLocalResult result: SearchResult) -> SearchResult {
        SearchResult(
            context: context,
            contacts: result.contacts,
            teamMembers: result.teamMembers,
            directory: directory,
            conversations: result.conversations,
            apps: result.apps,
            collaborators: collaborators,
            bots: bots,
            searchUsersCache: searchUsersCache
        )
    }

    func union(withAppsResult result: SearchResult) -> SearchResult {
        SearchResult(
            context: context,
            contacts: contacts,
            teamMembers: teamMembers,
            directory: directory,
            conversations: conversations,
            apps: apps + result.apps.filter { newApp in
                !apps.contains { existingApp in
                    newApp.remoteIdentifier == existingApp.remoteIdentifier
                }
            },
            collaborators: collaborators,
            bots: bots,
            searchUsersCache: searchUsersCache
        )
    }

    /// Merges in newly resolved human collaborators (non-app team collaborators), deduplicating by
    /// `remoteIdentifier` against collaborators, contacts and team members already present in `self`.
    func union(withCollaboratorsResult result: SearchResult) -> SearchResult {
        let existingUsers = contacts + teamMembers + collaborators
        return SearchResult(
            context: context,
            contacts: contacts,
            teamMembers: teamMembers,
            directory: directory,
            conversations: conversations,
            apps: apps,
            collaborators: collaborators + result.collaborators.filter { newCollaborator in
                !existingUsers.contains { existingUser in
                    newCollaborator.remoteIdentifier == existingUser.remoteIdentifier
                }
            },
            bots: bots,
            searchUsersCache: searchUsersCache
        )
    }

    func union(withBotsResult result: SearchResult) -> SearchResult {
        SearchResult(
            context: context,
            contacts: contacts,
            teamMembers: teamMembers,
            directory: directory,
            conversations: conversations,
            apps: apps,
            collaborators: collaborators,
            bots: bots + result.bots,
            searchUsersCache: searchUsersCache
        )
    }

    func union(withDirectoryResult result: SearchResult) -> SearchResult {
        SearchResult(
            context: context,
            contacts: contacts,
            teamMembers: Array(Set(teamMembers).union(result.teamMembers)),
            directory: result.directory,
            conversations: conversations,
            apps: apps,
            collaborators: collaborators,
            bots: bots,
            searchUsersCache: searchUsersCache
        )
    }

    func union(prependingDirectory result: SearchResult) -> SearchResult {
        SearchResult(
            context: context,
            contacts: contacts,
            teamMembers: teamMembers,
            directory: result.directory + directory,
            conversations: conversations,
            apps: apps,
            collaborators: collaborators,
            bots: bots,
            searchUsersCache: searchUsersCache
        )
    }

}
