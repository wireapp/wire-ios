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

/// Describes the shape of an a type that represents a feature.

public protocol FeatureLike: Codable {

    associatedtype Config: Codable

    /// The name of the feature.

    static var name: Feature.Name { get }

    /// The status of the feature.
    ///
    /// If `enabled` then the feature is available to the user.
    /// If `disabled` then it is not available and not visible.

    var status: Feature.Status { get }

    /// The object used to configure the feature.

    var config: Config { get }

    /// Initializes the feature with default values.

    init()

    /// Initializes the feature with the given status and config.

    init(status: Feature.Status, config: Config)

    /// Initializes the feature with the given `Feature` instance.

    init?(feature: Feature)

}

public extension FeatureLike {

    /// Store the feature in the given context as an instance of `Feature`.

    @discardableResult
    func store(for team: Team, in context: NSManagedObjectContext) throws -> Feature {
        return Feature.insert(name: Self.name,
                              status: status,
                              config: try JSONEncoder().encode(config),
                              team: team,
                              context: context)
    }

}
