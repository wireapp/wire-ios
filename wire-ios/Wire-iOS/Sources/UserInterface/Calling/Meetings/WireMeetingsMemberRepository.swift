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
import WireCallingDomain
import WireDataModel
import WireLogging
import WireNetwork
import WireSyncEngine

struct WireMeetingsMemberRepository: MeetingMemberRepositoryProtocol, @unchecked Sendable {

    enum Failure: Error {
        case sourceUnavailable
        case invalidMember
    }

    let userSession: any UserSession
    let conversationsAPI: any ConversationsAPI
    let usersAPI: any UsersAPI

    @MainActor
    func search(query: String) async throws -> [MeetingMember] {
        guard let searchUsersUseCase = userSession.makeSearchUsersUseCase() else {
            WireLogger.ui.error(
                "userSession.makeSearchUsersUseCase() returned nil, can't search for meeting members",
                attributes: .safePublic
            )
            return []
        }

        let result = await searchUsersUseCase.invoke(
            query: query,
            options: [.teamMembers], // in large teams find team members which are not yet known to us
            messageProtocol: .mls // meetings are always mls
        )
        return result.teamMembers.compactMap { result in
            guard let qualifiedID = result.qualifiedID(localDomain: nil) else { return MeetingMember?.none }
            return MeetingMember(
                qualifiedID: .init(qualifiedID),
                name: result.name ?? "",
                handle: result.handle ?? "",
                isSelfUser: false,
                initials: "",
                accentColor: .default,
                avatarImageData: nil
            )
        }.sorted { $0.name < $1.name }
    }

    func searchGroups(query: String) async throws -> [MeetingGroup] {
        let context = userSession.contextProvider.viewContext
        return try await context.perform {
            let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let predicate: NSPredicate = if query.isEmpty {
                NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(
                        format: "%K == %d",
                        ZMConversationConversationTypeKey,
                        ZMConversationType.group.rawValue
                    ),
                    NSCompoundPredicate(notPredicateWithSubpredicate: ZMConversation
                        .predicateForTeamOneToOneConversation())
                ])
            } else {
                ZMConversation.predicate(
                    forSearchQuery: query,
                    selfUser: ZMUser.selfUser(in: context)
                )
            }
            let request = ZMConversation.sortedFetchRequest(with: predicate)
            let conversations = try context.fetch(request) as? [ZMConversation] ?? []

            return conversations.compactMap { conversation -> MeetingGroup? in
                guard
                    conversation.conversationType == .group,
                    conversation.isSelfAnActiveMember,
                    !conversation.isDeletedRemotely,
                    !conversation.isMeeting,
                    let id = conversation.qualifiedID
                else { return nil }

                return MeetingGroup(
                    id: .init(id: id.uuid, domain: id.domain),
                    name: conversation.displayNameWithFallback,
                    isChannel: conversation.isChannel
                )
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    func members(in groupID: WireCallingDomain.QualifiedID) async throws -> [MeetingMember] {
        let response = try await conversationsAPI.getConversations(for: [groupID])
        guard
            !response.notFound.contains(groupID),
            !response.failed.contains(groupID),
            let conversation = response.found.first(where: { $0.qualifiedID == groupID }),
            conversation.type == .group,
            conversation.groupType != .meeting,
            let members = conversation.members,
            let sourceSelf = members.selfMember,
            let sourceSelfID = sourceSelf.qualifiedID
        else { throw Failure.sourceUnavailable }

        // Use the response IDs. A conversation pull does not remove stale local members.
        var seen = Set<WireCallingDomain.QualifiedID>()
        let memberIDs = try ([sourceSelf] + members.others).compactMap { member in
            guard let id = member.qualifiedID, !id.domain.isEmpty else { throw Failure.invalidMember }
            return seen.insert(id).inserted ? id : nil
        }

        let profiles = try await usersAPI.getUsers(userIDs: memberIDs)
        guard
            profiles.failed.isEmpty,
            Set(profiles.found.map(\.id)) == Set(memberIDs),
            let teamID = profiles.found.first(where: { $0.id == sourceSelfID })?.teamID
        else { throw Failure.invalidMember }

        let eligibleProfiles = Dictionary(
            profiles.found.filter {
                $0.teamID == teamID && $0.id.domain == sourceSelfID.domain
            }.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let context = userSession.contextProvider.syncContext
        return try await context.perform {
            guard
                let selfID = ZMUser.selfUser(in: context).qualifiedID,
                sourceSelfID == .init(id: selfID.uuid, domain: selfID.domain)
            else { throw Failure.sourceUnavailable }

            let result = memberIDs.compactMap { id -> MeetingMember? in
                guard let profile = eligibleProfiles[id] else { return nil }
                // Meeting edits resolve selected people from the local user store.
                let user = ZMUser.fetchOrCreate(with: id.id, domain: id.domain, in: context)
                user.name = profile.name
                user.handle = profile.handle
                let name = user.name ?? ""
                return MeetingMember(
                    qualifiedID: id,
                    name: name.isEmpty ? L10n.Localizable.Profile.Details.Title.unavailable : name,
                    handle: user.handle ?? "",
                    isSelfUser: id == sourceSelfID,
                    initials: user.initials ?? "",
                    accentColor: .default,
                    avatarImageData: nil
                )
            }
            try context.save()
            return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

}
