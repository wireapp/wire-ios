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

struct NotificationPayload {
    let userID: UUID
    let eventID: UUID
    
    enum Failure: Error {
        case missingUserID
        case missingEventID
    }
    
    enum Key: String {
        case data
        case user
        case id
    }
    
    init(userInfo: [AnyHashable : Any]) throws {
        guard
            let data = userInfo[Key.data.rawValue] as? [String: Any],
            let userIDString = data[Key.user.rawValue] as? String,
            let userID = UUID(uuidString: userIDString)
        else {
            throw Failure.missingUserID
        }
        
        guard let innerData = data[Key.data.rawValue] as? [AnyHashable: Any],
              let eventIDString = innerData[Key.id.rawValue] as? String,
              let eventID = UUID(uuidString: eventIDString)
        else {
            throw Failure.missingEventID
        }
        
        self.userID = userID
        self.eventID = eventID
    }
}
