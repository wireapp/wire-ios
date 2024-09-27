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

import AddressBook
import Contacts
import Foundation

// MARK: - AddressBookEntry

@objcMembers
public class AddressBookEntry: ZMManagedObject {
    public enum Fields: String {
        case localIdentifier
        case user
        case cachedName
    }

    @NSManaged public var localIdentifier: String?
    @NSManaged public var user: ZMUser?
    @NSManaged public var cachedName: String?

    override public func keysTrackedForLocalModifications() -> Set<String> {
        []
    }

    override public static func entityName() -> String {
        "AddressBookEntry"
    }

    override public static func sortKey() -> String? {
        Fields.localIdentifier.rawValue
    }

    override public static func isTrackingLocalModifications() -> Bool {
        false
    }
}

extension AddressBookEntry {
    @objc(createFromContact:managedObjectContext:user:)
    public static func create(
        from contact: CNContact,
        managedObjectContext: NSManagedObjectContext,
        user: ZMUser? = nil
    ) -> AddressBookEntry {
        let entry = AddressBookEntry.insertNewObject(in: managedObjectContext)
        entry.localIdentifier = contact.identifier
        entry.cachedName = CNContactFormatter.string(from: contact, style: .fullName)
        entry.user = user
        return entry
    }
}
