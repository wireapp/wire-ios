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

    enum CryptoStackSetupStage {
        case proteus
        case mls
    }

    func setupCryptoStack(stage: CryptoStackSetupStage) {
        switch stage {
        case .proteus:
            setupProteus()
        case .mls:
            setupMLS()
        }
    }

    private func setupProteus() {
        syncContext.performAndWait {
            let provider = CoreCryptoConfigProvider()

            do {
                let configuration = try provider.createInitialConfiguration(
                    sharedContainerURL: sharedContainerURL,
                    selfUser: .selfUser(in: syncContext)
                )
                let coreCrypto = try SafeCoreCrypto(
                    path: configuration.path,
                    key: configuration.key
                )
                syncContext.coreCrypto = coreCrypto
                try createProteusServiceIfNeeded(coreCrypto: coreCrypto)
            } catch {
                WireLogger.coreCrypto.error("fail: setup crypto stack (proteus): \(String(describing: error))")
            }

            WireLogger.coreCrypto.info("success: setup crypto stack (proteus)")
        }
    }

    private func setupMLS() {
        syncContext.performAndWait {
            let provider = CoreCryptoConfigProvider()

            do {
                guard let coreCrypto = syncContext.coreCrypto else {
                    throw CryptoStackSetupError.missingCoreCrypto
                }

                let clientID = try provider.clientID(of: .selfUser(in: syncContext))
                try coreCrypto.mlsInit(clientID: clientID)
                try createMLSControllerIfNeeded(coreCrypto: coreCrypto, clientID: clientID)

            } catch let error as MLSControllerSetupFailure {
                WireLogger.coreCrypto.error("fail: setup MLSController: \(String(describing: error))")
            } catch {
                WireLogger.coreCrypto.error("fail: setup crypto stack (mls): \(String(describing: error))")
            }

            WireLogger.coreCrypto.info("success: setup crypto stack (mls)")
        }
    }

    private enum CryptoStackSetupError: Error {
        case missingCoreCrypto
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
        // TODO: check if MLS flag is on
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
