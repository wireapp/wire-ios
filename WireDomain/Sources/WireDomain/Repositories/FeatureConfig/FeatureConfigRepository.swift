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

import Combine
import WireAPI
import WireDataModel

/// Facilitates access to feature configs related domain objects.
protocol FeatureConfigRepositoryProtocol {

    /// Pulls feature configs from the server and stores them locally.
    ///

    func pullFeatureConfigs() async throws

    /// Observes feature states.
    ///
    /// Each time `pullFeatureConfigs()` is called, a feature config is
    /// stored locally and a new `FeatureState` value is produced by the publisher.
    /// It allows the user to be notified of any feature changes over time.
    ///
    /// - Warning:  Use this method before calling `pullFeatureConfigs` to receive all emitted values.
    ///
    /// - Returns: A publisher of `FeatureState`.

    func observeFeatureStates() -> AnyPublisher<FeatureState, Never>

    /// Fetches a feature config locally.
    ///
    /// - Parameter name: The feature name to fetch the config for.
    /// - Parameter type: The type of config to retrieve.
    /// - Returns: A `LocalFeature` object with a status and a config (if any).

    func fetchFeatureConfig<T: Decodable>(with name: Feature.Name, type: T.Type) async throws -> LocalFeature<T>

    /// Updates a feature config locally.
    ///
    /// - Parameter featureConfig: The feature config to update.

    func updateFeatureConfig(_ featureConfig: FeatureConfig) async throws

    /// Fetches a flag indicating whether the user should be notified of a given feature.
    /// - Parameter name: The feature name.
    /// - Returns: `true` if user should be notified.

    func fetchNeedsToNotifyUser(for name: Feature.Name) async throws -> Bool

    /// Stores a flag indicating whether the user should be notified of a given feature.
    /// - Parameter notifyUser: Whether the user should be notified for a given feature.
    /// - Parameter name: The name of the feature to set the flag for.

    func storeNeedsToNotifyUser(_ notifyUser: Bool, forFeatureName name: Feature.Name) async throws

}

final class FeatureConfigRepository: FeatureConfigRepositoryProtocol {

    // MARK: - Properties

    private let featureConfigsAPI: any FeatureConfigsAPI
    // swiftlint:disable:next todo_requires_jira_link
    // TODO: create FeatureConfigLocalStore
    private let context: NSManagedObjectContext
    private let logger = WireLogger.featureConfigs
    private let featureStateSubject = PassthroughSubject<FeatureState, Never>()

    // MARK: - Object lifecycle

    init(
        featureConfigsAPI: any FeatureConfigsAPI,
        context: NSManagedObjectContext
    ) {
        self.featureConfigsAPI = featureConfigsAPI
        self.context = context
    }

    // MARK: - Public

    func pullFeatureConfigs() async throws {
        let featureConfigs = try await featureConfigsAPI.getFeatureConfigs()

        for featureConfig in featureConfigs {
            await storeFeatureConfig(featureConfig)
            await sendFeatureState(for: featureConfig)
        }
    }

    func observeFeatureStates() -> AnyPublisher<FeatureState, Never> {
        featureStateSubject.eraseToAnyPublisher()
    }

    func fetchFeatureConfig<T: Decodable>(with name: Feature.Name, type: T.Type) async throws -> LocalFeature<T> {
        try await context.perform { [self] in
            let feature = try fetchFeature(withName: name)

            if let config = feature.config {
                let decoder = JSONDecoder()
                let config = try decoder.decode(type, from: config)

                return LocalFeature(status: feature.status, config: config)
            }

            return LocalFeature(status: feature.status, config: nil)
        }
    }

    func fetchNeedsToNotifyUser(for name: Feature.Name) async throws -> Bool {
        try await context.perform { [self] in
            let feature = try fetchFeature(withName: name)
            return feature.needsToNotifyUser
        }
    }

    func storeNeedsToNotifyUser(_ notifyUser: Bool, forFeatureName name: Feature.Name) async throws {
        try await context.perform { [self] in
            let feature = try fetchFeature(withName: name)
            feature.needsToNotifyUser = notifyUser
        }
    }

    func updateFeatureConfig(_ featureConfig: FeatureConfig) async throws {
        await storeFeatureConfig(featureConfig)
        await sendFeatureState(for: featureConfig)
    }

    // MARK: - Private

    private func sendFeatureState(for featureConfig: FeatureConfig) async {
        guard let featureState = try? await getFeatureState(
            forFeatureConfig: featureConfig
        ) else { return }

        featureStateSubject.send(featureState)
    }

    private func fetchFeature(withName name: Feature.Name) throws -> Feature {
        guard let feature = Feature.fetch(name: name, context: context) else {
            throw FeatureConfigRepositoryError.failedToFetchFeatureLocally
        }

        return feature
    }

