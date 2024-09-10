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

extension MockUser {
    var canSeeServices: Bool {
        self.hasTeam
    }

    // MARK: - clients

    @discardableResult
    func feature(withUserClients numClients: Int) -> [MockUserClient]? {
        var newClients: [AnyHashable] = []
        for _ in 0 ..< numClients {
            let mockClient = MockUserClient()
            mockClient.remoteIdentifier = "0011223344556677"
            mockClient.user = (self as Any as! ZMUser)
            newClients.append(mockClient)
        }
        clients = Set(newClients)
        return newClients as? [MockUserClient]
    }
}
