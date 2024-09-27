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
import WireDataModel

extension ZMConversationMessage {
    /// Return the percentage (range: 0 to 1) to destruct of a ephemeral message.
    /// Return nil if self is not a ephemeral message or invalid deletionTimeout or deliveryState is pending
    var countdownProgress: Double? {
        guard deliveryState != .pending,
              let destructionDate, deletionTimeout > 0 else {
            return nil
        }

        return 1 - destructionDate.timeIntervalSinceNow / deletionTimeout
    }
}
