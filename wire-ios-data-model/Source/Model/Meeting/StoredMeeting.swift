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

public import CoreData

@objc(ZMStoredMeeting) @objcMembers
public final class StoredMeeting: NSManagedObject, Identifiable {

    /// The name of the associated Core Data entity.

    public static let entityName = "Meeting"

    @nonobjc
    public static func fetchRequest() -> NSFetchRequest<StoredMeeting> {
        NSFetchRequest<StoredMeeting>(entityName: "Meeting")
    }

    @NSManaged public var remoteIdentifier: UUID?
    @NSManaged public var domain: String?
    @NSManaged public var title: String?
    @NSManaged public var start: Date?
    @NSManaged public var end: Date?
    @NSManaged public var recurrenceFrequencyRawValue: Int16
    @NSManaged public var recurrenceInterval: Int64 // TODO: default 0 or -1 ?
    @NSManaged public var recurrenceUntil: Date?
    @NSManaged public var conversation: ZMConversation?
    @NSManaged public var creator: ZMUser?

}
