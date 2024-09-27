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

import Foundation
import WireTransport
import WireUtilities

// MARK: - ProteusToMLSMigrationCoordinating

// sourcery: AutoMockable
public protocol ProteusToMLSMigrationCoordinating {
    /// Updates the migration status of group conversations.
    func updateMigrationStatus() async throws
}

// MARK: - ProteusToMLSMigrationCoordinator

/// A class responsible for migrating group conversations from Proteus to MLS.
/// It will start the migration if the conditions are met and finalise it when the time comes.
///
/// See <doc:MLS-Migration> for more information.

public class ProteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating {
    // MARK: Lifecycle

    public convenience init(
        context: NSManagedObjectContext,
        userID: UUID
    ) {
        self.init(
            context: context,
            storage: ProteusToMLSMigrationStorage(
                userID: userID,
                userDefaults: .standard
            )
        )
    }

    init(
        context: NSManagedObjectContext,
        storage: ProteusToMLSMigrationStorageInterface,
        featureRepository: FeatureRepositoryInterface? = nil,
        actionsProvider: MLSActionsProviderProtocol? = nil
    ) {
        self.context = context
        self.storage = storage
        self.featureRepository = featureRepository ?? FeatureRepository(context: context)
        self.actionsProvider = actionsProvider ?? MLSActionsProvider()
    }

    // MARK: Public

    // MARK: - Public Interface

    public func updateMigrationStatus() async throws {
        switch storage.migrationStatus {
        case .notStarted:
            try await startMigrationIfNeeded()
        case .started:
            try await finaliseMigrationIfNeeded()
        default:
            break
        }
    }

    // MARK: Internal

    // MARK: - Types

    enum MigrationStatus: Int {
        case notStarted
        case started
        case finalising
        case finalised
    }

    enum MigrationStartStatus: Equatable {
        case canStart
        case cannotStart(reason: CannotStartMigrationReason)

        // MARK: Internal

        enum CannotStartMigrationReason {
            case unsupportedAPIVersion
            case mlsProtocolIsNotSupported
            case clientDoesntSupportMLS
            case backendDoesntSupportMLS
            case mlsMigrationIsNotEnabled
            case startTimeHasNotBeenReached
        }
    }

    // MARK: Private

    // MARK: - Helpers (migration finalisation)

    private typealias GroupIDConversationTuple = (groupID: MLSGroupID, conversation: ZMConversation)

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let featureRepository: FeatureRepositoryInterface
    private let actionsProvider: MLSActionsProviderProtocol
    private var storage: ProteusToMLSMigrationStorageInterface

    private let logger = WireLogger.mls

    // MARK: - Migration Start

    private func startMigrationIfNeeded() async throws {
        logger.info("checking if proteus-to-mls migration can start")
        let migrationStartStatus = await resolveMigrationStartStatus()

        switch migrationStartStatus {
        case .canStart:
            guard let mlsService = await context.perform({ self.context.mlsService }) else {
                return logger.warn("can't start migration: missing `mlsService`")
            }

            logger.info("starting proteus-to-mls migration")
            try await mlsService.startProteusToMLSMigration()
            storage.migrationStatus = .started

        case let .cannotStart(reason: reason):
            logger.info("proteus-to-mls migration can't start (reason: \(reason))")
        }
    }

    // MARK: - Migration Finalisation

    private func finaliseMigrationIfNeeded() async throws {
        guard let mlsService = await context.perform({ self.context.mlsService }) else {
            return logger.warn("can't migrate conversations to mls: missing `mlsService`")
        }

        let migrationFinalisationTimeHasArrived = await migrationFinalisationTimeHasArrived()

        // We periodically sync users to refresh their list of supported protocols
        // But if the finalisation time has arrived, we will finish the migration regardless of supported protocols
        if !migrationFinalisationTimeHasArrived {
            try await syncUsersWithTheBackend()
        }

        for (groupID, conversation) in try await fetchMixedConversations() {
            do {
                try await joinMLSGroupIfNeeded(groupID, mlsService: mlsService)

                let allParticipantsSupportMLS = await context
                    .perform { self.allParticipantsSupportMLS(in: conversation) }

                guard migrationFinalisationTimeHasArrived || allParticipantsSupportMLS else {
                    continue
                }

                try await updateConversationProtocolToMLS(for: conversation)
            } catch {
                logger
                    .warn(
                        "failed to migrate conversation (groupID:\(groupID.safeForLoggingDescription), error: \(String(describing: error))"
                    )
                continue
            }
        }
    }

