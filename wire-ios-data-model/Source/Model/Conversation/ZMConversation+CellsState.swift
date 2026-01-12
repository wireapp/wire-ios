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

/// An enum representing the three possible states of Wire cells, whether `ready`, `pending` or `disabled`.
/// Server side, this value is returned by Pydio backend forwarded to Wire backend.

@objc
public enum CellsState: Int16 {

    case disabled = 0

    case pending = 1

    case ready = 2

}

public extension ZMConversation {

    /// The wire cells state (whether ready, pending or disabled)

    @NSManaged var cellsState: CellsState

    /// Mapping `pending` state to enabled because the feature is considered ready to use on client side.

    var isCellsEnabled: Bool {
        switch cellsState {
        case .ready, .pending:
            true
        case .disabled:
            false
        }
    }
}
