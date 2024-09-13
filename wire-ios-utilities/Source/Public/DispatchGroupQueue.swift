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

@objcMembers
public final class DispatchGroupQueue: NSObject, GroupQueue {
    let queue: DispatchQueue
    let dispatchGroupContext: DispatchGroupContext

    public init(queue: DispatchQueue) {
        self.queue = queue
        self.dispatchGroupContext = DispatchGroupContext(groups: [])
    }

    public var dispatchGroup: ZMSDispatchGroup? {
        dispatchGroupContext.groups.first
    }

    public func add(_ group: ZMSDispatchGroup) {
        dispatchGroupContext.add(group)
    }

    public func performGroupedBlock(_ block: @escaping () -> Void) {
        let groups = dispatchGroupContext.enterAll()
        queue.async {
            block()
            self.dispatchGroupContext.leave(groups)
        }
    }
}
