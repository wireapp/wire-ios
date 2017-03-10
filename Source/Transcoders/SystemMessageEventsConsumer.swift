//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireRequestStrategy


public class SystemMessageEventsConsumer: NSObject, ZMEventConsumer {
    
    private let moc: NSManagedObjectContext
    private let localNotificationDispatcher: PushMessageHandler
    
    public init(moc: NSManagedObjectContext, localNotificationDispatcher: PushMessageHandler) {
        self.moc = moc
        self.localNotificationDispatcher = localNotificationDispatcher
    }
    
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        let messages = events.flatMap { ZMSystemMessage.createOrUpdate(from: $0, in: self.moc, prefetchResult: nil) }
        messages.forEach { self.localNotificationDispatcher.process($0) }
        
        if liveEvents {
            messages.forEach { $0.conversation?.resortMessages(withUpdatedMessage: $0) }
        }
    }
}

