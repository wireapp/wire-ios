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

import Foundation
import CoreData
import WireTransport

public extension MockTransportSession {
    private func selfUserPartOfTeam(_ team: MockTeam) -> Bool {
        return team.contains(user: selfUser)
    }
    
    private func ascendingCreationDate(first: MockTeam, second: MockTeam) -> Bool {
        return first.createdAt < second.createdAt
    }
    
    @objc(pushEventsForTeamsWithInserted:updated:deleted:shouldSendEventsToSelfUser:)
    public func pushEventsForTeams(inserted: Set<NSManagedObject>, updated: Set<NSManagedObject>, deleted: Set<NSManagedObject>, shouldSendEventsToSelfUser: Bool) -> [MockPushEvent] {
        guard shouldSendEventsToSelfUser else { return [] }
        
        let updatedEvents =  updated
            .flatMap { $0 as? MockTeam }
            .sorted(by: ascendingCreationDate)
            .flatMap{ self.pushEventForUpdatedTeam(team: $0, insertedObjects: inserted) }
        
        let deletedEvents = deleted
            .flatMap { $0 as? MockTeam }
            .sorted(by: ascendingCreationDate)
            .filter(selfUserPartOfTeam)
            .map(MockTeamEvent.deleted)
            .map { MockPushEvent(with: $0.payload, uuid: UUID.create(), isTransient: false) }
        
        return updatedEvents + deletedEvents
    }
    
    private func pushEventForUpdatedTeam(team: MockTeam, insertedObjects: Set<NSManagedObject>) -> [MockPushEvent] {
        var allEvents = [MockPushEvent]()
        let changedValues = team.changedValues()
        if let teamUpdateEvent = MockTeamEvent.updated(team: team , changedValues: changedValues) {
            allEvents.append(MockPushEvent(with: teamUpdateEvent.payload, uuid: UUID.create(), isTransient: false) )
        }
        
        let membersEvents = MockTeamMemberEvent.createIfNeeded(team: team, changedValues: team.changedValues(), selfUser: selfUser)
        let membersPushEvents = membersEvents.flatMap{ $0 }.map { MockPushEvent(with: $0.payload, uuid: UUID.create(), isTransient: false) }
        allEvents.append(contentsOf: membersPushEvents)

        let conversationsEvents = MockTeamConversationEvent.createIfNeeded(team: team, changedValues: team.changedValues())
        let conversationsPushEvents = conversationsEvents.flatMap{ $0 }.map { MockPushEvent(with: $0.payload, uuid: UUID.create(), isTransient: false) }
        allEvents.append(contentsOf: conversationsPushEvents)
        
        return allEvents
    }
}


extension MockTransportSession : UnauthenticatedTransportSessionProtocol {

    public func enqueueRequest(withGenerator generator: () -> ZMTransportRequest?) -> EnqueueResult {
        let result = attemptToEnqueueSyncRequest(generator: generator)
        
        if !result.didHaveLessRequestThanMax {
            return .maximumNumberOfRequests
        }
        else if !result.didGenerateNonNullRequest {
            return .nilRequest
        }
        else {
            return .success
        }
    }
    
}


// MARK: - Email activation
public extension MockTransportSession {
    @objc public var emailActivationCode: String {
        return "123456"
    }
}
