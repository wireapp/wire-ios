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

protocol SupportedProtocolsServiceInterface {

    func calculateSupportedProtocols() -> Set<MessageProtocol>

}

final class SupportedProtocolsService: SupportedProtocolsServiceInterface {

    // MARK: - Properties

    private let featureRepository: FeatureRepositoryInterface
    private let userRepository: UserRepositoryInterface

    // MARK: - Life cycle

    init(
        featureRepository: FeatureRepositoryInterface,
        userRepository: UserRepositoryInterface
    ) {
        self.featureRepository = featureRepository
        self.userRepository = userRepository
    }

    // MARK: - Methods

    func updateSupportedProtocols() {
        let selfUser = userRepository.selfUser()
        selfUser.supportedProtocols = calculateSupportedProtocols()
    }

    func calculateSupportedProtocols() -> Set<MessageProtocol> {
        let remoteProtocols = remotelySupportedProtocols()
        let migrationState = currentMigrationState()
        let allClientsMLSReady = allSelfUserClientsAreActiveMLSClients()

        var result = Set<MessageProtocol>()

        // All clients are proteus ready so we support it if the backend does.
        if remoteProtocols.contains(.proteus) {
            result.insert(.proteus)
        }

        // All clients are mls ready so we support it if the backend does.
        if remoteProtocols.contains(.mls) && allClientsMLSReady {
            result.insert(.mls)
        }

        // Proteus is still supported if migration is pending or still ongoing.
        if migrationState.isOne(of: .notStarted, .ongoing) && allClientsMLSReady {
            result.insert(.proteus)
        }

        // MLS migration is complete.
        if remoteProtocols.contains(.mls) && migrationState == .finalised {
            result.insert(.mls)
        }

        // MLS is forced.
        if remoteProtocols == [.mls] && migrationState.isOne(of: .disabled, .finalised) {
            result = [.mls]
        }

        // Even if proteus isn't supported, migration is pending or still ongoing.
        if remoteProtocols == [.mls] && !allClientsMLSReady && migrationState.isOne(of: .notStarted, .ongoing) {
            result = [.proteus]
        }

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

    enum ProteusToMLSMigrationState {

        case disabled
        case notStarted
        case ongoing
        case finalised

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
        return userRepository.selfUser().clients.all(\.isActiveMLSClient)
    }

}

private extension UserClient {

    var isActiveMLSClient: Bool {
        return hasMLSIdentity && isRecentlyActive
    }

    var hasMLSIdentity: Bool {
        return mlsPublicKeys.ed25519 != nil
    }

    var isRecentlyActive: Bool {
        guard let lastActiveDate = lastActiveDate else {
            return false
        }

        guard lastActiveDate <= Date() else {
            return true
        }

        return lastActiveDate.timeIntervalSinceNow.magnitude < .fourWeeks
    }

}
