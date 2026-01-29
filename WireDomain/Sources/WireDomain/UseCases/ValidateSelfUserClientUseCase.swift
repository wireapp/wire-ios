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
import WireDataModel
import WireNetwork

/// Ensures the self user client is properly set up and
/// in a valid state, ready to be used for communication.

public protocol ValidateSelfUserClientUseCaseProtocol {

    /// Validate the self user client.
    ///
    ///  - Throws: `ValidateSelfUserClientUseCaseError` in case
    ///  the self client is not valid.

    func invoke() async throws

}

/// Errors originating from ValidateSelfUserClientUseCaseProtocol

public enum ValidateSelfUserClientUseCaseError: Error {

    /// The self user does not have a remote id.

    case userNotRegistered

    /// The user needs to set a username before client
    /// registration can begin.

    case usernameRequired

    /// The user needs to delete one of their existing clients
    /// before registering the self client.

    case tooManyClients

    /// The self client require a valid E2EI certificate.

    case endToEndIdentityEnrollmentRequired

}

public struct ValidateSelfUserClientUseCase: ValidateSelfUserClientUseCaseProtocol {

    private let deviceName: String
    private let deviceLabel: String

    private let shouldRegisterMLSClient: Bool
    private let canRegisterMLSClient: Bool
    private let isE2EIRequired: Bool
    private let isE2EIEnrolled: Bool

    private let context: NSManagedObjectContext
    private let proteusService: any ProteusServiceInterface
    private let coreCryptoProvider: any CoreCryptoProviderProtocol
    private let userClientsAPI: any UserClientsAPI
    private let mlsService: any MLSServiceInterface

    private let localDomain: String
    private let apiVersion: WireNetwork.APIVersion

    public func invoke() async throws {
        // Ensure user is registered.
        guard let userID = await fetchUserID() else {
            throw ValidateSelfUserClientUseCaseError.userNotRegistered
        }

        // Ensure client exists locally.
        let (localID, maybeRemoteID) = try await fetchOrCreateLocalClient()

        // Ensure client exists remotely.
        let remoteID: String
        if let maybeRemoteID {
            remoteID = maybeRemoteID
        } else {
            remoteID = try await registerNewClient(localClientID: localID)
        }

        // If MLS is enabled.
        if shouldRegisterMLSClient && canRegisterMLSClient {
            // Ensure MLS client is initialized locally.
            if try await !isMLSClientInitialized(localClientID: localID) {
                if isE2EIRequired && !isE2EIEnrolled {
                    // Initialization happens in E2EI enrollment flow.
                    throw ValidateSelfUserClientUseCaseError.endToEndIdentityEnrollmentRequired
                } else {
                    // Initialize normally.
                    let mlsClientID = MLSClientID(
                        userID: userID.transportString(),
                        clientID: remoteID,
                        domain: localDomain
                    )

                    try await coreCryptoProvider.initialiseMLSWithBasicCredentials(
                        mlsClientID: mlsClientID
                    )
                }
            }

            // Ensure MLS client is registered remotely.
            if try await !isMLSClientRegisteredRemotely(localClientID: localID) {
                try await uploadMLSPublicKeys(localID: localID, remoteID: remoteID)
            }

            try await uploadMLSKeyPackagesIfNeeded()
        }
    }

    // MARK: - Helpers

    private func fetchUserID() async -> UUID? {
        await context.perform { [context] in
            ZMUser.selfUser(in: context).remoteIdentifier
        }
    }

    private func fetchOrCreateLocalClient() async throws -> (
        objectID: NSManagedObjectID,
        remoteID: String?
    ) {
        try await context.perform { [context, deviceName, deviceLabel] in
            let selfUser = ZMUser.selfUser(in: context)
            if let selfClient = selfUser.selfClient(), !selfClient.isZombieObject {
                // Client exists in DB.
                return (selfClient.objectID, selfClient.remoteIdentifier)
            } else if let selfClient = selfUser.clients.first(where: {
                $0.remoteIdentifier == nil
            }) {
                // Client exists but is not yet registered.
                return (objectID: selfClient.objectID, remoteID: selfClient.remoteIdentifier)
            } else {
                // No local client exists yet.
                let selfClient = UserClient.insertNewSelfClient(
                    in: context,
                    selfUser: selfUser,
                    model: deviceName,
                    label: deviceLabel
                )

                try context.save()
                return (objectID: selfClient.objectID, remoteID: selfClient.remoteIdentifier)
            }
        }
    }

