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

public final class ManagedObjectContextChangesMerger: NSObject {
    // MARK: Lifecycle

    public init(managedObjectContexts: Set<NSManagedObjectContext>) {
        self.managedObjectContexts = managedObjectContexts
        super.init()
        for moc in managedObjectContexts {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(
                    ManagedObjectContextChangesMerger
                        .contextDidSave(_:)
                ),
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: moc
            )
        }
    }

    // MARK: Public

    public let managedObjectContexts: Set<NSManagedObjectContext>

    // MARK: Internal

    @objc
    func contextDidSave(_ notification: Notification) {
        let mocThatSaved = notification.object as! NSManagedObjectContext
        for moc in managedObjectContexts.subtracting([mocThatSaved]) {
            moc.perform {
                moc.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
}
