//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireAPI
import WireDataModel
import WireSystem

/// Calculates and pushes the supported protocols to the backend
public struct PushSupportedProtocolsUseCase {

    private enum ProteusToMLSMigrationState: String {
        case disabled
        case notStarted
        case ongoing
        case finalised
    }

    let featureConfigRepository: any FeatureConfigRepositoryProtocol
    let userRepository: any UserRepositoryProtocol

    private let logger = WireLogger(tag: "supported-protocols")

    public func invoke() async throws {
        let supportedProtocols = await calculateSupportedProtocols()
        try await userRepository.pushSelfSupportedProtocols(supportedProtocols)
    }

    private func calculateSupportedProtocols() async -> Set<WireAPI.MessageProtocol> {
        logger.debug("calculating supported protocols...")

        let remoteProtocols = await remotelySupportedProtocols()
        let migrationState = await currentMigrationState()
        let allClientsMLSReady = allSelfUserClientsAreActiveMLSClients()

        logger.debug(
            "remote protocols: \(remoteProtocols), migration state: \(migrationState), allClientsMLSReady: \(allClientsMLSReady)"
        )

        var result = Set<WireAPI.MessageProtocol>()

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

        logger.debug("calculated supported protocols: \(result)")

        return result
    }

    private func remotelySupportedProtocols() async -> Set<WireAPI.MessageProtocol> {
        let mlsFeature = try? await featureConfigRepository.fetchFeatureConfig(
            with: .mls,
            type: Feature.MLS.Config.self
        )

        let mls = (status: mlsFeature?.status ?? .disabled,
                   config: mlsFeature?.config ?? Feature.MLS.Config())

        guard mls.status == .enabled else {
            /// If there is no MLS then there can only be proteus.
            return [.proteus]
        }

        var result = Set<WireAPI.MessageProtocol>()

        if mls.config.supportedProtocols.contains(.proteus) {
            result.insert(.proteus)
        }

        if mls.config.supportedProtocols.contains(.mls) {
            result.insert(.mls)
        }

        return result
    }

    private func currentMigrationState() async -> ProteusToMLSMigrationState {
        let mlsMigrationFeature = try? await featureConfigRepository.fetchFeatureConfig(
            with: .mlsMigration,
            type: Feature.MLSMigration.Config.self
        )

        let mlsMigration = (status: mlsMigrationFeature?.status ?? .disabled,
                            config: mlsMigrationFeature?.config ?? Feature.MLSMigration.Config())

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

    private func allSelfUserClientsAreActiveMLSClients() -> Bool {
        userRepository.fetchSelfUser().clients.all { userClient in
            let hasMLSIdentity = !userClient.mlsPublicKeys.isEmpty

            let isRecentlyActive: Bool = {
                if userClient.isSelfClient() {
                    return true
                }

                guard let lastActiveDate = userClient.lastActiveDate else {
                    return false
                }

                guard lastActiveDate <= Date() else {
                    return true
                }

                return lastActiveDate.timeIntervalSinceNow.magnitude < .fourWeeks
            }()

            return hasMLSIdentity && isRecentlyActive
        }
    }

}
