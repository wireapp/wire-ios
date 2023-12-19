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
import WireUtilities
import WireTransport

public protocol ProteusToMLSMigrationCoordinating {
    func updateMigrationStatus() async throws
}

public class ProteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating {

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

        enum CannotStartMigrationReason {
            case unsupportedAPIVersion
            case mlsProtocolIsNotSupported
            case clientDoesntSupportMLS
            case backendDoesntSupportMLS
            case mlsMigrationIsNotEnabled
            case startTimeHasNotBeenReached
        }
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let featureRepository: FeatureRepositoryInterface
    private let actionsProvider: MLSActionsProviderProtocol
    private var storage: ProteusToMLSMigrationStorageInterface
    private let logger = WireLogger.mls

    lazy var migrationForceTimeHasArrived: Bool = {
        let mlsMigrationFeature = featureRepository.fetchMLSMigration()
        guard let finaliseDate = mlsMigrationFeature.config.finaliseRegardlessAfter else {
            return false
        }

        return finaliseDate.isPast
    }()

    // MARK: - Life cycle

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

    // MARK: - Public Interface

    public func updateMigrationStatus() async throws {
        switch storage.migrationStatus {
        case .notStarted:
            try await startMigrationIfNeeded()
        case .started:
            try await migrateOrJoinGroupConversations()
            try await finalizeMigrationIfNeeded()
        default:
            break
        }
    }

    // MARK: - Internal Methods

    private func startMigrationIfNeeded() async throws {
        logger.info("checking if proteus-to-mls migration can start")
        let migrationStartStatus = await resolveMigrationStartStatus()

        switch migrationStartStatus {
        case .canStart:
            guard let mlsService = context.mlsService else {
                return logger.warn("can't start migration: missing `mlsService`")
            }

            logger.info("starting proteus-to-mls migration")
            try await mlsService.startProteusToMLSMigration()
            storage.migrationStatus = .started
        case .cannotStart(reason: let reason):
            logger.info("proteus-to-mls migration can't start (reason: \(reason))")
        }
    }

    private func finalizeMigrationIfNeeded() async throws {
        let tuples = try await fetchMixedConversations()
        if !migrationForceTimeHasArrived { try await syncUsersWithTheBackend() }

        for tuple in tuples {
            await finalizeConversationMigration(conversation: tuple.conversation)
        }
    }

    private func syncUsersWithTheBackend() async throws {
        let fetchRequest = ZMUser.fetchRequest()
        guard let users = try context.fetch(fetchRequest) as? [ZMUser] else { return }
        let qualifiedIDs = users.compactMap { $0.qualifiedID }
        try await actionsProvider.syncUsers(qualifiedIDs: ids, context: context.notificationContext)
    }

    // This method is for [iOS] Finalise migration for conversation - WPB-542
    // which is going to be implemented in the next PR
    func finalizeConversationMigration(conversation: ZMConversation) async {

    }

    func canConversationBeFinalised (conversation: ZMConversation) -> Bool {
        return conversation.localParticipants.allSatisfy { $0.supportedProtocols.contains(.mls) }
    }

    func resolveMigrationStartStatus() async -> MigrationStartStatus {
        let features = await fetchFeatures()

        if (BackendInfo.apiVersion ?? .v0) < .v5 {
            return .cannotStart(reason: .unsupportedAPIVersion)
        }

        if !features.mls.config.supportedProtocols.contains(.mls) {
            return .cannotStart(reason: .mlsProtocolIsNotSupported)
        }

        if !DeveloperFlag.enableMLSSupport.isOn {
            return .cannotStart(reason: .clientDoesntSupportMLS)
        }

        if await !isMLSEnabledOnBackend() {
            return .cannotStart(reason: .backendDoesntSupportMLS)
        }

        if features.mlsMigration.status == .disabled {
            return .cannotStart(reason: .mlsMigrationIsNotEnabled)
        }

        if features.mlsMigration.config.startTime > .now {
            return .cannotStart(reason: .startTimeHasNotBeenReached)
        }

        return .canStart
    }

    /// This method is responsible for migrating all `mixed` group conversations to `mls`.
    /// It evaluates each conversation to determine if the migration needs to be finalized (i.e: updating the protocol from `mixed` to `mls`)
    /// or if it should first join the corresponding MLS group.
    func migrateOrJoinGroupConversations() async throws {

        let tuples = try await fetchMixedConversations()

        let mlsService = await context.perform { self.context.mlsService }

        guard let mlsService else {
            return logger.warn("can't migrate conversations to mls: missing `mlsService`")
        }

        for tuple in tuples {
            do {
                if mlsService.conversationExists(groupID: tuple.groupID) {
                    await finalizeConversationMigration(conversation: tuple.conversation)
                } else {
                    try await mlsService.joinGroup(with: tuple.groupID)
                }

            } catch {
                logger.warn("Can't migrate conversation with group id \(tuple.groupID.safeForLoggingDescription) to mls: \(String(describing: error))")
            }
        }

    }

    typealias GroupIDConversationTuple = (groupID: MLSGroupID, conversation: ZMConversation)

    private func fetchMixedConversations() async throws -> [GroupIDConversationTuple] {
        return try await context.perform { [self] in

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

    // MARK: - Helpers

    private func fetchFeatures() async -> (mls: Feature.MLS, mlsMigration: Feature.MLSMigration) {
        return await context.perform { [featureRepository] in
            let mlsFeature = featureRepository.fetchMLS()
            let mlsMigrationFeature = featureRepository.fetchMLSMigration()
            return (mls: mlsFeature, mlsMigration: mlsMigrationFeature)
        }
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

}

extension ZMUser {
    var supportedProtocols: [MessageProtocol] {
        return [.mls, .proteus]
    }
}
