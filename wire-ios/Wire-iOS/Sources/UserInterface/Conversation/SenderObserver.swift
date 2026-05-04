//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import WireDataModel
import WireMessagingDomain

final class SenderObserver: SenderNameObserverProtocol {

    var authorChangedPublisher: AnyPublisher<String, Never>?

    // later to add publisher for avatar

    init(
        userID: NSManagedObjectID,
        viewContext: NSManagedObjectContext
    ) {
        viewContext.performAndWait { [weak self, viewContext] in
            guard let user = try? viewContext.existingObject(with: userID) as? ZMUser else {
                return
            }

            self?.authorChangedPublisher = NSManagedObject.publisher(for: user, in: viewContext)
                .map { $0.name ?? "" }
                .removeDuplicates()
                .eraseToAnyPublisher()
        }

    }
}

extension NSManagedObject {
    static func publisher<T: NSManagedObject>(
        for managedObject: T,
        in context: NSManagedObjectContext
    ) -> AnyPublisher<T, Never> {
        NotificationCenter.default.publisher(
            for: NSManagedObjectContext.didMergeChangesObjectIDsNotification,
            object: context
        )
        .compactMap { notification in
            if let updated = notification.userInfo?[NSUpdatedObjectIDsKey] as? Set<NSManagedObjectID>,
               updated.contains(managedObject.objectID),
               let updatedObject = context.object(with: managedObject.objectID) as? T {
                updatedObject
            } else {
                nil
            }
        }
        .eraseToAnyPublisher()
    }

}