    private func getFeatureState(forFeatureConfig config: FeatureConfig) async throws -> FeatureState? {
        switch config {
        case .appLock(let appLockFeatureConfig):

            return FeatureState(
                name: .appLock,
                status: appLockFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .classifiedDomains(let classifiedDomainsFeatureConfig):

            return FeatureState(
                name: .classifiedDomains,
                status: classifiedDomainsFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .conferenceCalling(let conferenceCallingFeatureConfig):

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(for: .conferenceCalling)
            return FeatureState(
                name: .conferenceCalling,
                status: conferenceCallingFeatureConfig.status,
                shouldNotifyUser: needsToNotifyUser
            )

        case .conversationGuestLinks(let conversationGuestLinksFeatureConfig):

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(for: .conversationGuestLinks)
            return FeatureState(
                name: .conversationGuestLinks,
                status: conversationGuestLinksFeatureConfig.status,
                shouldNotifyUser: needsToNotifyUser
            )

        case .digitalSignature(let digitalSignatureFeatureConfig):

            return FeatureState(
                name: .digitalSignature,
                status: digitalSignatureFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .endToEndIdentity(let endToEndIdentityFeatureConfig):

            return FeatureState(
                name: .e2ei,
                status: endToEndIdentityFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .fileSharing(let fileSharingFeatureConfig):

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(for: .fileSharing)
            return FeatureState(
                name: .fileSharing,
                status: fileSharingFeatureConfig.status,
                shouldNotifyUser: needsToNotifyUser
            )

        case .mls(let mlsFeatureConfig):

            return FeatureState(
                name: .mls,
                status: mlsFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .mlsMigration(let mLSMigrationFeatureConfig):

            return FeatureState(
                name: .mlsMigration,
                status: mLSMigrationFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .selfDeletingMessages(let selfDeletingMessagesFeatureConfig):

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(for: .selfDeletingMessages)
            return FeatureState(
                name: .selfDeletingMessages,
                status: selfDeletingMessagesFeatureConfig.status,
                shouldNotifyUser: needsToNotifyUser
            )

        case .unknown(let featureName):
            logger.warn(
                "Unknown feature name: \(featureName)"
            )

            return nil
        }
    }

    private func storeFeatureConfig(_ featureConfig: FeatureConfig) async {
        await context.perform { [self] in

            switch featureConfig {
            case .appLock(let appLockFeatureConfig):

                updateOrCreate(
                    featureName: .appLock,
                    isEnabled: appLockFeatureConfig.status == .enabled,
                    config: appLockFeatureConfig.toDomainModel()
                )

            case .classifiedDomains(let classifiedDomainsFeatureConfig):

                updateOrCreate(
                    featureName: .classifiedDomains,
                    isEnabled: classifiedDomainsFeatureConfig.status == .enabled,
                    config: classifiedDomainsFeatureConfig.toDomainModel()
                )

            case .conferenceCalling(let conferenceCallingFeatureConfig):

                updateOrCreate(
                    featureName: .conferenceCalling,
                    isEnabled: conferenceCallingFeatureConfig.status == .enabled,
                    config: conferenceCallingFeatureConfig.toDomainModel() /// always nil for api < v6
                )

            case .conversationGuestLinks(let conversationGuestLinksFeatureConfig):

                updateOrCreate(
                    featureName: .conversationGuestLinks,
                    isEnabled: conversationGuestLinksFeatureConfig.status == .enabled
                )

            case .digitalSignature(let digitalSignatureFeatureConfig):

                updateOrCreate(
                    featureName: .digitalSignature,
                    isEnabled: digitalSignatureFeatureConfig.status == .enabled
                )

            case .endToEndIdentity(let endToEndIdentityFeatureConfig):

                updateOrCreate(
                    featureName: .e2ei,
                    isEnabled: endToEndIdentityFeatureConfig.status == .enabled,
                    config: endToEndIdentityFeatureConfig.toDomainModel()
                )

            case .fileSharing(let fileSharingFeatureConfig):

                updateOrCreate(
                    featureName: .fileSharing,
                    isEnabled: fileSharingFeatureConfig.status == .enabled
                )

            case .mls(let mlsFeatureConfig):

                updateOrCreate(
                    featureName: .mls,
                    isEnabled: mlsFeatureConfig.status == .enabled,
                    config: mlsFeatureConfig.toDomainModel()
                )

            case .mlsMigration(let mLSMigrationFeatureConfig):

                updateOrCreate(
                    featureName: .mlsMigration,
                    isEnabled: mLSMigrationFeatureConfig.status == .enabled,
                    config: mLSMigrationFeatureConfig.toDomainModel()
                )

            case .selfDeletingMessages(let selfDeletingMessagesFeatureConfig):

                updateOrCreate(
                    featureName: .selfDeletingMessages,
                    isEnabled: selfDeletingMessagesFeatureConfig.status == .enabled,
                    config: selfDeletingMessagesFeatureConfig.toDomainModel()
                )

            case .unknown(let featureName):

                logger.warn(
                    "Unknown feature name: \(featureName)"
                )
            }
        }
    }

    private func updateOrCreate(
        featureName: Feature.Name,
        isEnabled: Bool,
        config: (any Codable)? = nil
    ) {
        if let config {
            let encoder = JSONEncoder()

            do {
                let data = try encoder.encode(config)

                Feature.updateOrCreate(
                    havingName: featureName,
                    in: context
                ) {
                    $0.status = isEnabled ? .enabled : .disabled
                    $0.config = data
                }

            } catch {
                logger.error(
                    "Failed to encode \(String(describing: config.self)) : \(error)"
                )
            }

        } else {
            Feature.updateOrCreate(
                havingName: featureName,
                in: context
            ) {
                $0.status = isEnabled ? .enabled : .disabled
            }
        }
    }

}

/// A feature fetched locally

struct LocalFeature<T: Decodable> {
    let status: Feature.Status
    let config: T?
}

/// The state of the feature

struct FeatureState {
    let name: Feature.Name
    let status: FeatureConfigStatus
    let shouldNotifyUser: Bool
}
