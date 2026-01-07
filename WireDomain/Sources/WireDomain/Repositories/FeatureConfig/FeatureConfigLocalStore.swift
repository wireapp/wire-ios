//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public final class FeatureConfigLocalStore: FeatureConfigLocalStoreProtocol {

    // MARK: - Error

    enum Error: Swift.Error {
        case failedToFetchFeatureLocally
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    public init(
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

    public func isFeatureEnabled(
        feature: Feature
    ) async -> Bool {
        await context.perform {
            feature.status == .enabled
        }
    }

    public func featureConfig(
        feature: Feature
    ) async -> (status: Feature.Status, config: Data?) {
        await context.perform {
            (feature.status, feature.config)
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
