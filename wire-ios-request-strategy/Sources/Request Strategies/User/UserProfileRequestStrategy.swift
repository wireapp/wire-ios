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
import WireLogging

/// Request strategy for fetching user profiles and processing user update events.
///
/// User profiles are fetched:
/// - During the `.fetchingUsers` slow sync phase.
/// - When a user is marked as `needsToBeUpdatedFromBackend`.
///
public class UserProfileRequestStrategy: AbstractRequestStrategy, IdentifierObjectSyncDelegate {
    var isFetchingAllConnectedUsers: Bool = false

    let userProfileByID: IdentifierObjectSync<UserProfileByIDTranscoder>
    let userProfileByQualifiedID: IdentifierObjectSync<UserProfileByQualifiedIDTranscoder>

    let userProfileByIDTranscoder: UserProfileByIDTranscoder
    let userProfileByQualifiedIDTranscoder: UserProfileByQualifiedIDTranscoder

    let actionSync: EntityActionSync

    private let apiVersion: WireTransport.APIVersion?
    private let localDomain: String?
    private let isFederationEnabled: Bool

    public init(
        managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        apiVersion: WireTransport.APIVersion?,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.userProfileByIDTranscoder = UserProfileByIDTranscoder(
            context: managedObjectContext,
            isFederationEnabled: isFederationEnabled
        )
        self.userProfileByQualifiedIDTranscoder = UserProfileByQualifiedIDTranscoder(
            context: managedObjectContext,
            isFederationEnabled: isFederationEnabled
        )

        self.userProfileByID = IdentifierObjectSync(
            managedObjectContext: managedObjectContext,
            transcoder: userProfileByIDTranscoder
        )
        self.userProfileByQualifiedID = IdentifierObjectSync(
            managedObjectContext: managedObjectContext,
            transcoder: userProfileByQualifiedIDTranscoder
        )

        self.actionSync = EntityActionSync(actionHandlers: [SyncUsersActionHandler(
            context: managedObjectContext,
            isFederationEnabled: isFederationEnabled
        )])
        self.apiVersion = apiVersion
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringSlowSync
        ]
        userProfileByID.delegate = self
        userProfileByQualifiedID.delegate = self
        userProfileByQualifiedIDTranscoder.contextChangedTracker = self
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {

        [userProfileByID, userProfileByQualifiedID, actionSync].nextRequest(for: apiVersion)
    }

    func fetch(users: Set<ZMUser>, for apiVersion: APIVersion) {
        let users = users.filter { !$0.isSelfUser }
        guard !users.isEmpty else { return }

        switch apiVersion {
        case .v0:
            userProfileByID.sync(identifiers: users.compactMap(\.remoteIdentifier))

        case .v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
            if let qualifiedUserIDs = users.qualifiedUserIDs {
                userProfileByQualifiedID.sync(identifiers: qualifiedUserIDs)
            } else if let localDomain {
                let qualifiedUserIDs = users.fallbackQualifiedIDs(localDomain: localDomain)
                userProfileByQualifiedID.sync(identifiers: qualifiedUserIDs)
            }
        }
    }

    public func didFinishSyncingAllObjects() {
        // do nothing
    }

    public func didFailToSyncAllObjects() {
        // do nothing
    }

}

extension UserProfileRequestStrategy: ZMContextChangeTracker {

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        guard let apiVersion else { return }

        let usersNeedingToBeUpdated = objects
            .compactMap { $0 as? ZMUser }
            .filter(\.needsToBeUpdatedFromBackend)

        fetch(users: Set(usersNeedingToBeUpdated), for: apiVersion)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        ZMUser.sortedFetchRequest(with: ZMUser.predicateForNeedingToBeUpdatedFromBackend())
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        guard
            let users = objects as? Set<ZMUser>,
            let apiVersion
        else {
            return
        }

        fetch(users: users, for: apiVersion)
    }

}

class UserProfileByIDTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = UUID

    var fetchLimit: Int = 1600 / 25 // UUID as string is 24 + 1 for the comma

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: UserProfilePayloadProcessor

    init(
        context: NSManagedObjectContext,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.processor = UserProfilePayloadProcessor(isFederationEnabled: isFederationEnabled)
    }

    func request(for identifiers: Set<UUID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard apiVersion == .v0 else { return nil }
        // GET /users?ids=?
        let userIDs = identifiers.map { $0.transportString() }.joined(separator: ",")
        return ZMTransportRequest(getFromPath: "/users?ids=\(userIDs)", apiVersion: apiVersion.rawValue)
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<UUID>,
        completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        if response.httpStatus == 404, let responseFailure = Payload.ResponseFailure(response, decoder: decoder) {
            if case .notFound = responseFailure.label {
                markUserProfilesAsFetched(identifiers)
                return
            }
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.UserProfiles(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        processor.updateUserProfiles(
            from: payload,
            in: context
        )

        let missingIdentifiers = identifiers.subtracting(payload.compactMap(\.id))
        markUserProfilesAsFetched(missingIdentifiers)
    }

    private func markUserProfilesAsFetched(_ missingUsers: Set<UUID>) {
        for userID in missingUsers {
            let user = ZMUser.fetch(with: userID, in: context)
            user?.needsToBeUpdatedFromBackend = false
        }
    }

}

class UserProfileByQualifiedIDTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = QualifiedID

    var fetchLimit: Int = 500

    weak var contextChangedTracker: ZMContextChangeTracker?
    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: UserProfilePayloadProcessor

    init(
        context: NSManagedObjectContext,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.processor = UserProfilePayloadProcessor(isFederationEnabled: isFederationEnabled)
    }

    func request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            apiVersion > .v0,
            let payloadData = Payload.QualifiedUserIDList(qualifiedIDs: Array(identifiers))
            .payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        // POST /list-users
        let path = NSString.path(withComponents: ["/list-users"])
        return ZMTransportRequest(
            path: path,
            method: .post,
            payload: payloadAsString as ZMTransportData?,
            apiVersion: apiVersion.rawValue
        )
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<QualifiedID>,
        completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        if response.httpStatus == 404, let responseFailure = Payload.ResponseFailure(response, decoder: decoder) {
            guard case .notFound = responseFailure.label else { return }
            markUserProfilesAsFetched(identifiers)
            return
        }

        // swiftlint:disable:next todo_requires_jira_link
        // TODO: [John] proper federation error handling.
        // This is a quick fix to make the app somewhat usable when
        // a remote federated backend is down.
        if response.httpStatus == 533 {
            markUserProfilesAsUnavailable(identifiers)
            return
        }

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else { return }
        switch apiVersion {
        case .v0, .v1, .v2, .v3:
            guard
                let rawData = response.rawData,
                let payload = Payload.UserProfiles(rawData, decoder: decoder)
            else {
                Logging.network.warn("Can't process response, aborting.")
                return
            }

            processor.updateUserProfiles(
                from: payload,
                in: context
            )

            let missingIdentifiers = identifiers.subtracting(payload.compactMap(\.qualifiedID))
            markUserProfilesAsFetched(missingIdentifiers)

        case .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
            guard
                let rawData = response.rawData,
                let payload = Payload.UserProfilesV4(rawData, decoder: decoder)
            else {
                Logging.network.warn("Can't process response, aborting.")
                return
            }

            processor.updateUserProfiles(
                from: payload.found,
                in: context
            )

            if let failedIdentifiers = payload.failed {
                markUserProfilesAsUnavailable(Set(failedIdentifiers))
            }
        }
    }

    private func markUserProfilesAsFetched(_ missingUsers: Set<QualifiedID>) {
        for qualifiedID in missingUsers {
            let user = ZMUser.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            user?.needsToBeUpdatedFromBackend = false
        }
    }

    private func markUserProfilesAsUnavailable(_ users: Set<QualifiedID>) {
        for qualifiedID in users {
            let user = ZMUser.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            user?.isPendingMetadataRefresh = true
            user?.needsToBeUpdatedFromBackend = false
        }
    }

}

private extension Collection<ZMUser> {

    func fallbackQualifiedIDs(localDomain: String) -> [QualifiedID] {
        compactMap { user in
            if let qualifiedID = user.qualifiedID {
                qualifiedID
            } else if let identifier = user.remoteIdentifier {
                QualifiedID(uuid: identifier, domain: localDomain)
            } else {
                nil
            }
        }
    }

}