    // MARK: - Helpers (migration start)

    private func resolveMigrationStartStatus() async -> MigrationStartStatus {
        if (BackendInfo.apiVersion ?? .v0) < .v5 {
            return .cannotStart(reason: .unsupportedAPIVersion)
        }

        if !DeveloperFlag.enableMLSSupport.isOn {
            return .cannotStart(reason: .clientDoesntSupportMLS)
        }

        if await !isMLSEnabledOnBackend() {
            return .cannotStart(reason: .backendDoesntSupportMLS)
        }

        let features = await fetchFeatures()

        if !features.mls.config.supportedProtocols.contains(.mls) {
            return .cannotStart(reason: .mlsProtocolIsNotSupported)
        }

        if features.mlsMigration.status == .disabled {
            return .cannotStart(reason: .mlsMigrationIsNotEnabled)
        }

        guard let startTime = features.mlsMigration.config.startTime, startTime.isInThePast else {
            return .cannotStart(reason: .startTimeHasNotBeenReached)
        }

        return .canStart
    }

    private func fetchFeatures() async -> (mls: Feature.MLS, mlsMigration: Feature.MLSMigration) {
        let mlsFeature = await featureRepository.fetchMLS()

        let mlsMigrationFeature = await context.perform { [featureRepository] in
            featureRepository.fetchMLSMigration()
        }

        return (mls: mlsFeature, mlsMigration: mlsMigrationFeature)
    }

    private func isMLSEnabledOnBackend() async -> Bool {
        do {
            _ = try await actionsProvider.fetchBackendPublicKeys(in: context.notificationContext)
            return true
        } catch FetchBackendMLSPublicKeysAction.Failure.mlsNotEnabled {
            return false
        } catch {
            logger.warn("unexpected error fetching public keys: \(String(describing: error))")
            return false
        }
    }

    private func fetchMixedConversations() async throws -> [GroupIDConversationTuple] {
        try await context.perform { [self] in

            let conversations = try ZMConversation.fetchAllTeamGroupConversations(
                messageProtocol: .mixed,
                in: context
            )

            let tuples: [(MLSGroupID, ZMConversation)] = conversations.compactMap {
                guard let groupID = $0.mlsGroupID else {
                    return nil
                }
                return (groupID: groupID, conversation: $0)
            }

            return tuples
        }
    }

    private func joinMLSGroupIfNeeded(_ groupID: MLSGroupID, mlsService: MLSServiceInterface) async throws {
        guard try await !mlsService.conversationExists(groupID: groupID) else { return }
        try await mlsService.joinGroup(with: groupID)
    }

    private func allParticipantsSupportMLS(in conversation: ZMConversation) -> Bool {
        conversation.localParticipants
            .allSatisfy { $0.supportedProtocols.contains(.mls) }
    }

    private func syncUsersWithTheBackend() async throws {
        let fetchRequest = ZMUser.fetchRequest()

        let qualifiedIDs = try await context.perform { [context] in
            let users = try context.fetch(fetchRequest) as? [ZMUser]
            return users?.compactMap(\.qualifiedID)
        }

        guard let qualifiedIDs else { return }

        try await actionsProvider.syncUsers(qualifiedIDs: qualifiedIDs, context: context.notificationContext)
    }

    private func migrationFinalisationTimeHasArrived() async -> Bool {
        let mlsMigrationFeature = await context.perform { [featureRepository] in
            featureRepository.fetchMLSMigration()
        }

        guard let finaliseDate = mlsMigrationFeature.config.finaliseRegardlessAfter else {
            return false
        }

        return finaliseDate.isInThePast
    }

    private func updateConversationProtocolToMLS(for conversation: ZMConversation) async throws {
        let qualifiedID = await context.perform { conversation.qualifiedID }
        guard let qualifiedID else { return }

        try await actionsProvider.updateConversationProtocol(
            qualifiedID: qualifiedID,
            messageProtocol: .mls,
            context: context.notificationContext
        )

        try await actionsProvider.syncConversation(
            qualifiedID: qualifiedID,
            context: context.notificationContext
        )
    }
}
