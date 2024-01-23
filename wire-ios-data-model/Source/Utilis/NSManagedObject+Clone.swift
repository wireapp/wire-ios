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

// Copied from https://stackoverflow.com/a/59450730
extension NSManagedObject {

    public func copyEntireObjectGraph(context: NSManagedObjectContext) -> NSManagedObject {
        var cache = [NSManagedObjectID: NSManagedObject]()
        return cloneObject(context: context, cache: &cache)
    }

    public func cloneObject(
        context: NSManagedObjectContext,
        cache alreadyCopied: inout [NSManagedObjectID: NSManagedObject]
    ) -> NSManagedObject {
        guard let entityName = entity.name else {
            fatalError("source.entity.name == nil")
        }

        if let storedCopy = alreadyCopied[self.objectID] {
            return storedCopy
        }

        let cloned = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        alreadyCopied[self.objectID] = cloned

        if let attributes = NSEntityDescription.entity(forEntityName: entityName, in: context)?.attributesByName {
            for key in attributes.keys {
                cloned.setValue(self.value(forKey: key), forKey: key)
            }
        }

        if let relationships = NSEntityDescription.entity(forEntityName: entityName, in: context)?.relationshipsByName {
            for (key, value) in relationships {
                if value.isToMany {
                    if let sourceSet = self.value(forKey: key) as? NSMutableOrderedSet {
                        guard let clonedSet = cloned.value(forKey: key) as? NSMutableOrderedSet else {
                            fatalError("Could not cast relationship \(key) to an NSMutableOrderedSet")
                        }

                        let enumerator = sourceSet.objectEnumerator()

                        var nextObject = enumerator.nextObject() as? NSManagedObject

                        while let relatedObject = nextObject {

                            let clonedRelatedObject = relatedObject.cloneObject(context: context, cache: &alreadyCopied)
                            clonedSet.add(clonedRelatedObject)
                            nextObject = enumerator.nextObject() as? NSManagedObject

                        }
                    } else if let sourceSet = self.value(forKey: key) as? NSMutableSet {
                        guard let clonedSet = cloned.value(forKey: key) as? NSMutableSet else {
                            fatalError("Could not cast relationship \(key) to an NSMutableSet")
                        }

                        let enumerator = sourceSet.objectEnumerator()
                        var nextObject = enumerator.nextObject() as? NSManagedObject

                        while let relatedObject = nextObject {
                            let clonedRelatedObject = relatedObject.cloneObject(context: context, cache: &alreadyCopied)
                            clonedSet.add(clonedRelatedObject)
                            nextObject = enumerator.nextObject() as? NSManagedObject
                        }
                    }
                } else {
                    if let relatedObject = self.value(forKey: key) as? NSManagedObject {
                        let clonedRelatedObject = relatedObject.cloneObject(context: context, cache: &alreadyCopied)
                        cloned.setValue(clonedRelatedObject, forKey: key)
                    }
                }
            }
        }

        return cloned
    }
}
