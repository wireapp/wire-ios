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

import Foundation
import WireLogging
import WireRequestStrategy

// sourcery: AutoMockable
public protocol GetUserClientFingerprintUseCaseProtocol {
    func invoke(userClient: UserClient) async -> Data?
}

public struct GetUserClientFingerprintUseCase: GetUserClientFingerprintUseCaseProtocol {

    let proteusService: ProteusServiceInterface
    let context: NSManagedObjectContext
    let sessionEstablisher: SessionEstablisherInterface
    let metadata: BackendMetadataProvider

    // MARK: - Initialization

    init(
        syncContext: NSManagedObjectContext,
        transportSession: TransportSessionType,
        proteusService: ProteusServiceInterface,
        metadata: BackendMetadataProvider
    ) {
        let httpClient = HttpClientImpl(
            transportSession: transportSession,
            queue: syncContext
        )
        let apiProvider = APIProvider(httpClient: httpClient)
        let sessionEstablisher = SessionEstablisher(
            context: syncContext,
            apiProvider: apiProvider
        )

        self.init(
            proteusService: proteusService,
            sessionEstablisher: sessionEstablisher,
            managedObjectContext: syncContext,
            metadata: metadata
        )
    }

    init(
        proteusService: ProteusServiceInterface,
        sessionEstablisher: SessionEstablisherInterface,
        managedObjectContext: NSManagedObjectContext,
        metadata: BackendMetadataProvider
    ) {
        self.proteusService = proteusService
        self.context = managedObjectContext
        self.sessionEstablisher = sessionEstablisher
        self.metadata = metadata
    }

    // MARK: - Methods

    public func invoke(userClient: UserClient) async -> Data? {
        let objectId = userClient.objectID

        guard let (existingClient, clientId) = await context.perform({
            let client = try? self.context.existingObject(with: objectId) as? UserClient
            return (client, client?.qualifiedClientID) as? (UserClient, QualifiedClientID)
        }) else {
            return nil
        }

        let shouldEstablishSession = await existingClient.hasSessionWithSelfClient == false

        if shouldEstablishSession {
            if let apiVersion = metadata.apiVersion {
                do {
                    try await sessionEstablisher.establishSession(with: Set([clientId]), apiVersion: apiVersion)
                } catch {
                    WireLogger.proteus.error("cannot establishSession while getting fingerprint: \(error)")
                }
            } else {
                WireLogger.backend.warn("apiVersion not resolved, cannot establishSession")
            }
        }

        let isSelfClient = await context.perform {
            existingClient.isSelfClient()
        }

        if isSelfClient {
            return await localFingerprint()
        } else {
            return await fetchRemoteFingerprint(for: existingClient)
        }
    }

    func localFingerprint() async -> Data? {
        do {
            let fingerprint = try await proteusService.localFingerprint()
            return fingerprint.utf8Data
        } catch {
            WireLogger.proteus.error("Cannot fetch local fingerprint")
            return nil
        }
    }

    func fetchRemoteFingerprint(for userClient: UserClient) async -> Data? {
        guard let sessionId = await context.perform({ userClient.proteusSessionID }) else {
            return nil
        }

        do {
            let fingerprint = try await proteusService.remoteFingerprint(forSession: sessionId)
            return fingerprint.utf8Data
        } catch {
            WireLogger.proteus.error("Cannot fetch remote fingerprint for \(userClient)")
            return nil
        }
    }
}
