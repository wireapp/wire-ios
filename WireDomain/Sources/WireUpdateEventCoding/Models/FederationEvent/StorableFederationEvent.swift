//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAPI

enum StorableFederationEvent: Equatable, Codable, Sendable {

    case connectionRemoved(StorableFederationConnectionRemovedEvent)
    case delete(StorableFederationDeleteEvent)

    init(_ value: WireAPI.FederationEvent) {
        switch value {
        case .connectionRemoved(let event):
            self = .connectionRemoved(StorableFederationConnectionRemovedEvent(event))
        case .delete(let event):
            self = .delete(StorableFederationDeleteEvent(event))
        }
    }

    func toAPIModel() -> WireAPI.FederationEvent {
        switch self {
        case .connectionRemoved(let event):
            return .connectionRemoved(event.toAPIModel())
        case .delete(let event):
            return .delete(event.toAPIModel())
        }
    }

}
