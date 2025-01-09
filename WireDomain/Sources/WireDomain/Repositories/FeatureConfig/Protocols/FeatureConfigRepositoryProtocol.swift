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
import WireAPI
import Combine



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

    func fetchFeatureConfig<T: Decodable>(
        name: Feature.Name,
        type: T.Type
    ) async throws -> LocalFeature<T>

    /// Updates a feature config locally.
    ///
    /// - Parameter featureConfig: The feature config to update.

    func updateFeatureConfig(
        _ featureConfig: FeatureConfig
    ) async throws

    /// Fetches a flag indicating whether the user should be notified of a given feature.
    /// - Parameter name: The feature name.
    /// - Returns: `true` if user should be notified.

    func needsToNotifyUser(
        name: Feature.Name
    ) async throws -> Bool

    /// Stores a flag indicating whether the user should be notified of a given feature.
    /// - Parameter notifyUser: Whether the user should be notified for a given feature.
    /// - Parameter name: The name of the feature to set the flag for.

    func storeFeatureNeedsToNotifyUser(
        _ notifyUser: Bool,
        name: Feature.Name
    ) async throws

}
