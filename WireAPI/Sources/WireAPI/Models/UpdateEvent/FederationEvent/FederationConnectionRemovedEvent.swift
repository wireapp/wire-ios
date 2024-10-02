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

/// An event where the two or more other backends stopped federating
/// with each other.

public struct FederationConnectionRemovedEvent: Equatable, Codable, Sendable {

    /// The domains of the backends that are no longer
    /// federating with each other.

    public let domains: Set<String>

    public init(domains: Set<String>) {
        self.domains = domains
    }

}
