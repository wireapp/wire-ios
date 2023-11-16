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

class MessagingService {

    let proteusProvider: ProteusProvider
    let mlsService: MLSServiceInterface?
    let managedObjectContext: NSManagedObjectContext

    init(proteusProvider: ProteusProvider, mlsService: MLSServiceInterface?, managedObjectContext: NSManagedObjectContext) {
        self.proteusProvider = proteusProvider
        self.mlsService = mlsService
        self.managedObjectContext = managedObjectContext
    }

    func proteusPerform<T>(
        withProteusService proteusServiceBlock: ProteusServicePerformBlock<T>,
        withKeyStore keyStoreBlock: KeyStorePerformBlock<T>
    ) rethrows -> T {
        return try managedObjectContext.performAndWait {
            try proteusProvider.perform(withProteusService: proteusServiceBlock, withKeyStore: keyStoreBlock)
        }
    }
}

public class FingerprintUseCase {

    let messagingService: MessagingService

    private let queue = OperationQueue()
    private var token: NSObjectProtocol?

    // FIXME: CC - temp method for dep injection
    public static func create(for managedObjectContext: NSManagedObjectContext) -> FingerprintUseCase {
        let proteusProvider = ProteusProvider(context: managedObjectContext)

        return FingerprintUseCase(messagingService: MessagingService(proteusProvider: proteusProvider,
                                                                     mlsService: nil, // on develop we should not have mlsService,
                                                                     managedObjectContext: managedObjectContext))
    }

    init(messagingService: MessagingService) {
        self.messagingService = messagingService
    }

    /*

     public override func awakeFromFetch() {
         super.awakeFromFetch()

         // Fetch fingerprint if not there yet (could remain nil after fetch)
         if let managedObjectContext = self.managedObjectContext,
            self.remoteIdentifier != nil, managedObjectContext.zm_isSyncContext && self.fingerprint == .none {
             self.fingerprint = self.remoteFingerprint()
         }
     }

     func localFingerprint(_ proteusProvider: ProteusProviding? = nil) -> Data? {
         guard
             let proteusProvider = proteusProvider ?? managedObjectContext?.proteusProvider,
             proteusProvider.canPerform
         else {
             return nil
         }

         var fingerprintData: Data?

         proteusProvider.perform(
             withProteusService: { proteusService in
                 do {
                     let fingerprint = try proteusService.localFingerprint()
                     fingerprintData = fingerprint.utf8Data
                 } catch {
                     zmLog.error("Cannot fetch local fingerprint for \(self)")
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

     */

    public func fetchRemoteFingerprint(for userClient: UserClient) async -> Data? {
        let userClientObjectId = userClient.objectID
        var userClientToUpdate: UserClient?
        var sessionId: ProteusSessionID?

        messagingService.managedObjectContext.performAndWait {
            userClientToUpdate = messagingService.managedObjectContext.object(with: userClientObjectId) as? UserClient
            if messagingService.proteusProvider.canPerform {
                sessionId = userClientToUpdate?.proteusSessionID
            }
        }

        guard let sessionID = sessionId
        else {
            return nil
        }

        var fingerprintData: Data?

        messagingService.proteusPerform(
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
}
