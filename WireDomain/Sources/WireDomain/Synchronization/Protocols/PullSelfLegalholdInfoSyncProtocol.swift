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

// sourcery: AutoMockable
/// An object to keep the local self legal hold info
/// up to date with the remote self legal hold info.
protocol PullSelfLegalholdInfoSyncProtocol {

    /// Fetch the self user from remote, then create or update
    /// it locally.
    ///
    /// - Parameters:
    ///   - selfTeamID: The id of the self user's team.

    func pull(selfTeamID: UUID) async throws

}
