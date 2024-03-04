////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

/// Action to perform on a given persistentContainer
class CoreDataAction {

    private func loadStores(for persistentContainer: NSPersistentContainer) throws {
        persistentContainer.persistentStoreDescriptions.first?.shouldAddStoreAsynchronously = false

        var loadError: Error?
        persistentContainer.loadPersistentStores { description, error in
            loadError =  error
        }
        if let loadError {
            throw loadError
        }
    }

    func perform(with persistentContainer: NSPersistentContainer) throws {

        try loadStores(for: persistentContainer)

        let context = persistentContainer.newBackgroundContext()
        var savedError: Error?
        context.performAndWait {
            do {
                try self.execute(in: context)
                try context.save()
            } catch {
                savedError = error
            }
        }
        if let savedError {
            throw savedError
        }
    }


    func execute(in context: NSManagedObjectContext) throws {
        // to be overriden by subclasses
    }
}
