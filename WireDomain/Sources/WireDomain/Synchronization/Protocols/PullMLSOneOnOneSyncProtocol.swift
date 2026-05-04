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
import WireDataModel
import WireNetwork

// sourcery: AutoMockable
/// An object to fetch an MLS one on one conversation
/// from remote and store it locally.
public protocol PullMLSOneOnOneSyncProtocol {

    /// Fetch an MLS one on one conversation from remote
    /// and store it locally.
    ///
    /// - Parameters:
    ///   - userID: The id of the other user.
    ///   - userDomain: The domain of the other user.
    ///
    /// - Returns: The base-64-encoded MLS group id.

    func pull(
        userID: UUID,
        userDomain: String
    ) async throws -> (MLSGroupID, MLSPublicKeys?)

}
