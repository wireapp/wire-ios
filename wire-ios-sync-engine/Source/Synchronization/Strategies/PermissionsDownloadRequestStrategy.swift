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

import WireDataModel
import WireUtilities

// MARK: - MembershipListPayload

struct MembershipListPayload: Decodable {
    let hasMore: Bool
    let members: [MembershipPayload]
}

// MARK: - MembershipPayload

struct MembershipPayload: Decodable {
    // MARK: Internal

    struct PermissionsPayload: Decodable {
        // MARK: Internal

        let copyPermissions: Int64
        let selfPermissions: Int64

        // MARK: Private

        private enum CodingKeys: String, CodingKey {
            case copyPermissions = "copy"
            case selfPermissions = "self"
        }
    }

    let userID: UUID
    let createdBy: UUID?
    let createdAt: Date?
    let permissions: PermissionsPayload?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case userID = "user"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case permissions
    }
}

extension MembershipPayload {
    @discardableResult
    func createOrUpdateMember(team: Team, in managedObjectContext: NSManagedObjectContext) -> Member? {
        let user = ZMUser.fetchOrCreate(with: userID, domain: nil, in: managedObjectContext)
        let member = Member.getOrUpdateMember(for: user, in: team, context: managedObjectContext)

        if let permissions = permissions.flatMap({ Permissions(rawValue: $0.selfPermissions) }) {
            member.permissions = permissions
        }

        member.createdBy = ZMUser.fetchOrCreate(with: userID, domain: nil, in: managedObjectContext)
        member.createdAt = createdAt
        member.needsToBeUpdatedFromBackend = false

        return member
    }
}

extension Member {
    fileprivate static let predicateForObjectsNeedingToBeUpdated = NSPredicate(
        format: "%K == YES",
        #keyPath(Member.needsToBeUpdatedFromBackend)
    )
}

// MARK: - PermissionsDownloadRequestStrategy

public final class PermissionsDownloadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource,
    ZMRequestGeneratorSource, ZMDownstreamTranscoder {
    // MARK: Lifecycle

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        configuration = .allowsRequestsWhileOnline
        self.sync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: Member.entityName(),
            predicateForObjectsToDownload: Member.predicateForObjectsNeedingToBeUpdated,
            filter: nil,
            managedObjectContext: managedObjectContext
        )
    }

    // MARK: Public

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [sync]
    }

    public var requestGenerators: [ZMRequestGenerator] {
        [sync]
    }

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        sync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest! {
        guard let member = object as? Member,
              downstreamSync as? ZMDownstreamObjectSync == sync
        else {
            fatal("Wrong object: \(object.safeForLoggingDescription)")
        }
        guard let identifier = member.remoteIdentifier,
              let teamId = member.team?.remoteIdentifier
        else {
            fatal("No ids to sync: \(object.safeForLoggingDescription)")
        }
        return TeamDownloadRequestFactory.getSingleMemberRequest(for: identifier, in: teamId, apiVersion: apiVersion)
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard
            downstreamSync as? ZMDownstreamObjectSync == sync,
            let team = (object as? Member)?.team,
            let rawData = response.rawData,
            let memberhipPayload = MembershipPayload(rawData)
        else {
            return
        }

        memberhipPayload.createOrUpdateMember(team: team, in: managedObjectContext)
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard downstreamSync as? ZMDownstreamObjectSync == sync, let member = object as? Member else {
            return
        }
        managedObjectContext.delete(member)
    }

    // MARK: Fileprivate

    fileprivate var sync: ZMDownstreamObjectSync!
}
