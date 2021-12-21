// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// Request strategy for fetching user profiles and processing user update events.
///
/// User profiles are fetched:
/// - During the `.fetchingUsers` slow sync phase.
/// - When a user is marked as `needsToBeUpdatedFromBackend`.
///
public class UserProfileRequestStrategy: AbstractRequestStrategy, IdentifierObjectSyncDelegate, FederationAware {

    var isFetchingAllConnectedUsers: Bool = false
    let syncProgress: SyncProgress

    let userProfileByID: IdentifierObjectSync<UserProfileByIDTranscoder>
    let userProfileByQualifiedID: IdentifierObjectSync<UserProfileByQualifiedIDTranscoder>

    let userProfileByIDTranscoder: UserProfileByIDTranscoder
    let userProfileByQualifiedIDTranscoder: UserProfileByQualifiedIDTranscoder

    public var useFederationEndpoint: Bool {
        get {
            userProfileByQualifiedIDTranscoder.isAvailable
        }
        set {
            userProfileByQualifiedIDTranscoder.isAvailable = newValue
        }
    }

    public init(managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                syncProgress: SyncProgress) {

        self.syncProgress = syncProgress
        self.userProfileByIDTranscoder = UserProfileByIDTranscoder(context: managedObjectContext)
        self.userProfileByQualifiedIDTranscoder = UserProfileByQualifiedIDTranscoder(context: managedObjectContext)

        self.userProfileByID = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                    transcoder: userProfileByIDTranscoder)
        self.userProfileByQualifiedID = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                             transcoder: userProfileByQualifiedIDTranscoder)

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [.allowsRequestsWhileOnline,
                              .allowsRequestsDuringSlowSync]
        self.userProfileByID.delegate = self
        self.userProfileByQualifiedID.delegate = self
        self.userProfileByQualifiedIDTranscoder.contextChangedTracker = self
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        fetchAllConnectedUsers()

        return userProfileByQualifiedID.nextRequest() ?? userProfileByID.nextRequest()
    }

    func fetch(_ users: Set<ZMUser>) {
        let users = users.filter({ !$0.isSelfUser })
        guard !users.isEmpty else { return }

        if userProfileByQualifiedID.isAvailable, let qualifiedUserIDs = users.qualifiedUserIDs {
            userProfileByQualifiedID.sync(identifiers: qualifiedUserIDs)
        } else {
            userProfileByID.sync(identifiers: users.compactMap(\.remoteIdentifier))
        }

    }

    func fetchAllConnectedUsers() {
        guard syncProgress.currentSyncPhase == .fetchingUsers,
              !isFetchingAllConnectedUsers
        else {
            return
        }

        let allConnectedUsers = self.allConnectedUsers()

        if allConnectedUsers.isEmpty {
            syncProgress.finishCurrentSyncPhase(phase: .fetchingUsers)
        } else {
            fetch(allConnectedUsers)
        }

        isFetchingAllConnectedUsers = true
    }

    func allConnectedUsers() -> Set<ZMUser> {
        let fetchRequest = NSFetchRequest<ZMConnection>(entityName: ZMConnection.entityName())
        let connections = managedObjectContext.fetchOrAssert(request: fetchRequest)

        return Set(connections.compactMap(\.to))
    }

    public func didFailToSyncAllObjects() {
        if syncProgress.currentSyncPhase == .fetchingUsers {
            syncProgress.failCurrentSyncPhase(phase: .fetchingUsers)
            isFetchingAllConnectedUsers = false
        }
    }

    public func didFinishSyncingAllObjects() {
        guard
            syncProgress.currentSyncPhase == .fetchingUsers,
            !userProfileByID.isSyncing,
            !userProfileByQualifiedID.isSyncing
        else {
            return
        }

        syncProgress.finishCurrentSyncPhase(phase: .fetchingUsers)
        isFetchingAllConnectedUsers = false
    }

}

extension UserProfileRequestStrategy: ZMContextChangeTracker {

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        let usersNeedingToBeUpdated = objects.compactMap({ $0 as? ZMUser}).filter(\.needsToBeUpdatedFromBackend)

