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
import WireSystem

extension NSManagedObjectContext {

    private func resolve<IDType: NSManagedObject>(_ id: NSManagedObjectID, as type: IDType.Type) throws -> IDType {
        guard let obj = try existingObject(with: id) as? IDType else {
            fatal("expected to find \(type) in context")
        }
        return obj
    }

    public func unpack<U: NSManagedObject, T>(_ object: U, _ block: @escaping @Sendable (U) -> T) async throws -> T {
        let managedObjectID = object.objectID
        return try await perform {
            let object = try self.resolve(managedObjectID, as: U.self)
            return block(object)
        }
    }
}
