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

    func setupCryptoStack() {
        syncContext.performAndWait {
            // The factory will create the config, core crypto, proteus service, and mls service.
            let factory = CoreCryptoFactory()

            do {
                // Create the config.
                let configuration = try factory.configuration(
                    sharedContainerURL: sharedContainerURL,
                    syncContext: syncContext
                )

                // Create core crypto.
                syncContext.coreCrypto = try factory.coreCrypto(configuration: configuration)

                // Create proteus service.


                // Create mls controller
                if syncContext.mlsController == nil {
                    guard let syncStatus = syncStatus else {
                        Logging.mls.warn("fail: setup MLSController: no sync status available")
                        return
                    }

                    syncContext.initializeMLSController(
                        coreCrypto: coreCrypto,
                        conversationEventProcessor: ConversationEventProcessor(context: syncContext),
                        userDefaults: UserDefaults(suiteName: "com.wire.mls.\(clientID)")!,
                        syncStatus: syncStatus
                    )
                }

                Logging.coreCrypto.info("success: setup crypto stack")
            } catch {
                Logging.coreCrypto.error("fail: setup crypto stack: \(String(describing: error))")
            }
        }
    }

}
