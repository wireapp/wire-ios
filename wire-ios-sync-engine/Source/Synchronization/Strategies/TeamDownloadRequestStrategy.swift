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

import WireLogging

struct TeamListPayload: Decodable {
    let hasMore: Bool
    let teams: [TeamPayload]

    private enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case teams
    }
}

struct TeamPayload: Decodable {

    let identifier: UUID
    let name: String
    let creator: UUID
    let icon: String
    let iconKey: String?
    let splashScreen: String?

    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name
        case creator
        case icon
        case iconKey = "icon_key"
        case splashScreen = "splash_screen"
    }

}

extension TeamPayload {

    func createOrUpdateTeam(in managedObjectContext: NSManagedObjectContext) -> Team {
        let team = Team.fetchOrCreate(
            with: identifier,
            in: managedObjectContext
        )

        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        _ = Member.getOrUpdateMember(for: selfUser, in: team, context: managedObjectContext)

        updateTeam(team, in: managedObjectContext)

        return team
    }

    func updateTeam(_ team: Team, in managedObjectContext: NSManagedObjectContext) {
        team.name = name
        team.creator = ZMUser.fetchOrCreate(with: creator, domain: nil, in: managedObjectContext)
        team.pictureAssetId = icon
        team.pictureAssetKey = iconKey
    }

}

private extension Team {

    static var predicateForObjectsNeedingToBeUpdated: NSPredicate = .init(
        format: "%K == YES AND %K != NULL",
        #keyPath(Team.needsToBeUpdatedFromBackend),
        Team.remoteIdentifierDataKey()
    )

}

/// Responsible for downloading the team which the self user belongs to during the slow sync
/// and for updating it when processing events or when manually requested.

public final class TeamDownloadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource,
    ZMDownstreamTranscoder {

    private(set) var downstreamSync: ZMDownstreamObjectSync!

    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
    ) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        configuration = [.allowsRequestsWhileOnline]
        self.downstreamSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: Team.entityName(),
            predicateForObjectsToDownload: Team.predicateForObjectsNeedingToBeUpdated,
            filter: nil,
            managedObjectContext: managedObjectContext
        )
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        downstreamSync.nextRequest(for: apiVersion)
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [downstreamSync]
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest! {
        guard downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
              let team = object as? Team else { fatal("Wrong sync or object for: \(object.safeForLoggingDescription)") }
        return team.remoteIdentifier.map { TeamDownloadRequestFactory.getRequest(for: [$0], apiVersion: apiVersion) }
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard
            downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
            let team = object as? Team,
            let rawData = response.rawData,
            let teamPayload = TeamPayload(rawData) else { return }

        teamPayload.updateTeam(team, in: managedObjectContext)

        team.needsToBeUpdatedFromBackend = false
        team.needsToDownloadRoles = true
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
              let team = object as? Team else { return }

        managedObjectContext.delete(team)
    }
}

// MARK: - Event

private extension ZMUpdateEvent {

    var teamId: UUID? {
        (payload[TeamEventPayloadKey.team.rawValue] as? String).flatMap(UUID.init(transportString:))
    }

    var dataPayload: [String: Any]? {
        payload[TeamEventPayloadKey.data.rawValue] as? [String: Any]
    }
}

private  enum TeamEventPayloadKey: String {

    case team
    case data
    case user
    case conversation = "conv"

}

struct TeamUpdateEventPayload: Decodable {

    let name: String?
    let icon: String?
    let iconKey: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case icon
        case iconKey = "icon_key"
    }

}

extension TeamUpdateEventPayload {

    func updateTeam(_ team: Team, in managedObjectContext: NSManagedObjectContext) {
        team.name = name
        team.pictureAssetId = icon
        team.pictureAssetKey = iconKey
    }

}
