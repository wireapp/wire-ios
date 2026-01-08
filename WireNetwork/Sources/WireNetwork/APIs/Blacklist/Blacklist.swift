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

import Foundation

/// Information about which app versions are legal (allowed to be used) and
/// which are illegal (should be blocked from usage).

public struct BuildNumberBlacklist: Equatable, Sendable {

    /// All build numbers less than this number are considered illegal.

    public let minimumLegalBuildNumber: String

    /// All of these build numbers are considered illegal.

    public let illegalBuildNumbers: Set<String>

    public init(
        minimumLegalBuildNumber: String,
        illegalBuildNumbers: Set<String>
    ) {
        self.minimumLegalBuildNumber = minimumLegalBuildNumber
        self.illegalBuildNumbers = illegalBuildNumbers
    }

}
