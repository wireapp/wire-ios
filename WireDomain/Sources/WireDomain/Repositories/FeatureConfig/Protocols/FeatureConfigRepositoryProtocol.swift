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

import Combine
import WireDataModel
import WireNetwork

// sourcery: AutoMockable
/// Facilitates access to feature configs related domain objects.
public protocol FeatureConfigRepositoryProtocol {

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

    /// Updates a feature config locally.
    ///
    /// - Parameter featureConfig: The feature config to update.

    func updateFeatureConfig(
        _ featureConfig: FeatureConfig
    ) async

    func fetchAllowedGlobalOperations() async throws -> LocalFeature<Feature.AllowedGlobalOperations.Config>
    func fetchMLSConfig() async throws -> LocalFeature<Feature.MLS.Config>
    func fetchMLSMigrationConfig() async throws -> LocalFeature<Feature.MLSMigration.Config>
    func fetchAppLock() async throws -> LocalFeature<Feature.AppLock.Config>
    func fetchCellsInternal() async throws -> LocalFeature<Feature.CellsInternal.Config>

    func isFeatureEnabled(
        _ feature: Feature.Name
    ) async -> Bool
}
