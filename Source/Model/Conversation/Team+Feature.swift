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

    func feature(for name: Feature.Name) -> Feature? {
        return features.first(where: { $0.name == name })
    }

    /// Enqueue a backend refresh for the feature with the given name.
    ///
    /// To trigger the request immediately, post a `RequestAvailableNotification`.
    ///
    /// - Parameter name: The name of the feature to refresh.
    
    public func enqueueBackendRefresh(for name: Feature.Name) {
        guard let context = managedObjectContext else { return }

        let feature = Feature.fetch(name: name, context: context)
        feature?.needsToBeUpdatedFromBackend = true
    }

}
