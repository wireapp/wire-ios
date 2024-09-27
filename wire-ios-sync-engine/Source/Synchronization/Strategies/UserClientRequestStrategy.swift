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
import WireCryptobox
import WireDataModel
import WireSystem
import WireTransport
import WireUtilities

private let zmLog = ZMSLog(tag: "userClientRS")

// MARK: - UserClientRequestStrategy

/// Performs actions on the self clients
///
/// Actions:
/// - Register a new client
/// - Update an existing client with prekeys
/// - Delete an existing client
/// - Fetch all self clients

@objcMembers
public final class UserClientRequestStrategy: ZMObjectSyncStrategy, ZMObjectStrategy, ZMUpstreamTranscoder,
    ZMSingleRequestTranscoder, RequestStrategy {
    // MARK: Lifecycle

    public init(
        clientRegistrationStatus: ZMClientRegistrationStatus,
        clientUpdateStatus: ClientUpdateStatus,
        context: NSManagedObjectContext,
        proteusProvider: ProteusProviding
    ) {
        self.clientRegistrationStatus = clientRegistrationStatus
        self.clientUpdateStatus = clientUpdateStatus
        self.requestsFactory = UserClientRequestFactory()
        self.prekeyGenerator = PrekeyGenerator(proteusProvider: proteusProvider)

        super.init(managedObjectContext: context)

        let modifiedKeysToSync = [
            ZMUserClientNumberOfKeysRemainingKey,
            ZMUserClientNeedsToUpdateSignalingKeysKey,
            ZMUserClientNeedsToUpdateCapabilitiesKey,
            UserClient.needsToUploadMLSPublicKeysKey,
        ]

        self.modifiedSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: UserClient.entityName(),
            update: modifiedPredicate(),
            filter: nil,
            keysToSync: modifiedKeysToSync,
            managedObjectContext: context
        )

        self.deleteSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: UserClient.entityName(),
            update: NSPredicate(format: "\(ZMUserClientMarkedToDeleteKey) == YES"),
            filter: nil,
            keysToSync: [ZMUserClientMarkedToDeleteKey],
            managedObjectContext: context
        )

        self.insertSync = ZMUpstreamInsertedObjectSync(
            transcoder: self,
            entityName: UserClient.entityName(),
            filter: insertSyncFilter,
            managedObjectContext: context
        )

        self.fetchAllClientsSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: context)
    }

    // MARK: Public

    public var requestsFactory: UserClientRequestFactory
    public var minNumberOfRemainingKeys: UInt = 20

    // we don;t use this method but it's required by ZMObjectStrategy protocol
    public var requestGenerators: [ZMRequestGenerator] {
        []
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [insertSync, modifiedSync, deleteSync]
    }

    public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let managedObjectContext else {
            assertionFailure("UserClientRequestStrategy has no context")
            return nil
        }

        guard let clientRegistrationStatus,
              let clientUpdateStatus else {
            return nil
        }

        if clientRegistrationStatus.currentPhase == .waitingForLogin {
            return nil
        }

        if clientUpdateStatus.currentPhase == .fetchingClients {
            fetchAllClientsSync.readyForNextRequestIfNotBusy()
            return fetchAllClientsSync.nextRequest(for: apiVersion)
        }

        if clientUpdateStatus.currentPhase == .deletingClients {
            if let request = deleteSync.nextRequest(for: apiVersion) {
                return request
            }
        }

        if clientRegistrationStatus.currentPhase == .generatingPrekeys {
            return nil
        }

        if clientRegistrationStatus.currentPhase == .waitingForPrekeys {
            clientRegistrationStatus.willGeneratePrekeys()
            WaitingGroupTask(context: managedObjectContext) { [self] in
                do {
                    let prekeys = try await prekeyGenerator.generatePrekeys()
                    let lastResortPrekey = try await prekeyGenerator.generateLastResortPrekey()
                    await managedObjectContext.perform {
                        clientRegistrationStatus.didGeneratePrekeys(prekeys, lastResortPrekey: lastResortPrekey)
                    }
                } catch {
                    // swiftlint:disable:next todo_requires_jira_link
                    // TODO: [F] check if we need to propagate error
                    WireLogger.proteus.error("prekeys: failed to generatePrekeys: \(error.localizedDescription)")
                }
            }
        }

        if clientRegistrationStatus.currentPhase == .unregistered {
            if let request = insertSync.nextRequest(for: apiVersion) {
                return request
            }
        }

        if clientRegistrationStatus.currentPhase == .registered || clientRegistrationStatus
            .currentPhase == .registeringMLSClient {
            return modifiedSync.nextRequest(for: apiVersion)
        }

        return nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        false
    }

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        requestsFactory.fetchClientsRequest(apiVersion: apiVersion)
    }

    public func request(
        forUpdating managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        guard let userClient = managedObject as? UserClient else {
            fatal("Called requestForUpdatingObject() on \(managedObject) to sync keys: \(keys)")
        }

        guard let clientUpdateStatus else {
            fatal("clientUpdateStatus is not set")
        }

        if keys.contains(ZMUserClientNumberOfKeysRemainingKey) {
            guard let prekeys = clientUpdateStatus.prekeys else {
                fatal("Asked to upload prekeys when there's no prekeys available")
            }
            do {
                return try requestsFactory.updateClientPreKeysRequest(
                    userClient,
                    prekeys: prekeys,
                    apiVersion: apiVersion
                )
            } catch {
                fatal("Couldn't create request for new pre keys: \(error)")
            }
        }

        if keys.contains(ZMUserClientMarkedToDeleteKey) {
            guard clientUpdateStatus.currentPhase == ClientUpdatePhase.deletingClients else {
                fatal("No email credentials in memory")
            }

            return requestsFactory.deleteClientRequest(
                userClient,
                credentials: clientUpdateStatus.credentials,
                apiVersion: apiVersion
            )
        }

        if keys.contains(ZMUserClientNeedsToUpdateSignalingKeysKey) {
            do {
                return try requestsFactory.updateClientSignalingKeysRequest(
                    userClient,
                    apiVersion: apiVersion
                )
            } catch {
                fatal("Couldn't create request for new signaling keys: \(error)")
            }
        }

        if keys.contains(ZMUserClientNeedsToUpdateCapabilitiesKey) {
            do {
                return try requestsFactory.updateClientCapabilitiesRequest(
                    userClient,
                    apiVersion: apiVersion
                )
            } catch {
                fatal("Couldn't create request for updating Capabilities: \(error)")
            }
        }

        if keys.contains(UserClient.needsToUploadMLSPublicKeysKey) {
            do {
                return try requestsFactory.updateClientMLSPublicKeysRequest(
                    userClient,
                    apiVersion: apiVersion
                )
            } catch {
                fatal("Couldn't create request for new mls public keys: \(error)")
            }
        }

        fatal("Unknown keys to sync (\(keys))")
    }

    public func request(
        forInserting managedObject: ZMManagedObject,
        forKeys keys: Set<String>?,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        guard let client = managedObject as? UserClient
        else { fatal("Called requestForInsertingObject() on \(managedObject.safeForLoggingDescription)") }
        guard let prekeys = clientRegistrationStatus?.prekeys else {
            fatal("Asked to insert client when there's no prekeys available")
        }
        guard let lastResortPrekey = clientRegistrationStatus?.lastResortPrekey else {
            fatal("Asked to insert client when there's no last resort prekey available")
        }

        return try? requestsFactory.registerClientRequest(
            client,
            credentials: clientRegistrationStatus?.emailCredentials,
            cookieLabel: CookieLabel.current.value,
            prekeys: prekeys,
            lastRestortPrekey: lastResortPrekey,
            apiVersion: apiVersion
        )
    }

    public func shouldCreateRequest(
        toSyncObject managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        withSync sync: Any,
        apiVersion: APIVersion
    ) -> Bool {
        if keys.contains(ZMUserClientNumberOfKeysRemainingKey), let userClient = managedObject as? UserClient {
            if userClient.numberOfKeysRemaining >= minNumberOfRemainingKeys {
                return false
            } else if clientUpdateStatus?.currentPhase == .waitingForPrekeys {
                clientUpdateStatus?.willGeneratePrekeys()
                let nextPrekeyIndex = UInt16(userClient.preKeysRangeMax) + 1
                let groups = managedObjectContext?.enterAllGroupsExceptSecondary() ?? []
                Task {
                    do {
                        let prekeys = try await prekeyGenerator.generatePrekeys(startIndex: nextPrekeyIndex)
                        await managedObjectContext?.perform {
                            self.clientUpdateStatus?.didGeneratePrekeys(prekeys)
                        }
                    } catch {
                        // swiftlint:disable:next todo_requires_jira_link
                        // TODO: [F] check if we need to propagate error
                        WireLogger.proteus
                            .error(
                                "prekeys: shouldCreateRequest: failed to generatePrekeys: \(error.localizedDescription)"
                            )
                    }
                    managedObjectContext?.leaveAllGroups(groups)
                }
                return false
            } else {
                return clientUpdateStatus?.currentPhase != .generatingPrekeys
            }
        }
        return true
    }

    public func shouldRetryToSyncAfterFailed(
        toUpdate managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse,
        keysToParse: Set<String>
    ) -> Bool {
        if keysToParse.contains(ZMUserClientNumberOfKeysRemainingKey) {
            return false
        }
        if keysToParse.contains(ZMUserClientNeedsToUpdateSignalingKeysKey) {
            if response.httpStatus == 400, let label = response.payloadLabel(), label == "bad-request" {
                // Malformed prekeys uploaded - recreate and retry once per launch

                if didRetryRegisteringSignalingKeys {
                    (managedObject as? UserClient)?.needsToUploadSignalingKeys = false
                    managedObjectContext?.saveOrRollback()
                    fatal(
                        "UserClientTranscoder sigKey request failed with bad-request - \(upstreamRequest.transportRequest.safeForLoggingDescription)"
                    )
                }
                didRetryRegisteringSignalingKeys = true
                return true
            }
            (managedObject as? UserClient)?.needsToUploadSignalingKeys = false
            return false
        }
        if keysToParse.contains(ZMUserClientNeedsToUpdateCapabilitiesKey) {
            if response.httpStatus == 400, let label = response.payloadLabel(), label == "bad-request" {
                if didRetryUpdatingCapabilities {
                    (managedObject as? UserClient)?.needsToUpdateCapabilities = false
                    managedObjectContext?.saveOrRollback()
                    fatal(
                        "UserClientTranscoder PUT Capabilities request failed with bad-request - \(upstreamRequest.transportRequest.safeForLoggingDescription)"
                    )
                }
                didRetryUpdatingCapabilities = true
                return true
            }
            (managedObject as? UserClient)?.needsToUpdateCapabilities = false
            return false
        } else if keysToParse.contains(ZMUserClientMarkedToDeleteKey) {
            let error = errorFromFailedDeleteResponse(response)
            if error.code == ClientUpdateError.clientToDeleteNotFound.rawValue {
                managedObjectContext?.delete(managedObject)
                managedObjectContext?.saveOrRollback()
            }
            clientUpdateStatus?.failedToDeleteClient(managedObject as! UserClient, error: error)
            return false
        } else if keysToParse.contains(UserClient.needsToUploadMLSPublicKeysKey) {
            return false
        } else {
            // first we try to register without password (credentials can be there, but they can not contain password)
            // if there is no password in credentials but it's required, we will recieve error from backend and only
            // then will ask for password
            let error = errorFromFailedInsertResponse(response)
            if error.code == UserSessionErrorCode.canNotRegisterMoreClients.rawValue {
                clientUpdateStatus?.needsToFetchClients(andVerifySelfClient: false)
            }
            clientRegistrationStatus?.didFail(toRegisterClient: error)
            return true
        }
    }

    public func updateInsertedObject(
        _ managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse
    ) {
        if let client = managedObject as? UserClient {
            guard
                let payload = response.payload as? [String: AnyObject],
                let remoteIdentifier = payload["id"] as? String
            else {
                zmLog.warn("Unexpected backend response for inserted client")
                return
            }

            client.remoteIdentifier = remoteIdentifier
            client.numberOfKeysRemaining = Int32(prekeyGenerator.keyCount)
            guard let moc = managedObjectContext else { return }
            _ = UserClient.createOrUpdateSelfUserClient(payload, context: moc)
            clientRegistrationStatus?.didRegisterProteusClient(client)
        } else {
            fatal("Called updateInsertedObject() on \(managedObject.safeForLoggingDescription)")
        }
    }

    public func errorFromFailedDeleteResponse(_ response: ZMTransportResponse!) -> NSError {
        var errorCode: ClientUpdateError = .none
        if let response, response.result == .permanentError {
            if let errorLabel = response.payload?.asDictionary()?["label"] as? String {
                switch errorLabel {
                case "client-not-found":
                    errorCode = .clientToDeleteNotFound
                case "invalid-credentials",
                     "missing-auth",
                     // in case the password not matching password format requirement
                     "bad-request":
                    errorCode = .invalidCredentials
                default:
                    break
                }
            }
        }
        return ClientUpdateError.errorForType(errorCode)()
    }

    public func errorFromFailedInsertResponse(_ response: ZMTransportResponse!) -> NSError {
        var errorCode: UserSessionErrorCode = .unknownError
        if let moc = managedObjectContext, let response, response.result == .permanentError {
            if let errorLabel = response.payload?.asDictionary()?["label"] as? String {
                switch errorLabel {
                case "missing-auth":
                    if let emailAddress = ZMUser.selfUser(in: moc).emailAddress, !emailAddress.isEmpty {
                        errorCode = .needsPasswordToRegisterClient
                    } else {
                        errorCode = .invalidCredentials
                    }

                case "too-many-clients":
                    errorCode = .canNotRegisterMoreClients

                case "invalid-credentials",
                     "code-authentication-failed",
                     "code-authentication-required":
                    errorCode = .invalidCredentials

                default:
                    break
                }
            }
        }
        return NSError(domain: NSError.userSessionErrorDomain, code: Int(errorCode.rawValue), userInfo: nil)
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        switch response.result {
        case .success:
            if let payload = response.payload?.asArray() as? [[String: AnyObject]] {
                received(clients: payload)
            }

        case .expired:
            clientUpdateStatus?.failedToFetchClients()

        default:
            break
        }
    }

    /// Returns whether synchronization of this object needs additional requests
    public func updateUpdatedObject(
        _ managedObject: ZMManagedObject,
        requestUserInfo: [AnyHashable: Any]?,
        response: ZMTransportResponse,
        keysToParse: Set<String>
    ) -> Bool {
        guard let userClient = managedObject as? UserClient else { return false }

        if keysToParse.contains(ZMUserClientMarkedToDeleteKey) {
            return processResponseForDeletingClients(
                managedObject,
                requestUserInfo: requestUserInfo,
                responsePayload: response.payload
            )
        } else if keysToParse.contains(ZMUserClientNumberOfKeysRemainingKey) {
            (managedObject as! UserClient).numberOfKeysRemaining += Int32(prekeyGenerator.keyCount)
            clientUpdateStatus?.didUploadPrekeys()
        } else if keysToParse.contains(ZMUserClientNeedsToUpdateSignalingKeysKey) {
            didRetryRegisteringSignalingKeys = false
        } else if keysToParse.contains(ZMUserClientNeedsToUpdateCapabilitiesKey) {
            didRetryUpdatingCapabilities = false
        } else if keysToParse.contains(UserClient.needsToUploadMLSPublicKeysKey), response.result == .success {
            userClient.needsToUploadMLSPublicKeys = false
            clientRegistrationStatus?.didRegisterMLSClient(userClient)
        }

        return false
    }

    // Should return the objects that need to be refetched from the BE in case of upload error
    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        nil
    }

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        // Events are processed by the UserClientEventConsumer
    }

    // MARK: Internal

    weak var clientRegistrationStatus: ZMClientRegistrationStatus?
    weak var clientUpdateStatus: ClientUpdateStatus?

    fileprivate(set) var modifiedSync: ZMUpstreamModifiedObjectSync! = nil
    fileprivate(set) var deleteSync: ZMUpstreamModifiedObjectSync! = nil
    fileprivate(set) var insertSync: ZMUpstreamInsertedObjectSync! = nil
    fileprivate(set) var fetchAllClientsSync: ZMSingleRequestSync! = nil
    let prekeyGenerator: PrekeyGenerator

    func modifiedPredicate() -> NSPredicate {
        guard let baseModifiedPredicate = UserClient.predicateForObjectsThatNeedToBeUpdatedUpstream() else {
            fatal("baseModifiedPredicate is nil!")
        }

        let needToUploadKeysPredicate = NSPredicate(
            format: "\(ZMUserClientNumberOfKeysRemainingKey) < \(minNumberOfRemainingKeys)"
        )

        let needsToUploadSignalingKeysPredicate = NSPredicate(
            format: "\(ZMUserClientNeedsToUpdateSignalingKeysKey) == YES"
        )

        let needsToUpdateCapabilitiesPredicate = NSPredicate(
            format: "\(ZMUserClientNeedsToUpdateCapabilitiesKey) == YES"
        )

        let needsToUploadMLSPublicKeysPredicate = NSPredicate(
            format: "\(UserClient.needsToUploadMLSPublicKeysKey) == YES"
        )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            baseModifiedPredicate,
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                needToUploadKeysPredicate,
                needsToUploadSignalingKeysPredicate,
                needsToUpdateCapabilitiesPredicate,
                needsToUploadMLSPublicKeysPredicate,
            ]),
        ])
    }

    func processResponseForDeletingClients(
        _ managedObject: ZMManagedObject!,
        requestUserInfo: [AnyHashable: Any]!,
        responsePayload payload: ZMTransportData!
    ) -> Bool {
        // is it safe for ui??
        if let client = managedObject as? UserClient, let context = managedObjectContext {
            WaitingGroupTask(context: context) {
                await client.deleteClientAndEndSession()
                await context.perform { self.clientUpdateStatus?.didDeleteClient() }
            }
        }
        return false
    }

    // MARK: Fileprivate

    fileprivate var didRetryRegisteringSignalingKeys = false
    fileprivate var didRetryUpdatingCapabilities = false

    fileprivate var insertSyncFilter: NSPredicate {
        NSPredicate { object, _ -> Bool in
            guard let client = object as? UserClient, let user = client.user else { return false }
            return user.isSelfUser
        }
    }

    // MARK: Private

    private func received(clients: [[String: AnyObject]]) {
        guard let context = managedObjectContext else { return }

        let clients = clients.compactMap { clientInfo in
            UserClient.createOrUpdateSelfUserClient(clientInfo, context: context)
        }

        // remove all clients that are not there, with the exception of the self client
        // in theory we should also remove the self client and log out, but this will happen
        // next time the user sends a message or when we will receive the "deleted" event
        // for that client
        let foundClientsIdentifier = Set(clients.compactMap(\.remoteIdentifier))
        let selfUser = ZMUser.selfUser(in: context)
        let selfClient = selfUser.selfClient()
        let otherClients = selfUser.clients
        let deletedClients = otherClients.filter {
            $0 != selfClient && $0.remoteIdentifier.map { foundClientsIdentifier.contains($0) } == false
        }

        WaitingGroupTask(context: context) {
            for deletedClient in deletedClients {
                await deletedClient.deleteClientAndEndSession()
            }
            await context.perform {
                context.saveOrRollback()
                self.clientUpdateStatus?.didFetchClients(clients)
            }
        }

        context.saveOrRollback()
        clientUpdateStatus?.didFetchClients(clients)
    }
}
