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

extension ZMConversation {
    fileprivate static var predicateForObjectsNeedingToDownloadRoles = NSPredicate(
        format: "%K == YES AND %K != NULL",
        #keyPath(ZMConversation.needsToDownloadRoles),
        ZMConversation.remoteIdentifierDataKey()
    )

    fileprivate func updateRoles(with response: ZMTransportResponse) {
        guard let rolesPayload = response.payload?.asDictionary()?["conversation_roles"] as? [[String: Any]]
        else {
            return
        }
        let existingRoles = nonTeamRoles

        // Update or insert new roles
        let newRoles = rolesPayload.compactMap {
            Role.createOrUpdate(with: $0, teamOrConversation: .conversation(self), context: managedObjectContext!)
        }

        // Delete removed roles
        let rolesToDelete = existingRoles.subtracting(newRoles)
        for item in rolesToDelete {
            managedObjectContext?.delete(item)
        }
    }
}

// MARK: - ConversationRoleDownstreamRequestStrategy

public final class ConversationRoleDownstreamRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource,
    ZMRequestGeneratorSource, ZMDownstreamTranscoder {
    // MARK: Lifecycle

    @objc
    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [.allowsRequestsWhileOnline]

        self.downstreamSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: ZMConversation.entityName(),
            predicateForObjectsToDownload: ZMConversation.predicateForObjectsNeedingToDownloadRoles,
            filter: nil,
            managedObjectContext: managedObjectContext
        )
    }

    // MARK: Public

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [downstreamSync]
    }

    public var requestGenerators: [ZMRequestGenerator] {
        [downstreamSync]
    }

    public static func getRolesRequest(in conversationIdentifier: UUID, apiVersion: APIVersion) -> ZMTransportRequest {
        let path = requestPath + "/" + conversationIdentifier.transportString() + "/roles"
        return ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
    }

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        downstreamSync.nextRequest(for: apiVersion)
    }

    public func request(
        forFetching object: ZMManagedObject!,
        downstreamSync: ZMObjectSync!,
        apiVersion: APIVersion
    ) -> ZMTransportRequest! {
        guard
            downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
            let conversation = object as? ZMConversation
        else {
            fatal("Wrong sync or object for: \(object.safeForLoggingDescription)")
        }

        return conversation.remoteIdentifier.map {
            ConversationRoleDownstreamRequestStrategy.getRolesRequest(in: $0, apiVersion: apiVersion)
        }
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // Do not delete conversation and set needsToDownloadRoles to false to avoid request loop
        guard
            downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
            let conversation = object as? ZMConversation,
            response.httpStatus == 404
        else {
            return
        }
        conversation.needsToDownloadRoles = false
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard
            downstreamSync as? ZMDownstreamObjectSync == self.downstreamSync,
            let conversation = object as? ZMConversation
        else {
            return
        }
        conversation.needsToDownloadRoles = false
        conversation.updateRoles(with: response)
    }

    // MARK: Internal

    static let requestPath = "/conversations"

    private(set) var downstreamSync: ZMDownstreamObjectSync!

    // MARK: Fileprivate

    fileprivate let jsonDecoder = JSONDecoder()
}
