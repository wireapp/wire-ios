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

/// Facilitate access to feature configs related domain objects.

protocol FeatureConfigRepositoryProtocol {

    /// Pull feature configs from the server and store them locally.
    ///
    /// The `AsyncStream` produces a config value right after it is stored locally
    /// so actions can be triggered right away from a lower level callsite (e.g an interactor).
    ///
    /// - Returns: An async stream of feature config.

    func pullFeatureConfigs() -> AsyncThrowingStream<FeatureConfig, Error>

    /// Indicates whether the user should be notified of a given feature.
    /// - Parameter featureName: The feature name.

    func shouldNotifyUser(for featureName: Feature.Name) -> Bool

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

    func pullFeatureConfigs() -> AsyncThrowingStream<FeatureConfig, Error> {
        AsyncThrowingStream<FeatureConfig, Error> { continuation in
            Task {
                do {
                    let featureConfigs = try await featureConfigsAPI.getFeatureConfigs()

                    for featureConfig in featureConfigs {
                        do {
                            try await self.storeFeatureConfig(featureConfig)
                            continuation.yield(featureConfig)
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

    func shouldNotifyUser(for featureName: Feature.Name) -> Bool {
        let feature = Feature.fetch(name: featureName, context: context)
        return feature?.needsToNotifyUser ?? false
    }

    // MARK: - Private

    private func storeFeatureConfig(_ featureConfig: FeatureConfig) async throws {
        try await context.perform { [self] in

            switch featureConfig {
            case .appLock(let appLockFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .appLock,
                    isEnabled: appLockFeatureConfig.status == .enabled,
                    config: appLockFeatureConfig.toDomainModel()
                )

            case .classifiedDomains(let classifiedDomainsFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .classifiedDomains,
                    isEnabled: classifiedDomainsFeatureConfig.status == .enabled,
                    config: classifiedDomainsFeatureConfig.toDomainModel()
                )

            case .conferenceCalling(let conferenceCallingFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .conferenceCalling,
                    isEnabled: conferenceCallingFeatureConfig.status == .enabled,
                    config: conferenceCallingFeatureConfig.toDomainModel() /// always nil for api < v6
                )

            case .conversationGuestLinks(let conversationGuestLinksFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .conversationGuestLinks,
                    isEnabled: conversationGuestLinksFeatureConfig.status == .enabled
                )

            case .digitalSignature(let digitalSignatureFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .digitalSignature,
                    isEnabled: digitalSignatureFeatureConfig.status == .enabled
                )

            case .endToEndIdentity(let endToEndIdentityFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .e2ei,
                    isEnabled: endToEndIdentityFeatureConfig.status == .enabled,
                    config: endToEndIdentityFeatureConfig.toDomainModel()
                )

            case .fileSharing(let fileSharingFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .fileSharing,
                    isEnabled: fileSharingFeatureConfig.status == .enabled
                )

            case .mls(let mLSFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .mls,
                    isEnabled: mLSFeatureConfig.status == .enabled,
                    config: mLSFeatureConfig.toDomainModel()
                )

            case .mlsMigration(let mLSMigrationFeatureConfig):

                try updateOrCreate(
                    inContext: context,
                    featureName: .mlsMigration,
                    isEnabled: mLSMigrationFeatureConfig.status == .enabled,
                    config: mLSMigrationFeatureConfig.toDomainModel()
                )

            case .selfDeletingMessages(let selfDeletingMessagesFeatureConfig):

                try updateOrCreate(
                    inContext: context,
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
        inContext context: NSManagedObjectContext,
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