        fetch(Set(usersNeedingToBeUpdated))
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return ZMUser.sortedFetchRequest(with: ZMUser.predicateForNeedingToBeUpdatedFromBackend()!)
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        guard let users = objects as? Set<ZMUser> else {
            return
        }

        fetch(users)
    }

}

extension UserProfileRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            switch event.type {
            case .userUpdate:
                processUserUpdate(event)
            case .userDelete:
                processUserDeletion(event)
            default:
                break
            }
        }
    }

    func processUserUpdate(_ updateEvent: ZMUpdateEvent) {
        guard updateEvent.type == .userUpdate else { return }

        guard
            let payloadAsDictionary = updateEvent.payload["user"] as? [String: Any],
            let payloadData = try? JSONSerialization.data(withJSONObject: payloadAsDictionary, options: []),
            let userProfile = Payload.UserProfile(payloadData),
            let userID = userProfile.id
        else {
            return Logging.eventProcessing.error("Malformed user.update update event, skipping...")
        }

        let user = ZMUser.fetchOrCreate(with: userID,
                                        domain: userProfile.qualifiedID?.domain,
                                        in: managedObjectContext)
        userProfile.updateUserProfile(for: user, authoritative: false)
    }

    func processUserDeletion(_ updateEvent: ZMUpdateEvent) {
        guard updateEvent.type == .userDelete else { return }

        guard let userId = (updateEvent.payload["id"] as? String).flatMap(UUID.init),
              let user = ZMUser.fetch(with: userId, in: managedObjectContext)
        else {
            return Logging.eventProcessing.error("Malformed user.delete update event, skipping...")
        }

        if user.isSelfUser {
            deleteAccount()
        } else {
            user.markAccountAsDeleted(at: updateEvent.timestamp ?? Date())
        }
    }

    private func deleteAccount() {
        let notification = AccountDeletedNotification(context: managedObjectContext)
        notification.post(in: managedObjectContext.notificationContext)
    }

}

class UserProfileByIDTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = UUID

    var fetchLimit: Int =  1600 / 25 // UUID as string is 24 + 1 for the comma
    var isAvailable: Bool = true

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<UUID>) -> ZMTransportRequest? {
        // GET /users?ids=?
        let userIDs = identifiers.map({ $0.transportString() }).joined(separator: ",")
        return ZMTransportRequest(getFromPath: "/users?ids=\(userIDs)")
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<UUID>) {

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

        payload.updateUserProfiles(in: context)

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
    var isAvailable: Bool = true

    weak var contextChangedTracker: ZMContextChangeTracker?
    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<QualifiedID>) -> ZMTransportRequest? {
        guard
            let payloadData = Payload.QualifiedUserIDList(qualifiedIDs: Array(identifiers)).payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        // POST /list-users
        let path = NSString.path(withComponents: ["/list-users"])
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payloadAsString as ZMTransportData?)
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<QualifiedID>) {

        if response.httpStatus == 404, let responseFailure = Payload.ResponseFailure(response, decoder: decoder) {
            switch responseFailure.label {
            case .noEndpoint:
                // NOTE should be removed or replaced once the BE exposes a version number.
                Logging.network.warn("Endpoint not available, deactivating.")
                isAvailable = false

                // Re-schedule to fetch clients with the clients with the fallback
                if let users = ZMUser.fetchObjects(withRemoteIdentifiers: Set(identifiers.map(\.uuid)),
                                                   in: context) as? Set<ZMUser> {
                    contextChangedTracker?.objectsDidChange(Set(users))
                }
            case .notFound:
                markUserProfilesAsFetched(identifiers)
            default:
                break
            }

            return
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.UserProfiles(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.updateUserProfiles(in: context)

        let missingIdentifiers = identifiers.subtracting(payload.compactMap(\.qualifiedID))
        markUserProfilesAsFetched(missingIdentifiers)
    }

    private func markUserProfilesAsFetched(_ missingUsers: Set<QualifiedID>) {
        for qualifiedID in missingUsers {
            let user = ZMUser.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            user?.needsToBeUpdatedFromBackend = false
        }
    }

}
