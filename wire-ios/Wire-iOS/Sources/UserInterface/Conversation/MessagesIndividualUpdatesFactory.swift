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
import WireMessagingDomain
import WireDataModel

final class MessagesIndividualUpdatesFactory {
    
    private let context: NSManagedObjectContext
    
    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }
    
    var dict = [NSManagedObjectID: SenderObserver]()
    
    func makeSenderNamePublisher(user: UserModel?) -> SenderObserverProtocol? {
    
        guard let user else {
            return nil
        }
        
        let zmUser = context.performAndWait {
            ZMUser.fetch(
                with: user.remoteIdentifier,
                in: context
            )
        }
        guard let zmUser else {
            return nil
        }
        
        if let observer = dict[zmUser.objectID] {
            return observer
        }
        
        let observer = SenderObserver(
            userID: zmUser.objectID,
            viewContext: context
        )
        dict[zmUser.objectID] = observer
        return observer
    }
    
    // todo: clear if needed
}
