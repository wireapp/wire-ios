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

/// Similar to a dispatch queue or NSOperationQueue.
@objc(ZMSGroupQueue)
public protocol GroupQueue: NSObjectProtocol {

    /// The underlying dispatch group that is used for `performGroupedBlock(_:)`.
    /// It can be used to associate a block with the receiver without running it on the receiver's queue.
    var dispatchGroup: ZMSDispatchGroup? { get }

    /// Submits a block to the receiver's private queue and associates it with the receiver's group.
    /// This will use `NSManagedObjectContext.performBlock(_:)` internally and hence encapsulates
    /// an autorelease pool and a call to `NSManagedObjectContext.processPendingChanges()`.
    func performGroupedBlock(_ block: @escaping () -> Void)
}
