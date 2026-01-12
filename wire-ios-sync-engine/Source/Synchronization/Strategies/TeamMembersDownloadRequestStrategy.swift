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

/// Downloads all team members during the slow sync and updating when processing events or when manually requested.

public final class TeamMembersDownloadRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder,
    ZMContextChangeTrackerSource, ZMDownstreamTranscoder {

    let syncStatus: SyncStatus
    private var slowSync: ZMSingleRequestSync!
    private var downstreamSync: ZMDownstreamObjectSync!

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncStatus: SyncStatus
    ) {

        self.syncStatus = syncStatus

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [.allowsRequestsWhileOnline, .allowsRequestsDuringSlowSync]
        self.downstreamSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: Team.entityName(),
            predicateForObjectsToDownload: Team.predicateForObjectsNeedingToBeUpdated,
            filter: nil,
            managedObjectContext: managedObjectContext
        )
        self.slowSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if syncStatus.currentSyncPhase == .fetchingTeamMembers {
            slowSync.readyForNextRequestIfNotBusy()
            return slowSync.nextRequest(for: apiVersion)
        } else {
            return downstreamSync.nextRequest(for: apiVersion)
        }
    }

    // MARK: - ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [downstreamSync]
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let teamID = ZMUser.selfUser(in: managedObjectContext).teamIdentifier else {
            completeSyncPhase() // Skip sync phase if user doesn't belong to a team
            return nil
        }

        let maxResults = 2000
        return ZMTransportRequest(
            getFromPath: "/teams/\(teamID.transportString())/members?maxResults=\(maxResults)",
            apiVersion: apiVersion.rawValue
        )
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard
            response.result == .success,
            let team = ZMUser.selfUser(in: managedObjectContext).team,
            let rawData = response.rawData,
            let payload = MembershipListPayload(rawData)
        else {
            failSyncPhase()
            return
        }

        // as per WPB-6485 we ignore the hasMore
        payload.members.forEach { membershipPayload in
            membershipPayload.createOrUpdateMember(team: team, in: managedObjectContext)
        }

        completeSyncPhase()
    }

    func failSyncPhase() {
        syncStatus.failCurrentSyncPhase(phase: .fetchingTeamMembers)
    }

    func completeSyncPhase() {
        syncStatus.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest! {
        guard let teamID = (object as? Team)?.remoteIdentifier else { fatalError() }

        let maxResults = 2000
        return ZMTransportRequest(
            getFromPath: "/teams/\(teamID.transportString())/members?maxResults=\(maxResults)",
            apiVersion: apiVersion.rawValue
        )
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard
            response.result == .success,
            let team = object as? Team,
            let rawData = response.rawData,
            let payload = MembershipListPayload(rawData)
        else {
            return
        }

        payload.members.forEach { membershipPayload in
            membershipPayload.createOrUpdateMember(team: team, in: managedObjectContext)
        }

        team.needsToRedownloadMembers = false
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // No op
    }
}

private extension Team {

    static var predicateForObjectsNeedingToBeUpdated: NSPredicate = .init(
        format: "%K == YES AND %K != NULL",
        #keyPath(Team.needsToRedownloadMembers),
        Team.remoteIdentifierDataKey()
    )

}
