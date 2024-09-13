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

@objcMembers
public final class Action: ZMManagedObject {
    public static let nameKey = #keyPath(Action.name)
    public static let roleKey = #keyPath(Action.role)

    @NSManaged public var role: Role
    @NSManaged public var name: String?

    override public static func entityName() -> String {
        String(describing: Action.self)
    }

    @discardableResult
    public static func fetchOrCreate(
        name: String,
        in context: NSManagedObjectContext
    ) -> Action {
        var created = false
        return fetchOrCreate(
            name: name,
            in: context,
            created: &created
        )
    }

    @discardableResult
    public static func fetchOrCreate(
        name: String,
        in context: NSManagedObjectContext,
        created: inout Bool
    ) -> Action {
        if let action = fetch(
            name: name,
            in: context
        ) {
            created = false
            return action
        }

        let action = create(
            name: name,
            in: context
        )

        created = true
        return action
    }

    public static func fetch(
        name: String,
        in context: NSManagedObjectContext
    ) -> Action? {
        let fetchRequest = NSFetchRequest<Action>(entityName: entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", nameKey, name)
        let actions = context.fetchOrAssert(request: fetchRequest)
        return actions.first
    }

    @discardableResult
    public static func create(
        name: String,
        in context: NSManagedObjectContext
    ) -> Action {
        let action = Action.insertNewObject(in: context)
        action.name = name
        return action
    }

    override public static func isTrackingLocalModifications() -> Bool {
        false
    }
}
