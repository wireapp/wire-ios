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
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to users related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol UserRepositoryProtocol {

    /// Fetch self user from the local store

    func fetchSelfUser() -> ZMUser

    /// Fetches a user locally
    ///
    /// - parameters
    ///     - id: The ID of the user.
    ///     - domain: The domain of the user.
    /// - returns : A  local`ZMUser`.

    func fetchUser(
        with id: UUID,
        domain: String?
    ) async throws -> ZMUser

    /// Push self user supported protocols
    /// - Parameter supportedProtocols: A list of supported protocols.

    func pushSelfSupportedProtocols(
        _ supportedProtocols: Set<WireAPI.MessageProtocol>
    ) async throws

    /// Fetch and persist all locally known users

    func pullKnownUsers() async throws

    /// Fetch and persist a list of users
    ///
    /// - parameters:
    ///     - userIDs: IDs of users to fetch

    func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws

    /// Removes user push token from storage.

    func removePushToken()

    /// Adds a legal hold request.
    ///
    /// - parameters:
    ///     - userID: The user ID of the target legalhold subject.
    ///     - clientID: The client ID of the legalhold device.
    ///     - lastPrekey: The last prekey of the legalhold device.
    ///
    /// Legal hold is the ability to provide an auditable transcript of all communication
    /// held by team members that are put under legal hold compliance (from a third-party),
    /// achieved by collecting the content of such communication for later auditing.

    func addLegalHoldRequest(
        for userID: UUID,
        clientID: String,
        lastPrekey: Prekey
    ) async

    /// Disables user legal hold.

    func disableUserLegalHold() async throws

    /// Updates a user property
    ///
    /// - parameters:
    ///     - userProperty: The user property to update.

    func updateUserProperty(
        _ userProperty: WireAPI.UserProperty
    ) async throws

    /// Deletes a user property.
    ///
    /// - parameters:
    ///     - key: The user property key to delete.

    func deleteUserProperty(
        withKey key: UserProperty.Key
    ) async

    /// Deletes the user account.
    ///
    /// - parameters:
    ///     - user: The user to delete the account for.
    ///     - date: The date the user was deleted.

    func deleteUserAccount(for user: ZMUser, at date: Date) async

}

public final class UserRepository: UserRepositoryProtocol {

    enum DefaultsKeys: String {
        case pushToken = "PushToken"
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI
    private let selfUserAPI: any SelfUserAPI
    private let conversationLabelsRepository: any ConversationLabelsRepositoryProtocol
    private let conversationRepository: any ConversationRepositoryProtocol
    private let storage: UserDefaults

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        usersAPI: any UsersAPI,
        selfUserAPI: any SelfUserAPI,
        conversationLabelsRepository: any ConversationLabelsRepositoryProtocol,
        conversationRepository: ConversationRepositoryProtocol,
        sharedUserDefaults: UserDefaults = .standard
    ) {
        self.context = context
        self.usersAPI = usersAPI
        self.selfUserAPI = selfUserAPI
        self.conversationLabelsRepository = conversationLabelsRepository
        self.conversationRepository = conversationRepository
        storage = sharedUserDefaults
    }

    // MARK: - Public

    public func fetchSelfUser() -> ZMUser {
        ZMUser.selfUser(in: context)
    }

    public func fetchUser(
        with id: UUID,
        domain: String?
    ) async throws -> ZMUser {
        try await context.perform { [context] in
            guard let user = ZMUser.fetch(with: id, in: context) else {
                throw UserRepositoryError.failedToFetchUser(id)
            }

            return user
        }
    }

    public func pushSelfSupportedProtocols(
        _ supportedProtocols: Set<WireAPI.MessageProtocol>
    ) async throws {
        try await selfUserAPI.pushSupportedProtocols(supportedProtocols)
    }

