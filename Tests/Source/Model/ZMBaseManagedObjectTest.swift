//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

extension ZMBaseManagedObjectTest {
    
    @objc public func createClient(user: ZMUser, createSessionWithSelfUser: Bool, managedObjectContext: NSManagedObjectContext) -> UserClient {
        if user.remoteIdentifier == nil {
            user.remoteIdentifier = UUID.create()
        }
        
        let userClient = UserClient.insertNewObject(in: managedObjectContext)
        userClient.remoteIdentifier = NSString.createAlphanumerical()
        userClient.user = user
        
        if createSessionWithSelfUser {
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()!
            self.performPretendingUiMocIsSyncMoc {
                let key = try! selfClient.keysStore.lastPreKey()
                _ = selfClient.establishSessionWithClient(userClient, usingPreKey: key)
            }
        }
        return userClient
    }
}
