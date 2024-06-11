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

/// Metadata about the local backend.

public struct BackendInfo: Equatable {
    /// The local domain.

    public let domain: String

    /// Whether federation is enabled on the local backend.

    public let isFederationEnabled: Bool

    /// All production ready api versions supported by the local backend.

    public let supportedVersions: Set<APIVersion>

    /// All api versions currently under development by the local backend.

    public let developmentVersions: Set<APIVersion>
}
