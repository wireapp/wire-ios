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
    let managedObjectContext: NSManagedObjectContext
    let messageSender: MessageSender

    public static func create(for managedObjectContext: NSManagedObjectContext) -> GetUserClientFingerprintUseCase {
        let proteusProvider = ProteusProvider(context: managedObjectContext)

        return GetUserClientFingerprintUseCase(proteusProvider: proteusProvider, messageSender: MessageSender(httpClient: <#T##HttpClient#>, clientRegistrationDelegate: <#T##ClientRegistrationDelegate#>, sessionEstablisher: <#T##SessionEstablisher#>, context: <#T##NSManagedObjectContext#>), managedObjectContext: managedObjectContext)
    }

    init(proteusProvider: ProteusProviding,
         messageSender: MessageSender,
         managedObjectContext: NSManagedObjectContext) {
        self.proteusProvider = proteusProvider
        self.managedObjectContext = managedObjectContext
        self.messageSender = messageSender
    }

    public func invoke(userClient: UserClient) async -> Data? {
        let objectId = userClient.objectID

        let isSelfClient: Bool = managedObjectContext.performAndWait {
            guard let existingUserId = try? managedObjectContext.existingObject(with: objectId) as? UserClient else {
                return false
            }
            return existingUserId.isSelfClient()
        }

//        if !userClient.hasSessionWithSelfClient {
//            //
//            .establishSessionWithClient(<#T##client: UserClient##UserClient#>, usingPreKey: <#T##String#>)
//                           syncSelfClient.missesClient(syncClient)
//                           syncSelfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
//                           syncMOC.saveOrRollback()
//                       }

        if isSelfClient {
            return await localFingerprint()
        } else {
            return await fetchRemoteFingerprint(for: userClient)
        }
    }

    func localFingerprint() async -> Data? {
        var canPerform: Bool = false

        managedObjectContext.performAndWait {
            canPerform = proteusProvider.canPerform
        }
        guard canPerform else {
            return nil
        }
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
        let userClientObjectId = userClient.objectID
        var userClientToUpdate: UserClient?
        var sessionId: ProteusSessionID?

        managedObjectContext.performAndWait {
            userClientToUpdate = managedObjectContext.object(with: userClientObjectId) as? UserClient
            if proteusProvider.canPerform {
                sessionId = userClientToUpdate?.proteusSessionID
            }
        }

        guard let sessionID = sessionId
        else {
            return nil
        }

        var fingerprintData: Data?

        proteusPerform(
            withProteusService: { proteusService in
                do {
                    let fingerprint = try proteusService.remoteFingerprint(forSession: sessionID)
                    fingerprintData = fingerprint.utf8Data
                } catch {
                    WireLogger.proteus.error("Cannot fetch remote fingerprint for \(userClient)")
                }
            },
            withKeyStore: { keyStore in
                keyStore.encryptionContext.perform { sessionsDirectory in
                    fingerprintData = sessionsDirectory.fingerprint(for: sessionID.mapToEncryptionSessionID())
                }
            }
        )

        return fingerprintData
    }

    private func proteusPerform<T>(
        withProteusService proteusServiceBlock: ProteusServicePerformBlock<T>,
        withKeyStore keyStoreBlock: KeyStorePerformBlock<T>
    ) rethrows -> T {
        return try managedObjectContext.performAndWait {
            try proteusProvider.perform(withProteusService: proteusServiceBlock, withKeyStore: keyStoreBlock)
        }
    }
}
