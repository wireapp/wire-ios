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

    public func fetchRemoteFingerprint(for userClient: UserClient) async -> Data? {
        let userClientObjectId = userClient.objectID
        var userClientToUpdate: UserClient?
        var sessionId: ProteusSessionID?

        messagingService.managedObjectContext.performAndWait {
            userClientToUpdate = messagingService.managedObjectContext.object(with: userClientObjectId) as? UserClient
            sessionId = userClientToUpdate?.proteusSessionID
        }

        guard messagingService.proteusProvider.canPerform,
              let sessionID = sessionId
        else {
            return nil
        }

        var fingerprintData: Data?

        messagingService.proteusProvider.perform(
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
