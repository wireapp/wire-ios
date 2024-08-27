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

import WireAPI
import WireDataModel

/// Facilitates access to feature configs related domain objects.

protocol FeatureConfigRepositoryProtocol {

    /// Pulls feature configs from the server and stores them locally.
    ///
    /// The `AsyncStream` produces a `FeatureState` value right after the feature is stored locally.
    /// so actions can be triggered right away at a lower level callsite (e.g an interactor).
    /// This will allow a user to be notified immediately even if the stream fails afterwards.
    ///
    /// - Returns: An async stream of `FeatureState`.

    func pullFeatureConfigs() -> AsyncThrowingStream<FeatureState, Error>

    /// Fetch a feature config locally.
    ///
    /// - Parameter name: The feature name to fetch the config for.
    /// - Parameter type: The type of config to retrieve.
    /// - Returns: A `LocalFeature` object with a status and a config (if any).

    func fetchFeatureConfig<T: Decodable>(withName name: Feature.Name, type: T.Type) async throws -> LocalFeature<T>

    /// Fetches a flag indicating whether the user should be notified of a given feature.
    /// - Parameter name: The feature name.
    /// - Returns: `true` if user should be notified.

    func fetchNeedsToNotifyUser(forFeatureName name: Feature.Name) async throws -> Bool

    /// Stores a flag indicating whether the user should be notified of a given feature.
    /// - Parameter notifyUser: Whether the user should be notified for a given feature.
    /// - Parameter name: The name of the feature to set the flag for.

    func storeNeedsToNotifyUser(_ notifyUser: Bool, forFeatureName name: Feature.Name) async throws

}

final class FeatureConfigRepository: FeatureConfigRepositoryProtocol {

    // MARK: - Properties

    private let featureConfigsAPI: any FeatureConfigsAPI
    private let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    init(
        featureConfigsAPI: any FeatureConfigsAPI,
        context: NSManagedObjectContext
    ) {
        self.featureConfigsAPI = featureConfigsAPI
        self.context = context
    }

    // MARK: - Public

