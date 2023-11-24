////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public class GetUserClientFingerprintUseCase {

    let proteusProvider: ProteusProviding
    let context: NSManagedObjectContext
    let sessionEstablisher: SessionEstablisherInterface

    // MARK: - Initialization

    convenience init(syncContext: NSManagedObjectContext,
                     transportSession: TransportSessionType) {
        let httpClient = HttpClientImpl(
            transportSession: transportSession,
            queue: syncContext)
        let apiProvider = APIProvider(httpClient: httpClient)
        let sessionEstablisher = SessionEstablisher(
            context: syncContext,
            apiProvider: apiProvider)
        let proteusProvider = ProteusProvider(context: syncContext)

        self.init(proteusProvider: proteusProvider, sessionEstablisher: sessionEstablisher, managedObjectContext: syncContext)
    }

    init(proteusProvider: ProteusProviding,
         sessionEstablisher: SessionEstablisherInterface,
         managedObjectContext: NSManagedObjectContext) {
        self.proteusProvider = proteusProvider
        self.context = managedObjectContext
        self.sessionEstablisher = sessionEstablisher
    }

    // MARK: - Methods

    public func invoke(userClient: UserClient) async -> Data? {
        let objectId = userClient.objectID

        var existingUser: UserClient?
        var shouldEstablishSession = false
        var clientIds = Set<QualifiedClientID>()

        await self.context.perform {
            existingUser = try? self.context.existingObject(with: objectId) as? UserClient
            shouldEstablishSession = existingUser?.hasSessionWithSelfClient == false
            if let id = existingUser?.qualifiedClientID {
                clientIds.insert(id)
            }
        }

        if shouldEstablishSession {
            if let apiVersion = BackendInfo.apiVersion {
                do {
                    try await sessionEstablisher.establishSession(with: clientIds, apiVersion: apiVersion)
                } catch {
                    WireLogger.proteus.error("cannot establishSession while getting fingerprint: \(error)")
                }
            } else {
                WireLogger.backend.warn("apiVersion not resolved, cannot establishSession")
            }
        }

        guard let existingUser else { return nil }

        let isSelfClient = await context.perform { 
            existingUser.isSelfClient() 
        }

        let canPerform  = await context.perform {
            self.proteusProvider.canPerform
        }

        guard canPerform else {
            WireLogger.proteus.error("cannot get localFingerprint, proteusProvider not ready")
            return nil
        }

        if isSelfClient {
            return await localFingerprint()
        } else {
            return await fetchRemoteFingerprint(for: existingUser)
        }
    }

    func localFingerprint() async -> Data? {
        var fingerprintData: Data?

        proteusPerform(
            withProteusService: { proteusService in
                do {
                    let fingerprint = try proteusService.localFingerprint()
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

        proteusPerform(
            withProteusService: { proteusService in
                do {
                    let fingerprint = try proteusService.remoteFingerprint(forSession: sessionId)
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
        withProteusService proteusServiceBlock: ProteusServicePerformBlock<T>,
        withKeyStore keyStoreBlock: KeyStorePerformBlock<T>
    ) rethrows -> T {
        return try context.performAndWait {
            try proteusProvider.perform(withProteusService: proteusServiceBlock, withKeyStore: keyStoreBlock)
        }
    }
}