    func registerNewClient(localClientID: NSManagedObjectID) async throws -> String {
        let prekeys = try await generateProteusPrekeys(startIndex: 0)
        let lastResortPrekey = try await generateLastResortProteusPrekey()

        let capabilities: [UserClientCapability] = if apiVersion >= .v9 {
            [.legalholdConsent, .consumableNotifications]
        } else {
            [.legalholdConsent]
        }

        let newClient = try await context.perform { [context] in
            let client = try context.existingObject(with: localClientID) as! UserClient

            // Note on the cookie label:
            // A random UUID() label should be generated for each log in
            // which should be stored with the account.

            // If there's a hard logout (data wiped)
            // the label should also be deleted.

            // We should use the same label when registering the client.

            return NewClient(
                prekeys: prekeys,
                lastkey: lastResortPrekey,
                type: client.type.toNetwork(),
                capabilities: capabilities,
                deviceClass: client.deviceClass?.toNetwork(),
                cookie: nil, // TODO: check what this is used for
                label: client.label,
                model: client.model,
                password: nil,
                verificationCode: nil,
                mlsPublicKeys: nil // mls registration happens later.
            )
        }

        let remoteClient = try await userClientsAPI.registerClient(newClient: newClient)

        // Update local state.
        return try await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            let localClient = try context.existingObject(with: localClientID) as! UserClient

            localClient.remoteIdentifier = remoteClient.id
            localClient.numberOfKeysRemaining = Int32(newClient.prekeys.count)
            // TODO: check if other properties need storing
            localClient.activationDate = remoteClient.activationDate
            localClient.lastActiveDate = remoteClient.lastActiveDate
            localClient.isConsumableNotificationsCapable = remoteClient.capabilities.contains(.consumableNotifications)
            localClient.needsSessionMigration = selfUser.domain == nil

            let otherClients = selfUser.clients.filter { client in
                client.remoteIdentifier != localClient.remoteIdentifier
            }

            if !otherClients.isEmpty {
                localClient.missesClients(otherClients)
                localClient.setLocallyModifiedKeys(Set(["missingClients"]))
            }

            localClient.markAsSelfClient()
            try context.save()

            // TODO: Set client id in WireLoger.authentication
            return remoteClient.id
        }
    }

    private func generateProteusPrekeys(startIndex: UInt16) async throws -> [Prekey] {
        try await proteusService.generatePrekeys(start: startIndex, count: 100).map {
            Prekey(
                id: Int($0),
                base64EncodedKey: $1
            )
        }
    }

    func generateLastResortProteusPrekey() async throws -> Prekey {
        Prekey(
            id: Int(await proteusService.lastPrekeyID),
            base64EncodedKey: try await proteusService.lastPrekey()
        )
    }

    private func isMLSClientInitialized(localClientID: NSManagedObjectID) async throws -> Bool {
        try await context.perform { [context] in
            let localClient = try context.existingObject(with: localClientID) as! UserClient
            return !localClient.mlsPublicKeys.isEmpty
        }
    }

    private func isMLSClientRegisteredRemotely(localClientID: NSManagedObjectID) async throws -> Bool {
        try await context.perform { [context] in
            let localClient = try context.existingObject(with: localClientID) as! UserClient
            return !localClient.needsToUploadMLSPublicKeys
        }
    }

    private func uploadMLSPublicKeys(
        localID: NSManagedObjectID,
        remoteID: UserClientID
    ) async throws {
        let mlsPublicKeys = try await context.perform { [context] in
            let client = try context.existingObject(with: localID) as! UserClient
            return client.mlsPublicKeys.toNetwork()
        }
        let clientUpdate = ClientUpdate(mlsPublicKeys: mlsPublicKeys)
        try await userClientsAPI.updateClient(
            id: remoteID,
            clientUpdate: clientUpdate
        )
    }

    private func uploadMLSKeyPackagesIfNeeded() async throws {
        await mlsService.uploadKeyPackagesIfNeeded()
    }

}

private extension WireDataModel.DeviceClass {

    func toNetwork() -> WireNetwork.DeviceClass {
        switch self {
        case .phone:
                .phone
        case .tablet:
                .tablet
        case .desktop:
                .desktop
        case .legalHold:
                .legalhold
        default:
                .phone
        }
    }

}

private extension WireDataModel.DeviceType {

    func toNetwork() -> WireNetwork.UserClientType {
        switch self {
        case .permanent:
                .permanent
        case .temporary:
                .temporary
        case .legalHold:
                .legalhold
        default:
                .permanent
        }
    }

}

private extension UserClient.MLSPublicKeys {

    func toNetwork() -> WireNetwork.MLSPublicKeys {
        MLSPublicKeys(
            ed25519: ed25519,
            p256: p256,
            p384: p384,
            p521: p521
        )
    }

}
