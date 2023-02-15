//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireRequestStrategy
import CoreCryptoSwift

extension ZMUserSession {

    func setupMLSControllerIfNeeded() {
        guard !isMLSControllerInitialized else {
            return
        }

        guard let syncStatus = syncStatus else {
            Logging.mls.warn("Failed to setup MLSController: no sync status available")
            return
        }

        syncContext.performAndWait {
            do {
                let factory = CoreCryptoFactory()
                let configuration = try factory.configuration(
                    sharedContainerURL: sharedContainerURL,
                    syncContext: syncContext
                )

                let coreCrypto = try factory.coreCrypto(configuration: configuration)

                initializeMLSController(
                    coreCrypto: coreCrypto,
                    clientID: configuration.clientId,
                    syncStatus: syncStatus
                )
            } catch {
                Logging.mls.warn("Failed to setup MLSController: \(String(describing: error))")
            }
        }
    }

    private var isMLSControllerInitialized: Bool {
        var result = false

        syncContext.performAndWait {
            result = syncContext.isMLSControllerInitialized
        }

        return result
    }

    private func initializeMLSController(
        coreCrypto: CoreCryptoProtocol,
        clientID: String,
        syncStatus: SyncStatusProtocol
    ) {
        syncContext.performAndWait {
            syncContext.initializeMLSController(
                coreCrypto: coreCrypto,
                conversationEventProcessor: ConversationEventProcessor(context: syncContext),
                userDefaults: UserDefaults(suiteName: "com.wire.mls.\(clientID)")!,
                syncStatus: syncStatus
            )
        }
    }
}
