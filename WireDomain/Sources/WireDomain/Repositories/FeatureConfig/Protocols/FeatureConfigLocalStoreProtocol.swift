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

public protocol FeatureConfigLocalStoreProtocol {

    /// Fetches a feature locally.
    /// - parameter name: The name of the feature.
    /// - returns: The feature found locally

    func fetchFeature(
        name: Feature.Name
    ) async throws -> Feature

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

    /// Checks whether a feature is enabled.
    /// - parameter feature: The feature to check the status for.

    func isFeatureEnabled(
        feature: Feature
    ) async -> Bool

}
