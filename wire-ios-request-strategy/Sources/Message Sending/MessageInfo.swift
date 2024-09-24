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

/// Container of information needed to encrypt a message
struct MessageInfo {
    typealias Domain = String
    typealias UserID = UUID
    typealias ClientList = [Domain: [UserID: [UserClientData]]]

    var genericMessage: GenericMessage
    /// list of clients divided per domain and userId
    var listClients: ClientList
    var missingClientsStrategy: MissingClientsStrategy
    var selfClientID: String
    var nativePush: Bool

    func allSessionIds() -> [ProteusSessionID] {
        var result = [ProteusSessionID]()
        for (_, userClientIdAndSessionIds) in listClients {
            for (_, userClientDatas) in userClientIdAndSessionIds {
                let sessionIds = userClientDatas.compactMap({ $0.data == nil ? $0.sessionID : nil })
                result.append(contentsOf: sessionIds)
            }
        }
        return result
    }
}

struct UserClientData: Equatable {
    var sessionID: ProteusSessionID
    var data: Data?
}