    func pullFeatureConfigs() -> AsyncThrowingStream<FeatureState, Error> {
        AsyncThrowingStream<FeatureState, Error> { continuation in
            Task {
                do {
                    let featureConfigs = try await featureConfigsAPI.getFeatureConfigs()

                    for featureConfig in featureConfigs {
                        do {
                            try await storeFeatureConfig(featureConfig)
                            if let featureState = try await getFeatureState(forFeatureConfig: featureConfig) {
                                continuation.yield(featureState)
                            }
                        } catch {
                            continuation.finish(throwing: FeatureConfigRepositoryError.failedToStoreConfigLocally(error))
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func fetchFeatureConfig<T: Decodable>(withName name: Feature.Name, type: T.Type) async throws -> LocalFeature<T> {
        try await context.perform { [context] in
            guard let feature = Feature.fetch(name: name, context: context) else {
                throw FeatureConfigRepositoryError.failedToFetchConfigLocally
            }

            if let config = feature.config {
                let decoder = JSONDecoder()
                let config = try decoder.decode(type, from: config)

                return LocalFeature(status: feature.status, config: config)
            }

            return LocalFeature(status: feature.status, config: nil)
        }
    }

    func fetchNeedsToNotifyUser(forFeatureName name: Feature.Name) async throws -> Bool {
        await context.perform { [context] in
            let feature = Feature.fetch(name: name, context: context)
            return feature?.needsToNotifyUser ?? false
        }
    }

    func storeNeedsToNotifyUser(_ notifyUser: Bool, forFeatureName name: Feature.Name) async throws {
        await context.perform { [context] in
            let feature = Feature.fetch(name: name, context: context)
            feature?.needsToNotifyUser = notifyUser
        }
    }

    // MARK: - Private

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

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(forFeatureName: .conferenceCalling)
            return FeatureState(
                name: .conferenceCalling,
                status: conferenceCallingFeatureConfig.status,
                shouldNotifyUser: needsToNotifyUser
            )

        case .conversationGuestLinks(let conversationGuestLinksFeatureConfig):

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(forFeatureName: .conversationGuestLinks)
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

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(forFeatureName: .fileSharing)
            return FeatureState(
                name: .fileSharing,
                status: fileSharingFeatureConfig.status,
                shouldNotifyUser: needsToNotifyUser
            )

        case .mls(let mLSFeatureConfig):

            return FeatureState(
                name: .mls,
                status: mLSFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .mlsMigration(let mLSMigrationFeatureConfig):

            return FeatureState(
                name: .mlsMigration,
                status: mLSMigrationFeatureConfig.status,
                shouldNotifyUser: false
            )

        case .selfDeletingMessages(let selfDeletingMessagesFeatureConfig):

            let needsToNotifyUser = try await fetchNeedsToNotifyUser(forFeatureName: .selfDeletingMessages)
            return FeatureState(
                name: .selfDeletingMessages,
                status: selfDeletingMessagesFeatureConfig.status,
                shouldNotifyUser: needsToNotifyUser
            )

        case .unknown(let featureName):
            assertionFailure("Unknown feature: \(featureName)")
            return nil
        }
    }

    private func storeFeatureConfig(_ featureConfig: FeatureConfig) async throws {
        try await context.perform { [self] in

            switch featureConfig {
            case .appLock(let appLockFeatureConfig):

                try updateOrCreate(
                    featureName: .appLock,
                    isEnabled: appLockFeatureConfig.status == .enabled,
                    config: appLockFeatureConfig.toDomainModel()
                )

            case .classifiedDomains(let classifiedDomainsFeatureConfig):

                try updateOrCreate(
                    featureName: .classifiedDomains,
                    isEnabled: classifiedDomainsFeatureConfig.status == .enabled,
                    config: classifiedDomainsFeatureConfig.toDomainModel()
                )

            case .conferenceCalling(let conferenceCallingFeatureConfig):

                try updateOrCreate(
                    featureName: .conferenceCalling,
                    isEnabled: conferenceCallingFeatureConfig.status == .enabled,
                    config: conferenceCallingFeatureConfig.toDomainModel() /// always nil for api < v6
                )

            case .conversationGuestLinks(let conversationGuestLinksFeatureConfig):

                try updateOrCreate(
                    featureName: .conversationGuestLinks,
                    isEnabled: conversationGuestLinksFeatureConfig.status == .enabled
                )

            case .digitalSignature(let digitalSignatureFeatureConfig):

                try updateOrCreate(
                    featureName: .digitalSignature,
                    isEnabled: digitalSignatureFeatureConfig.status == .enabled
                )

            case .endToEndIdentity(let endToEndIdentityFeatureConfig):

                try updateOrCreate(
                    featureName: .e2ei,
                    isEnabled: endToEndIdentityFeatureConfig.status == .enabled,
                    config: endToEndIdentityFeatureConfig.toDomainModel()
                )

            case .fileSharing(let fileSharingFeatureConfig):

                try updateOrCreate(
                    featureName: .fileSharing,
                    isEnabled: fileSharingFeatureConfig.status == .enabled
                )

            case .mls(let mLSFeatureConfig):

                try updateOrCreate(
                    featureName: .mls,
                    isEnabled: mLSFeatureConfig.status == .enabled,
                    config: mLSFeatureConfig.toDomainModel()
                )

            case .mlsMigration(let mLSMigrationFeatureConfig):

                try updateOrCreate(
                    featureName: .mlsMigration,
                    isEnabled: mLSMigrationFeatureConfig.status == .enabled,
                    config: mLSMigrationFeatureConfig.toDomainModel()
                )

            case .selfDeletingMessages(let selfDeletingMessagesFeatureConfig):

                try updateOrCreate(
                    featureName: .selfDeletingMessages,
                    isEnabled: selfDeletingMessagesFeatureConfig.status == .enabled,
                    config: selfDeletingMessagesFeatureConfig.toDomainModel()
                )

            case .unknown(let featureName):
                assertionFailure("Unknown feature: \(featureName)")
            }
        }
    }

    private func updateOrCreate(
        featureName: Feature.Name,
        isEnabled: Bool,
        config: (any Codable)? = nil
    ) throws {
        if let config {
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)

            Feature.updateOrCreate(havingName: featureName, in: context) {
                $0.status = isEnabled ? .enabled : .disabled
                $0.config = data
            }
        } else {
            Feature.updateOrCreate(havingName: featureName, in: context) {
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
