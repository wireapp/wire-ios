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

public enum ConnectionStatus: String, Decodable, Equatable {

    /// The connection is complete and the conversation is in its normal state

    case accepted = "accepted"

    /// The user has been blocked

    case blocked = "blocked"

    /// The other user has sent a connection request to this one

    case pending = "pending"

    /// The connection has been ignored

    case ignored = "ignored"

    /// This user has sent a connection request to another user

    case sent = "sent"

    /// The connection has been cancelled

    case cancelled = "cancelled"

    /// The connection is missing legal hold consent

    case missingLegalholdConsent = "missing-legalhold-consent"
}
