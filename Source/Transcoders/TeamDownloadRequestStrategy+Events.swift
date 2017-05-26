//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


fileprivate  enum TeamEventPayloadKey: String {
    case team
    case data
    case user
    case conversation = "conv"

}

fileprivate extension ZMUpdateEvent {

    var teamId: UUID? {
        return(payload[TeamEventPayloadKey.team.rawValue] as? String).flatMap(UUID.init)
    }

    var dataPayload: [String: Any]? {
        return payload[TeamEventPayloadKey.data.rawValue] as? [String: Any]
    }
}


private let log = ZMSLog(tag: "Teams")



extension TeamDownloadRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        events.forEach(process)
    }

    private func process(_ event: ZMUpdateEvent) {
        switch event.type {
        case .teamCreate: createTeam(with: event)
        case .teamDelete: deleteTeam(with: event)
        case .teamUpdate: updateTeam(with : event)
        case .teamMemberJoin: processAddedMember(with: event)
        case .teamMemberLeave: processRemovedMember(with: event)
        case .teamConversationCreate: createTeamConversation(with: event)
        case .teamConversationDelete: deleteTeamConversation(with: event)
        // Note: "conversation-delete" is not handled yet, 
        // cf. disabled_testThatItDeletesALocalTeamConversationInWhichSelfIsAGuest in TeamDownloadRequestStrategy_EventsTests
        default: break
        }
    }

    private func createTeam(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId else { return }
        guard let team = Team.fetchOrCreate(with: identifier, create: true, in: managedObjectContext, created: nil) else { return }
        team.needsToBeUpdatedFromBackend = true
    }

    private func deleteTeam(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId else { return }
        guard let team = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }
        managedObjectContext.delete(team)
    }

    private func updateTeam(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        guard let existingTeam = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }
        existingTeam.update(with: data)
    }

    private func processAddedMember(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        var created = false
        let fetchedTeam = withUnsafeMutablePointer(to: &created) {
             Team.fetchOrCreate(with: identifier, create: true, in: managedObjectContext, created: $0)
        }
        guard let team = fetchedTeam else { return }
        // In case we just created this team locally, we want to ensure that we refetch all of its
        // metadata, as well as all member permissions.
        team.needsToBeUpdatedFromBackend = created
        guard let addedUserId = (data[TeamEventPayloadKey.user.rawValue] as? String).flatMap(UUID.init) else { return }
        guard let user = ZMUser(remoteID: addedUserId, createIfNeeded: true, in: managedObjectContext) else { return }
        user.needsToBeUpdatedFromBackend = true
        // TODO: The event payload does not contain permissions (so far),
        // should we always refetch the team to ensure we refetch the members with their permissions?
        _ = Member.getOrCreateMember(for: user, in: team, context: managedObjectContext)
    }

    private func processRemovedMember(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        guard let team = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }
        guard let removedUserId = (data[TeamEventPayloadKey.user.rawValue] as? String).flatMap(UUID.init) else { return }
        guard let user = ZMUser(remoteID: removedUserId, createIfNeeded: false, in: managedObjectContext) else { return }
        if let member = user.membership(in: team) {
            managedObjectContext.delete(member)
            // TODO: Delete the team in case the member.user was the self user
        } else {
            log.error("Trying to delete non existent membership of \(user) in \(team)")
        }
    }

    private func createTeamConversation(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        guard let team = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }
        guard let conversationId = (data[TeamEventPayloadKey.conversation.rawValue] as? String).flatMap(UUID.init) else { return }
        let conversation = ZMConversation(remoteID: conversationId, createIfNeeded: true, in: managedObjectContext)
        conversation?.team = team
        conversation?.needsToBeUpdatedFromBackend = true
    }

    private func deleteTeamConversation(with event: ZMUpdateEvent) {
        guard let identifier = event.teamId, let data = event.dataPayload else { return }
        guard let team = Team.fetchOrCreate(with: identifier, create: false, in: managedObjectContext, created: nil) else { return }
        guard let conversationId = (data[TeamEventPayloadKey.conversation.rawValue] as? String).flatMap(UUID.init) else { return }
        guard let conversation = ZMConversation(remoteID: conversationId, createIfNeeded: false, in: managedObjectContext) else { return }
        if conversation.team == team {
            managedObjectContext.delete(conversation)
        } else {
            log.error("Specified conversation \(conversation) to delete not in specified team \(team)")
        }
    }
    
}
