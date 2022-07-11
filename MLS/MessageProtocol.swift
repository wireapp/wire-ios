//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

/// Protocols for exchanging end-to-end-encrypted messages
/// between clients.

public enum MessageProtocol: Int16 {

    /// With proteus, inidividual encryption sessions are created between
    /// every pair of clients in a conversation. This imposes constraints on
    /// number of participants in a conversation because the number of
    /// encrypted payloads sent per message increases exponentionally as
    /// the number of partipants grows linerarly.

    case proteus

    /// With mls, a shared cryptographic state is maintained and shared between
    /// all participants in a group, so only a single encrypted payload is required
    /// per message. This allows for much larger groups compared to proteus.

    case mls

}
