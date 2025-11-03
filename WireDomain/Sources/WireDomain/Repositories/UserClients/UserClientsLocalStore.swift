//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLegacyLogging

public struct UserClientsLocalStore: UserClientsLocalStoreProtocol {

    // MARK: - Properties

    let context: NSManagedObjectContext

    // MARK: - Methods

    public func fetchSelfClient() async -> UserClient? {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            return selfUser.selfClient()
        }
    }

    public func fetchSelfClientID() async -> String? {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            return selfUser.selfClient()?.remoteIdentifier
        }
    }

    public func fetchClient(
        id: String,
        forUser user: ZMUser,
        createIfNeeded: Bool
    ) async -> UserClient? {
        await context.perform {
            UserClient.fetchUserClient(
                withRemoteId: id,
                forUser: user,
                createIfNeeded: createIfNeeded
            )
        }
    }

    public func fetchOrCreateClient(
        id: String
    ) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        await context.perform { [context] in
            if let existingClient = UserClient.fetchExistingUserClient(
                with: id,
                in: context
            ) {
                return (existingClient, false)
            } else {
                let newClient = UserClient.insertNewObject(in: context)
                newClient.remoteIdentifier = id
                return (newClient, true)
            }
        }
    }

    public func deletedSelfClients(
        newClients: [String]
    ) async -> [String] {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            return selfUser.clients
                .compactMap(\.remoteIdentifier)
                .filter {
                    !newClients.contains($0)
                }
        }
    }

    public func deleteClient(
        id: String
    ) async {
        let localClient = await context.perform { [context] in
            return UserClient.fetchExistingUserClient(
                with: id,
                in: context
            )
        }

        guard let localClient else {
            return WireLogger.userClient.error(
                "Failed to find existing client with id: \(id.redactedAndTruncated())"
            )
        }

        await localClient.deleteClientAndEndSession()
    }

    public func updateClient(
        id: String,
        isNewClient: Bool,
        userClientInfo: UserClientInfo
    ) async {
        await context.perform { [context] in

            guard let localClient = UserClient.fetchExistingUserClient(
                with: id,
                in: context
            ) else {
                return WireLogger.userClient.error(
                    "Failed to find existing client with id: \(id.redactedAndTruncated())"
                )
            }

            localClient.label = userClientInfo.label
            localClient.type = userClientInfo.type
            localClient.model = userClientInfo.model
            localClient.deviceClass = userClientInfo.deviceClass
            localClient.activationDate = userClientInfo.activationDate
            localClient.lastActiveDate = userClientInfo.lastActiveDate
            localClient.remoteIdentifier = userClientInfo.id
            localClient.isConsumableNotificationsCapable = userClientInfo.capabilities
                .contains(.consumableNotifications)

            let selfUser = ZMUser.selfUser(in: context)
            localClient.user = localClient.user ?? selfUser

            if isNewClient {
                localClient.needsSessionMigration = selfUser.domain == nil
            }

            if localClient.isLegalHoldDevice, isNewClient {
                selfUser.legalHoldRequest = nil
                selfUser.needsToAcknowledgeLegalHoldStatus = true
            }

            if !localClient.isSelfClient() {
                localClient.mlsPublicKeys = .init(
                    ed25519: userClientInfo.mlsPublicKeys?.ed25519,
                    ed448: userClientInfo.mlsPublicKeys?.ed448,
                    p256: userClientInfo.mlsPublicKeys?.p256,
                    p384: userClientInfo.mlsPublicKeys?.p384,
                    p521: userClientInfo.mlsPublicKeys?.p512
                )
            }

            guard let selfClient = selfUser.selfClient(), isNewClient else { return }

            if
                localClient.remoteIdentifier != selfClient.remoteIdentifier,
                let localClientActivationDate = localClient.activationDate,
                let selfClientActivationDate = selfClient.activationDate,
                localClientActivationDate.compare(selfClientActivationDate) == .orderedDescending {
                localClient.needsToNotifyUser = true
            }

            selfClient.addNewClientToIgnored(localClient)
            selfClient.updateSecurityLevelAfterDiscovering(Set([localClient]))
        }
    }

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            return selfUser.clients.all { userClient in
                let hasMLSIdentity = !userClient.mlsPublicKeys.isEmpty

                let isRecentlyActive: Bool = {
                    if userClient.isSelfClient() {
                        return true
                    }

                    guard let lastActiveDate = userClient.lastActiveDate else {
                        return false
                    }

                    guard lastActiveDate <= Date() else {
                        return true
                    }

                    return lastActiveDate.timeIntervalSinceNow.magnitude < .fourWeeks
                }()

                return hasMLSIdentity && isRecentlyActive
            }
        }
    }

    public func storeClient(
        discoveryDate: Date,
        client: WireDataModel.UserClient
    ) async {
        await context.perform {
            client.discoveryDate = discoveryDate
        }
    }

    public func addNewClientToIgnored(
        selfClient: WireDataModel.UserClient,
        newClient: WireDataModel.UserClient
    ) async {
        await context.perform {
            selfClient.addNewClientToIgnored(newClient)
        }
    }

    public func proteusSessionID(
        for client: WireDataModel.UserClient
    ) async -> ProteusSessionID? {
        await context.perform {
            client.proteusSessionID
        }
    }

    public func clientSessionCreated(
        selfClient: WireDataModel.UserClient,
        newClient: WireDataModel.UserClient
    ) async {
        await context.perform {
            selfClient.decrementNumberOfRemainingProteusKeys()
            selfClient.updateSecurityLevelAfterDiscovering([newClient])
        }
    }

    public func invalidateSelfClient() async {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            guard let selfClient = selfUser.selfClient() else {
                return
            }

            selfClient.remoteIdentifier = nil
            selfClient.resetLocallyModifiedKeys(selfClient.keysThatHaveLocalModifications)
            selfClient.clearMLSPublicKeys()
            context.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
            context.saveOrRollback()
        }
    }

    public func hasRegisteredConsumableNotificationsCapable() async -> Bool {
        await context.perform { [context] in
            let selfClient = ZMUser.selfUser(in: context).selfClient()
            return selfClient?.isConsumableNotificationsCapable == true
        }
    }

}
