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

import Foundation
import WireDomain
import WireLegacyLogging
import WireRequestStrategy

// sourcery: AutoMockable
public protocol LegacySupportedProtocolsServiceInterface {

    func calculateSupportedProtocols() -> Set<WireDataModel.MessageProtocol>

}

/// Service to calculate the supported protocols
/// - Note: Only used within legacy sync with `ResolveOneOnOneConversationUseCase`
public final class LegacySupportedProtocolsService: LegacySupportedProtocolsServiceInterface {

    // MARK: - Properties

    private let featureRepository: LegacyFeatureRepositoryInterface
    private let selfUserProvider: SelfUserProviderProtocol
    private let logger = WireLogger.supportedProtocols

    // MARK: - Life cycle

    public convenience init(context: NSManagedObjectContext) {
        self.init(
            featureRepository: LegacyFeatureRepository(context: context),
            selfUserProvider: WireDomain.SelfUserProvider(context: context)
        )
    }

    init(
        featureRepository: LegacyFeatureRepositoryInterface,
        selfUserProvider: SelfUserProviderProtocol
    ) {
        self.featureRepository = featureRepository
        self.selfUserProvider = selfUserProvider
    }

    // MARK: - Methods

    public func calculateSupportedProtocols() -> Set<MessageProtocol> {
        logger.debug("calculating supported protocols... - legacy")

        let remoteProtocols = remotelySupportedProtocols()
        let migrationState = currentMigrationState()
        let allClientsMLSReady = allSelfUserClientsAreActiveMLSClients()
        let currentSelfUserSupportedProtocols = selfUserSupportedProtocols()

        logger
            .debug(
                "remote protocols: \(remoteProtocols), migration state: \(migrationState), allClientsMLSReady: \(allClientsMLSReady), currentSelfUserSupportedProtocols: \(currentSelfUserSupportedProtocols) - legacy"
            )

        var result = Set<MessageProtocol>()

        // All clients are proteus ready so we support it if the backend does.
        if remoteProtocols.contains(.proteus) {
            result.insert(.proteus)
        }

        // All clients are mls ready so we support it if the backend does.
        if remoteProtocols.contains(.mls), allClientsMLSReady {
            result.insert(.mls)
        }

        // Proteus is still supported if migration is pending or still ongoing.
        if migrationState.isOne(of: .notStarted, .ongoing), allClientsMLSReady {
            result.insert(.proteus)
        }

        // MLS migration is complete.
        if remoteProtocols.contains(.mls), migrationState == .finalised {
            result.insert(.mls)
        }

        // MLS is forced.
        if remoteProtocols == [.mls], migrationState.isOne(of: .disabled, .finalised) {
            result = [.mls]
        }

        // Even if proteus isn't supported, migration is pending or still ongoing.
        if remoteProtocols == [.mls], !allClientsMLSReady, migrationState.isOne(of: .notStarted, .ongoing) {
            result = [.proteus]
        }

        // SelfUser supports mls (other client) at the moment, so we should not remove it
        if currentSelfUserSupportedProtocols.contains(.mls) {
            result.insert(.mls)
        }

        logger.debug("calculated supported protocols: \(result) - legacy")

        return result
    }

    // MARK: - MLS

    private func remotelySupportedProtocols() -> Set<MessageProtocol> {
        let mls = featureRepository.fetchMLS()

        guard mls.status == .enabled else {
            // If there is no MLS then there can only be proteus.
            return [.proteus]
        }

        var result = Set<MessageProtocol>()

        if mls.config.supportedProtocols.contains(.proteus) {
            result.insert(.proteus)
        }

        if mls.config.supportedProtocols.contains(.mls) {
            result.insert(.mls)
        }

        return result
    }

    private func currentMigrationState() -> ProteusToMLSMigrationState {
        let mlsMigration = featureRepository.fetchMLSMigration()

        guard mlsMigration.status == .enabled else {
            return .disabled
        }

        let now = Date()

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
        selfUserProvider.fetchSelfUser().clients.all(\.isActiveMLSClient)
    }

    private func selfUserSupportedProtocols() -> Set<MessageProtocol> {
        selfUserProvider.fetchSelfUser().supportedProtocols
    }
}

// MARK: -

private extension UserClient {

    var isActiveMLSClient: Bool {
        hasMLSIdentity && isRecentlyActive
    }

    var hasMLSIdentity: Bool {
        !mlsPublicKeys.isEmpty
    }

    var isRecentlyActive: Bool {
        if isSelfClient() {
            return true
        }

        guard let lastActiveDate else {
            return false
        }

        guard lastActiveDate <= Date() else {
            return true
        }

        return lastActiveDate.timeIntervalSinceNow.magnitude < .fourWeeks
    }

}
