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

/// Describes the apps synchronization state.

enum SyncState {

    /// The app is fetching and processing all pending events.

    case quickSync(Task<Void, Error>)

    /// The app is processing live events via the push channel.

    case live(Task<Void, Error>)

    /// The app is neither receiving nor processing any events.

    case suspended

}
