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

import enum WireNetwork.APIVersion

extension APIVersion {

    /// Returns this version and all subsequent versions.
    /// For example, if `self` is v2 and all cases are [v0, v1, v2, v3, v4],
    /// this returns [v2, v3, v4].
    var andNextVersions: [APIVersion] {
        let apiVersions = APIVersion.allCases
        let currentVersion = Int(rawValue)
        return Array(apiVersions.suffix(from: currentVersion))
    }

    /// Returns all API versions strictly before `end`, sorted in ascending order.
    /// For example, `allCasesUpTo(.v3)` returns [v0, v1, v2].
    static func allCasesUpTo(_ end: APIVersion) -> [APIVersion] {
        Set(APIVersion.allCases)
            .subtracting(end.andNextVersions)
            .sorted()
    }

}
