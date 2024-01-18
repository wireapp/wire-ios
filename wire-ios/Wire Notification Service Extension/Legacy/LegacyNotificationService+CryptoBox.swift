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

extension LegacyNotificationService {

    // MARK: Configuration

    struct CryptoSetupConfiguration {
        let shouldSetupProteusService: Bool
        let shouldSetupMLSService: Bool

        init() {
            self.init(
                shouldSetupProteusService: DeveloperFlag.proteusViaCoreCrypto.isOn,
                shouldSetupMLSService: DeveloperFlag.enableMLSSupport.isOn && (BackendInfo.apiVersion ?? .v0) >= .v5
            )
        }

        init(shouldSetupProteusService: Bool, shouldSetupMLSService: Bool) {
            self.shouldSetupProteusService = shouldSetupProteusService
            self.shouldSetupMLSService = shouldSetupMLSService
        }
    }

    // MARK: Methods

    func setUpCoreCryptoStack(
        provider: CoreCryptoProviderProtocol,
        syncContext: NSManagedObjectContext,
        configuration: CryptoSetupConfiguration = CryptoSetupConfiguration()
    ) {
        if configuration.shouldSetupProteusService, syncContext.proteusService == nil {
            syncContext.proteusService = ProteusService(coreCryptoProvider: provider)
        }

        if configuration.shouldSetupMLSService, syncContext.mlsDecryptionService == nil {
            let commitSender = CommitSender(
                coreCryptoProvider: provider,
                notificationContext: syncContext.notificationContext
            )
            let mlsActionExecutor = MLSActionExecutor(
                coreCryptoProvider: provider,
                commitSender: commitSender
            )

            syncContext.mlsDecryptionService = MLSDecryptionService(
                context: syncContext,
                mlsActionExecutor: mlsActionExecutor
            )
        }
    }
}
