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

import CoreData
import WireSystem

extension NSManagedObjectContext: GroupQueue {

    @objc
    public var dispatchGroup: ZMSDispatchGroup {
        dispatchGroupContext.groups[0]
    }

    @objc
    public func performGroupedBlock(_ block: @escaping () -> Void) {
        fatalError("TODO")
    }
}

extension NSManagedObjectContext {

    @objc
    var dispatchGroupContext: DispatchGroupContext {
        get { objc_getAssociatedObject(self, &AssociatedDispatchGroupContextKey) as! DispatchGroupContext }
        set { objc_setAssociatedObject(self, &AssociatedDispatchGroupContextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private var AssociatedDispatchGroupContextKey = 0
// private var AssociatedPendingSaveCountKey = 0
