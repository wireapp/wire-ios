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

// swiftlint:disable identifier_name

/// A type representing all the versions of the Wire api.

public enum APIVersion: UInt, CaseIterable, Comparable {
    case v0
    case v1
    case v2
    case v3
    case v4
    case v5
    case v6

    // MARK: Public

    /// API versions considered production ready by the client.
    ///
    /// IMPORTANT: A version X should only be considered a production version
    /// if the backend also considers X production ready (i.e no more changes
    /// can be made to the API of X) and the implementation of X is correct
    /// and tested.
    ///
    /// Only if these critera are met should we explicitly mark the version
    /// as production ready.

    public static let productionVersions: Set<Self> = [.v0, .v1, .v2, .v3, .v4, .v5]

    /// API versions currently under development and not suitable for production
    /// environments.

    public static let developmentVersions: Set<Self> = Set(allCases).subtracting(productionVersions)

    /// Compare two api versions.
    ///
    /// - Parameters:
    ///   - lhs: The left operand.
    ///   - rhs: The right operand.
    ///
    /// - Returns: `True` if the numeric version of the left operand is less than the numeric
    /// version of the right operand.

    public static func < (
        lhs: APIVersion,
        rhs: APIVersion
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// swiftlint:enable identifier_name
