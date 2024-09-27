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

/// Downloads all team members during the slow sync.

public final class TeamMembersDownloadRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder {
    // MARK: Lifecycle

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

        configuration = [.allowsRequestsDuringSlowSync]
        self.sync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
    }

    // MARK: Public

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard syncStatus.currentSyncPhase == .fetchingTeamMembers else { return nil }

        sync.readyForNextRequestIfNotBusy()

        return sync.nextRequest(for: apiVersion)
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
        for membershipPayload in payload.members {
            membershipPayload.createOrUpdateMember(team: team, in: managedObjectContext)
        }

        completeSyncPhase()
    }

    // MARK: Internal

    let syncStatus: SyncStatus
    var sync: ZMSingleRequestSync!

    func failSyncPhase() {
        syncStatus.failCurrentSyncPhase(phase: .fetchingTeamMembers)
    }

    func completeSyncPhase() {
        syncStatus.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
    }
}
