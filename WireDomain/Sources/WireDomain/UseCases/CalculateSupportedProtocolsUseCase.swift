//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireDataModel
import WireLogging
import WireNetwork
import WireSystem

// sourcery: AutoMockable
/// Calculates the supported protocols.
public protocol CalculateSupportedProtocolsUseCaseProtocol {
    func invoke() async -> Set<WireNetwork.MessageProtocol>
}

public struct CalculateSupportedProtocolsUseCase: CalculateSupportedProtocolsUseCaseProtocol {

    private enum ProteusToMLSMigrationState: String {
        case disabled
        case notStarted
        case ongoing
        case finalised
    }

    let featureConfigRepository: any FeatureConfigRepositoryProtocol
    let userClientsLocalStore: any UserClientsLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol

    private let logger = WireLogger(tag: "supported-protocols")

    public func invoke() async -> Set<WireNetwork.MessageProtocol> {
        await calculateSupportedProtocols()
    }

    private func calculateSupportedProtocols() async -> Set<WireNetwork.MessageProtocol> {
        logger.debug("calculating supported protocols...")

        let remoteProtocols = await remotelySupportedProtocols()
        let migrationState = await currentMigrationState()
        let allClientsMLSReady = await userClientsLocalStore.allSelfUserClientsAreActiveMLSClients()
        let currentSelfUserSupportedProtocols = await userLocalStore.fetchSelfUserSupportedProtocols()

        logger.debug(
            "remote protocols: \(remoteProtocols), migration state: \(migrationState), allClientsMLSReady: \(allClientsMLSReady), currentSelfUserSupportedProtocols: \(currentSelfUserSupportedProtocols)"
        )

        var result = Set<WireNetwork.MessageProtocol>()

        /// All clients are proteus ready so we support it if the backend does.
        if remoteProtocols.contains(.proteus) {
            result.insert(.proteus)
        }

        /// We support mls if the backend does and all MLS clients are ready.
        if remoteProtocols.contains(.mls), allClientsMLSReady {
            result.insert(.mls)
        }

        /// Proteus is still supported if migration is pending or still ongoing.
        if migrationState.isOne(of: .notStarted, .ongoing), allClientsMLSReady {
            result.insert(.proteus)
        }

        /// MLS migration is complete.
        if remoteProtocols.contains(.mls), migrationState == .finalised {
            result.insert(.mls)
        }

        /// MLS is forced.
        if remoteProtocols == [.mls], migrationState.isOne(of: .disabled, .finalised) {
            result = [.mls]
        }

        /// Even if proteus isn't supported, migration is pending or still ongoing.
        if remoteProtocols == [.mls], !allClientsMLSReady, migrationState.isOne(of: .notStarted, .ongoing) {
            result = [.proteus]
        }

        // SelfUser supports mls (other client) at the moment, so we should not remove it
        if currentSelfUserSupportedProtocols.contains(.mls) {
            result.insert(.mls)
        }

        logger.debug("calculated supported protocols: \(result)")

        return result
    }

    private func remotelySupportedProtocols() async -> Set<WireNetwork.MessageProtocol> {
        let mlsFeature = try? await featureConfigRepository.fetchMLSConfig()

        let mls = (
            status: mlsFeature?.status ?? .disabled,
            config: mlsFeature?.config ?? Feature.MLS.Config()
        )

        guard mls.status == .enabled else {
            /// If there is no MLS then there can only be proteus.
            return [.proteus]
        }

        var result = Set<WireNetwork.MessageProtocol>()

        if mls.config.supportedProtocols.contains(.proteus) {
            result.insert(.proteus)
        }

        if mls.config.supportedProtocols.contains(.mls) {
            result.insert(.mls)
        }

        return result
    }

    private func currentMigrationState() async -> ProteusToMLSMigrationState {
        let mlsMigrationFeature = try? await featureConfigRepository.fetchMLSMigrationConfig()

        let mlsMigration = (
            status: mlsMigrationFeature?.status ?? .disabled,
            config: mlsMigrationFeature?.config ?? Feature.MLSMigration.Config()
        )

        guard mlsMigration.status == .enabled else {
            return .disabled
        }

        let now = Date.now

        guard
            let startDate = mlsMigration.config.startTime,
            startDate <= now
        else {
            return .notStarted
        }

        guard
            let endDate = mlsMigration.config.finaliseRegardlessAfter,
            endDate <= now
        else {
            return .ongoing
        }

        return .finalised
    }

}
