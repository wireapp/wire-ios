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

public enum ConnectionStatus: Equatable, Sendable {

    /// The connection is complete and the conversation is in its normal state

    case accepted

    /// The user has been blocked

    case blocked

    /// The other user has sent a connection request to this one

    case pending

    /// The connection has been ignored

    case ignored

    /// This user has sent a connection request to another user

    case sent

    /// The connection has been cancelled

    case cancelled

    /// The connection is missing legal hold consent

    case missingLegalholdConsent
}

enum ConnectionStatusV0: String, Equatable, Sendable, Decodable {

    case accepted
    case blocked
    case pending
    case ignored
    case sent
    case cancelled
    case missingLegalholdConsent = "missing-legalhold-consent"
}

extension ConnectionStatusV0: ToAPIModelConvertible {
    func toAPIModel() -> ConnectionStatus {
        switch self {
        case .accepted:
            .accepted
        case .blocked:
            .blocked
        case .pending:
            .pending
        case .ignored:
            .ignored
        case .sent:
            .sent
        case .cancelled:
            .cancelled
        case .missingLegalholdConsent:
            .missingLegalholdConsent
        }
    }
}
