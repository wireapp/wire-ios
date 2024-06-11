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

/// A configuration for the *Classified Domains* feature.

public struct ClassifiedDomainsFeatureConfig: Equatable {
    /// The feature's status.

    public let status: FeatureConfigStatus

    /// The list of domains that are trusted by the
    /// self backend and are considered to be safe
    /// for classified communication.

    public let domains: Set<String>
}
