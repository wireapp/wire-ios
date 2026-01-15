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

import WireTransport

// MARK: - Prod/Dev versions

public extension APIVersion {

    /// API versions considered production ready by the client.
    ///
    /// IMPORTANT: A version X should only be considered a production version
    /// if the backend also considers X production ready (i.e no more changes
    /// can be made to the API of X) and the implementation of X is correct
    /// and tested.
    ///
    /// Only if these critera are met should we explicitly mark the version
    /// as production ready.

    static let productionVersions: Set<Self> = [
        .v0, .v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13, .v14
    ]

    /// API versions currently under development and not suitable for production
    /// environments.

    static let developmentVersions: Set<Self> = Set(allCases).subtracting(productionVersions)

}
