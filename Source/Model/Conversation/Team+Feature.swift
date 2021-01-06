//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension Team {

    @NSManaged private var features: Set<Feature>

    /// Fetch a particular team feature.
    ///
    /// If no instance exists yet in the database, a default one will be created
    /// using the parameterless initializer for `T`.
    ///
    /// - Parameters:
    ///     - type: The type of the desired feature. The available features
    ///             are typically found in the namespace `Feature`.
    ///
    /// - Returns:
    ///     The feature object.

    public func feature<T: FeatureLike>(for featureType: T.Type) -> T {
        guard let feature = features.first(where: { $0.name == T.name }) else {
            return createAndStoreDefault(for: featureType)
        }

        guard let result = T(feature: feature) else {
            fatalError("Failed to create feature wrapper for name: \(T.name)")
        }

        return result
    }
    
    func feature(for name: Feature.Name) -> Feature? {
        return features.first(where: { $0.name == name })
    }

    private func createAndStoreDefault<T: FeatureLike>(for type: T.Type) -> T {
        let defaultInstance = T()

        guard
            let context = managedObjectContext,
            let _ = try? defaultInstance.store(for: self, in: context)
        else {
            fatalError("Failed to store default instance for feature: \(T.name)")
        }

        return defaultInstance
    }

    /// Enqueue a backend refresh for the feature with the given name.
    ///
    /// To trigger the request immediately, post a `RequestAvailableNotification`.
    ///
    /// - Parameter name: The name of the feature to refresh.
    
    public func enqueueBackendRefresh(for name: Feature.Name) {
        guard let context = managedObjectContext else { return }
        
        let feature = Feature.fetchOrCreate(name: name, team: self, context: context)
        feature.needsToBeUpdatedFromBackend = true
    }

}
