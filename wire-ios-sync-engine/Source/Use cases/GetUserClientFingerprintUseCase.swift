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
import WireRequestStrategy

// MARK: - GetUserClientFingerprintUseCaseProtocol

// sourcery: AutoMockable
public protocol GetUserClientFingerprintUseCaseProtocol {
    func invoke(userClient: UserClient) async -> Data?
}

// MARK: - GetUserClientFingerprintUseCase

public struct GetUserClientFingerprintUseCase: GetUserClientFingerprintUseCaseProtocol {
    let proteusProvider: ProteusProviding
    let context: NSManagedObjectContext
    let sessionEstablisher: SessionEstablisherInterface

    // MARK: - Initialization

    init(
        syncContext: NSManagedObjectContext,
        transportSession: TransportSessionType,
        proteusProvider: ProteusProviding
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
            proteusProvider: proteusProvider,
            sessionEstablisher: sessionEstablisher,
            managedObjectContext: syncContext
        )
    }

    init(
        proteusProvider: ProteusProviding,
        sessionEstablisher: SessionEstablisherInterface,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.proteusProvider = proteusProvider
        self.context = managedObjectContext
        self.sessionEstablisher = sessionEstablisher
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
            if let apiVersion = BackendInfo.apiVersion {
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

        let canPerform = await context.perform {
            proteusProvider.canPerform
        }

        guard canPerform else {
            WireLogger.proteus.error("cannot get localFingerprint, proteusProvider not ready")
            return nil
        }

        if isSelfClient {
            return await localFingerprint()
        } else {
            return await fetchRemoteFingerprint(for: existingClient)
        }
    }

    func localFingerprint() async -> Data? {
        var fingerprintData: Data?

        await proteusPerform(
            withProteusService: { proteusService in
                do {
                    let fingerprint = try await proteusService.localFingerprint()
                    fingerprintData = fingerprint.utf8Data
                } catch {
                    WireLogger.proteus.error("Cannot fetch local fingerprint")
                }
            },
            withKeyStore: { keyStore in
                keyStore.encryptionContext.perform { sessionsDirectory in
                    fingerprintData = sessionsDirectory.localFingerprint
                }
            }
        )
        return fingerprintData
    }

    func fetchRemoteFingerprint(for userClient: UserClient) async -> Data? {
        guard let sessionId = await context.perform({ userClient.proteusSessionID }) else {
            return nil
        }

        var fingerprintData: Data?

        await proteusPerform(
            withProteusService: { proteusService in
                do {
                    let fingerprint = try await proteusService.remoteFingerprint(forSession: sessionId)
                    fingerprintData = fingerprint.utf8Data
                } catch {
                    WireLogger.proteus.error("Cannot fetch remote fingerprint for \(userClient)")
                }
            },
            withKeyStore: { keyStore in
                keyStore.encryptionContext.perform { sessionsDirectory in
                    fingerprintData = sessionsDirectory.fingerprint(for: sessionId.mapToEncryptionSessionID())
                }
            }
        )

        return fingerprintData
    }

    // MARK: - Helpers

    private func proteusPerform<T>(
        withProteusService proteusServiceBlock: @escaping ProteusServicePerformAsyncBlock<T>,
        withKeyStore keyStoreBlock: @escaping KeyStorePerformAsyncBlock<T>
    ) async rethrows -> T {
        try await proteusProvider.performAsync(
            withProteusService: proteusServiceBlock,
            withKeyStore: keyStoreBlock
        )
    }
}
