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


fileprivate extension Notification {

    var contextDidSaveData: [AnyHashable : AnyObject] {
        guard let info = userInfo else { return [:] }
        var changes = [AnyHashable : AnyObject]()
        for (key, value) in info {
            guard let set = value as? NSSet else { continue }
            changes[key] = set.flatMap {
                return ($0 as? NSManagedObject)?.objectID.uriRepresentation()
            } as AnyObject
        }

        return changes
    }
}


/// This class is used to persist `NSManagedObjectContext` change
/// notifications in order to merge them into the main app contexts.
@objc public class ContextDidSaveNotificationPersistence: NSObject {

    private let defaults = UserDefaults.shared()
    private let saveNotificationKey = "contextDidChangeNotifications"

    public func add(_ note: Notification) {
        var current = storedNotifications
        current.append(note.contextDidSaveData)
        let archived = NSKeyedArchiver.archivedData(withRootObject: current)
        defaults?.set(archived, forKey: saveNotificationKey)
        defaults?.synchronize()
    }

    public func clear() {
        defaults?.set(nil, forKey: saveNotificationKey)
    }

    public var storedNotifications: [[AnyHashable : AnyObject]] {
        if let data = defaults!.object(forKey: saveNotificationKey) as? Data,
            let stored = NSKeyedUnarchiver.unarchiveObject(with: data) as? [[AnyHashable : AnyObject]] {
            return stored
        }

        return []
    }
    
}
