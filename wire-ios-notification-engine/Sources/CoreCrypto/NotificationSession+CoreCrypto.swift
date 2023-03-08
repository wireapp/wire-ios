//
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
import WireDataModel
import WireUtilities

extension NotificationSession {

    func setUpCoreCryptoStack(
        sharedContainerURL: URL,
        syncContext: NSManagedObjectContext
    ) {
        guard shouldSetupCryptoStack else {
            WireLogger.coreCrypto.info("not setting up core crypto stack because it is not needed")
            return
        }

        syncContext.performAndWait {
            let provider = CoreCryptoConfigProvider()

            do {
                let configuration = try provider.createFullConfiguration(
                    sharedContainerURL: sharedContainerURL,
                    selfUser: .selfUser(in: syncContext)
                )

                let safeCoreCrypto = try SafeCoreCrypto(coreCryptoConfiguration: configuration)

                syncContext.coreCrypto = safeCoreCrypto

                if DeveloperFlag.proteusViaCoreCrypto.isOn, syncContext.proteusService == nil {
                    syncContext.proteusService = try ProteusService(coreCrypto: safeCoreCrypto)
                }

                if DeveloperFlag.enableMLSSupport.isOn, syncContext.mlsController == nil {
                    syncContext.mlsController = MLSDecryptionController(
                        context: syncContext,
                        coreCrypto: safeCoreCrypto
                    )
                }
            } catch {
                WireLogger.coreCrypto.error("fail: setup crypto stack: \(String(describing: error))")
            }

            WireLogger.coreCrypto.info("success: setup crypto stack")
        }
    }

    private var shouldSetupCryptoStack: Bool {
        return DeveloperFlag.proteusViaCoreCrypto.isOn || DeveloperFlag.enableMLSSupport.isOn
    }

}
