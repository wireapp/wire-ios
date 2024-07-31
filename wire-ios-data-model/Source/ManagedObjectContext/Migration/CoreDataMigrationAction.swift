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

/// Action to perform on a given persistentContainer
class CoreDataMigrationAction {
    var dataModelName: String {
        "zmessaging"
    }

    private func loadStore(for persistentContainer: NSPersistentContainer) throws {
        persistentContainer.persistentStoreDescriptions.first?.shouldAddStoreAsynchronously = false

        var loadError: Error?
        persistentContainer.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }
    }

    func perform(on storeURL: URL, with model: NSManagedObjectModel) throws {
        let container = try createStore(model: model, at: storeURL)

        try loadStore(for: container)

        let context = container.newBackgroundContext()
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
            // enforce cleanup without handling errors
            try? removeStore(for: container)
            throw savedError
        } else {
            try removeStore(for: container)
        }
    }

    func removeStore(for container: NSPersistentContainer) throws {
        if let store = container.persistentStoreCoordinator.persistentStores.first {
            try container.persistentStoreCoordinator.remove(store)
        }
    }

    func execute(in context: NSManagedObjectContext) throws {
        // to be overriden by subclasses
    }

    private func createStore(model: NSManagedObjectModel, at storeURL: URL) throws -> NSPersistentContainer {

        let container = NSPersistentContainer(
            name: dataModelName,
            managedObjectModel: model
        )

        try container.persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: nil
        )

        return container
    }
}
