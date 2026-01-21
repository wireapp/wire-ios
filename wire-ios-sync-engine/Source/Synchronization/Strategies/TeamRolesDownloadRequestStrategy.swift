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

private extension Team {

    static var predicateForTeamRolesNeedingToBeUpdated: NSPredicate = .init(
        format: "%K == YES AND %K != NULL",
        #keyPath(Team.needsToDownloadRoles),
        Team.remoteIdentifierDataKey()
    )

    func updateRoles(with payload: [String: Any]) {
        guard let rolesPayload = payload["conversation_roles"] as? [[String: Any]] else { return }
        let existingRoles = roles

        // Update or insert new roles
        let newRoles = rolesPayload.compactMap {
            Role.createOrUpdate(with: $0, teamOrConversation: .team(self), context: managedObjectContext!)
        }

        // Delete removed roles
        let rolesToDelete = existingRoles.subtracting(newRoles)
        rolesToDelete.forEach {
            managedObjectContext?.delete($0)
        }
    }

}

public final class TeamRolesDownloadRequestStrategy:
    AbstractRequestStrategy,
    ZMContextChangeTrackerSource,
    ZMRequestGeneratorSource,
    ZMRequestGenerator,
    ZMDownstreamTranscoder {

    private(set) var downstreamSync: ZMDownstreamObjectSync!

    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        self.downstreamSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: Team.entityName(),
            predicateForObjectsToDownload: Team.predicateForTeamRolesNeedingToBeUpdated,
            filter: nil,
            managedObjectContext: managedObjectContext
        )
    }

    public override func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        downstreamSync.nextRequest(for: apiVersion)
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [downstreamSync]
    }

    public var requestGenerators: [ZMRequestGenerator] {
        [self]
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest! {
        guard downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
              let team = object as? Team else { fatal("Wrong sync or object for: \(object.safeForLoggingDescription)") }
        return TeamDownloadRequestFactory.requestToDownloadRoles(for: team.remoteIdentifier!, apiVersion: apiVersion)
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
              let team = object as? Team,
              let payload = response.payload?.asDictionary() as? [String: Any] else { return }

        team.needsToDownloadRoles = false
        team.updateRoles(with: payload)
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // pass
    }
}
