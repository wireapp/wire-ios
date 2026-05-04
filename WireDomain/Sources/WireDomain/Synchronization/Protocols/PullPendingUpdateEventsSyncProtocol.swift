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
/// A sync to pull pending update events from the remote, decrypts,
/// and stores them locally.
public protocol PullPendingUpdateEventsSyncProtocol {

    /// Pull pending update events from the remote, decrypt (if needed),
    /// and store them locally.
    /// - Returns: Stream of UpdateEvent's batch
    @discardableResult
    func pull(publicKeys: EARPublicKeys?) async throws -> AsyncStream<[UpdateEvent]>

}
