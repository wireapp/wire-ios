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

protocol FeatureConfigLocalStoreProtocol {

    /// Fetches a feature locally.
    /// - parameter name: The name of the feature.
    /// - returns: The feature found locally

    func fetchFeature(
        name: Feature.Name
    ) async throws -> Feature

    /// Stores a flag indicating whether the user needs to be notified of the feature.
    /// - parameters:
    ///     - needsNotifyUser: The flag to update.
    ///     - feature: The feature to update the flag for.

    func storeFeature(
        needsNotifyUser: Bool,
        feature: Feature
    ) async

    /// Fetches a flag whether the user needs to be notified for the feature.
    /// - parameter feature: A given feature.
    /// - returns: Whether the user needs to be notified.

    func featureNeedsNotifyUser(
        feature: Feature
    ) async -> Bool

    /// Stores a feature locally.
    /// - parameters:
    ///     - name: The name of the feature
    ///     - isEnabled: Whether the feature is enabled.
    ///     - config: The config of the feature if any.

    func storeFeature(
        name: Feature.Name,
        isEnabled: Bool,
        config: (any Codable)?
    ) async

    /// Fetches a feature config info.
    /// - parameter feature: The feature to fetch the info from.
    /// - returns: A status (enabled or disabled) and a config payload.

    func featureConfig(
        feature: Feature
    ) async -> (status: Feature.Status, config: Data?)

}

final class FeatureConfigLocalStore: FeatureConfigLocalStoreProtocol {

    // MARK: - Error

    enum Error: Swift.Error {
        case failedToFetchFeatureLocally
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }

    // MARK: - Public

    public func fetchFeature(
        name: Feature.Name
    ) async throws -> Feature {
        try await context.perform { [context] in
            guard let feature = Feature.fetch(
                name: name,
                context: context
            ) else {
                throw Error.failedToFetchFeatureLocally
            }

            return feature
        }
    }

    public func storeFeature(
        needsNotifyUser: Bool,
        feature: Feature
    ) async {
        await context.perform {
            feature.needsToNotifyUser = needsNotifyUser
        }
    }

    public func featureConfig(
        feature: Feature
    ) async -> (status: Feature.Status, config: Data?) {
        await context.perform {
            (feature.status, feature.config)
        }
    }

    func featureNeedsNotifyUser(
        feature: Feature
    ) async -> Bool {
        await context.perform {
            feature.needsToNotifyUser
        }
    }

    public func storeFeature(
        name: Feature.Name,
        isEnabled: Bool,
        config: (any Codable)? = nil
    ) async {
        await context.perform { [context] in
            if let config {
                let encoder = JSONEncoder()

                do {
                    let data = try encoder.encode(config)

                    Feature.updateOrCreate(
                        havingName: name,
                        in: context
                    ) {
                        $0.status = isEnabled ? .enabled : .disabled
                        $0.config = data
                    }

                } catch {
                    WireLogger.featureConfigs.error(
                        "Failed to encode \(String(describing: config.self)) : \(error)"
                    )
                }

            } else {
                Feature.updateOrCreate(
                    havingName: name,
                    in: context
                ) {
                    $0.status = isEnabled ? .enabled : .disabled
                }
            }
        }
    }

}
