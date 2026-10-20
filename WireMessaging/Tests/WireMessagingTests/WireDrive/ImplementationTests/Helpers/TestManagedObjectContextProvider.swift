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

import CoreData
import Foundation
import WireData

/// An in-memory Core Data stack for exercising stores against the real `zmessaging` model.
///
/// The model is loaded from `WireDataBundle`, so a schema mistake — a missing attribute, a wrong
/// type, a stale model version — fails the test rather than only showing up at runtime.
final class TestManagedObjectContextProvider: ManagedObjectContextProvider, @unchecked Sendable {

    private let container: NSPersistentContainer

    init() throws {
        guard let model = NSManagedObjectModel.mergedModel(from: [WireDataBundle.bundle]) else {
            throw Failure.modelUnavailable
        }

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        self.container = NSPersistentContainer(name: "zmessaging", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]

        var loadError: (any Error)?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let loadError {
            throw loadError
        }
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    enum Failure: Error {
        case modelUnavailable
    }
}
