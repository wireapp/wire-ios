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
            let factory = CoreCryptoFactory()

            do {
                let configuration = try factory.createConfiguration(
                    sharedContainerURL: sharedContainerURL,
                    selfUser: .selfUser(in: syncContext)
                )

                let coreCrypto = try syncContext.coreCrypto ?? SafeCoreCrypto(coreCryptoConfiguration: configuration)
                syncContext.coreCrypto = coreCrypto

                try createProteusServiceIfNeeded(coreCrypto: coreCrypto)

                try createMLSControllerIfNeeded(
                    coreCrypto: coreCrypto,
                    clientID: configuration.clientID
                )
            } catch let error as MLSControllerSetupFailure {
                WireLogger.coreCrypto.error("fail: setup MLSController: \(String(describing: error))")
            } catch {
                WireLogger.coreCrypto.error("fail: setup crypto stack: \(String(describing: error))")
            }

            WireLogger.coreCrypto.info("success: setup crypto stack")
        }
    }

    // MARK: - Proteus

    private func createProteusServiceIfNeeded(coreCrypto: SafeCoreCryptoProtocol) throws {
        guard DeveloperFlag.proteusViaCoreCrypto.isOn, syncContext.proteusService == nil else { return }
        syncContext.proteusService = try ProteusService(coreCrypto: coreCrypto)
    }

    // MARK: - MLS

    private func createMLSControllerIfNeeded(
        coreCrypto: SafeCoreCryptoProtocol,
        clientID: String
    ) throws {
        guard syncContext.mlsController == nil else { return }

        guard let syncStatus = syncStatus else {
            throw MLSControllerSetupFailure.missingSyncStatus
        }

        guard let userDefaults = UserDefaults(suiteName: "com.wire.mls.\(clientID)") else {
            throw MLSControllerSetupFailure.invalidUserDefaults
        }

        syncContext.mlsController = MLSController(
            context: syncContext,
            coreCrypto: coreCrypto,
            conversationEventProcessor: ConversationEventProcessor(context: syncContext),
            userDefaults: userDefaults,
            syncStatus: syncStatus
        )
    }

    private enum MLSControllerSetupFailure: Error {
        case missingSyncStatus
        case invalidUserDefaults
    }

}
