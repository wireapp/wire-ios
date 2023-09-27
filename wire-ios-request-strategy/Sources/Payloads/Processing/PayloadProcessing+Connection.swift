// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension Payload.ConnectionStatus {

    var internalStatus: ZMConnectionStatus {
        switch self {
        case .sent:
            return .sent
        case .accepted:
            return .accepted
        case .pending:
            return .pending
        case .blocked:
            return .blocked
        case .cancelled:
            return .cancelled
        case .ignored:
            return .ignored
        case .missingLegalholdConsent:
            return .blockedMissingLegalholdConsent
        }
    }

    init?(_ status: ZMConnectionStatus) {
        switch status {
        case .invalid:
            return nil
        case .accepted:
            self = .accepted
        case .pending:
            self = .pending
        case .ignored:
            self = .ignored
        case .blocked:
            self = .blocked
        case .sent:
            self = .sent
        case .cancelled:
            self = .cancelled
        case .blockedMissingLegalholdConsent:
            self = .missingLegalholdConsent
        @unknown default:
            return nil
        }
    }
}


// MARK: - Connection events

extension Payload.UserConnectionEvent {

    func process(in context: NSManagedObjectContext) {
        let processor = ConnectionPayloadProcessor()
        processor.updateOrCreateConnection(
            from: connection,
            in: context
        )
    }

}