    public func pullKnownUsers() async throws {
        let knownUserIDs: [WireDataModel.QualifiedID]

        do {
            knownUserIDs = try await context.perform {
                let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
                let knownUsers = try self.context.fetch(fetchRequest)
                return knownUsers.compactMap(\.qualifiedID)
            }
        } catch {
            throw UserRepositoryError.failedToCollectKnownUsers(error)
        }

        try await pullUsers(userIDs: knownUserIDs)
    }

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        do {
            let userList = try await usersAPI.getUsers(userIDs: userIDs.toAPIModel())

            await context.perform {
                for user in userList.found {
                    self.persistUser(from: user)
                }
            }
        } catch {
            throw UserRepositoryError.failedToFetchRemotely(error)
        }
    }

    public func removePushToken() {
        storage.set(
            nil,
            forKey: DefaultsKeys.pushToken.rawValue
        )
    }

    public func fetchUser(with id: UUID) async throws -> ZMUser {
        try await context.perform { [context] in
            guard let user = ZMUser.fetch(with: id, in: context) else {
                throw UserRepositoryError.failedToFetchUser(id)
            }

            return user
        }
    }

    public func addLegalHoldRequest(
        for userID: UUID,
        clientID: String,
        lastPrekey: Prekey
    ) async {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            guard let prekey = lastPrekey.toDomainModel() else {
                return WireLogger.eventProcessing.error(
                    "Invalid legal hold request payload: invalid base64 encoded key \(lastPrekey.base64EncodedKey)"
                )
            }

            let legalHoldRequest = LegalHoldRequest(
                target: userID,
                requester: nil,
                clientIdentifier: clientID,
                lastPrekey: prekey
            )

            selfUser.userDidReceiveLegalHoldRequest(legalHoldRequest)
        }
    }

    public func disableUserLegalHold() async throws {
        try await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.legalHoldRequestWasCancelled()

            try context.save()
        }
    }

    public func updateUserProperty(_ userProperty: UserProperty) async throws {
        switch userProperty {
        case .areReadReceiptsEnabled(let isEnabled):
            let selfUser = fetchSelfUser()

            await context.perform {
                selfUser.readReceiptsEnabled = isEnabled
                selfUser.readReceiptsEnabledChangedRemotely = true
            }

        case .conversationLabels(let conversationLabels):
            try await conversationLabelsRepository.updateConversationLabels(conversationLabels)

        default:
            WireLogger.updateEvent.warn(
                "\(String(describing: userProperty)) property not handled."
            )
        }
    }

    public func deleteUserProperty(
        withKey key: UserProperty.Key
    ) async {
        switch key {
        case .wireReceiptMode:
            let selfUser = fetchSelfUser()

            await context.perform {
                selfUser.readReceiptsEnabled = false
                selfUser.readReceiptsEnabledChangedRemotely = true
            }

        case .wireTypingIndicatorMode:
            // TODO: [WPB-726] feature not implemented yet
            break

        case .labels:
            /// Already handled with `user.properties-set` event (adding new labels and removing old ones)
            /// see `ConversationLabelsRepository`
            break
        }
    }

    public func deleteUserAccount(
        for user: ZMUser,
        at date: Date
    ) async {
        let isSelfUser = await context.perform {
            user.isSelfUser
        }

        if isSelfUser {
            let notification = AccountDeletedNotification(context: context)
            notification.post(in: context.notificationContext)
        } else {
            await context.perform {
                user.isAccountDeleted = true
            }

            await conversationRepository.removeFromConversations(
                user: user,
                removalDate: date
            )
        }
    }

    // MARK: - Private

    private func persistUser(from user: WireAPI.User) {
        let persistedUser = ZMUser.fetchOrCreate(with: user.id.uuid, domain: user.id.domain, in: context)

        guard user.deleted == false else {
            return persistedUser.markAccountAsDeleted(at: Date())
        }

        persistedUser.name = user.name
        persistedUser.handle = user.handle
        persistedUser.teamIdentifier = user.teamID
        persistedUser.accentColorValue = Int16(user.accentID)
        persistedUser.previewProfileAssetIdentifier = user.assets.first(where: { $0.size == .preview })?.key
        persistedUser.previewProfileAssetIdentifier = user.assets.first(where: { $0.size == .complete })?.key
        persistedUser.emailAddress = user.email
        persistedUser.expiresAt = user.expiresAt
        persistedUser.serviceIdentifier = user.service?.id.transportString()
        persistedUser.providerIdentifier = user.service?.provider.transportString()
        persistedUser.supportedProtocols = user.supportedProtocols?.toDomainModel() ?? [.proteus]
        persistedUser.needsToBeUpdatedFromBackend = false
    }
}
