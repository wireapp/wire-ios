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

public final class StoredMeeting: NSManagedObject, Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredMeeting> {
        return NSFetchRequest<StoredMeeting>(entityName: "Meeting")
    }

    @NSManaged public var domain: String?
    @NSManaged public var end: Date?
    @NSManaged public var remoteIdentifier: UUID?
    @NSManaged public var repeatOptionRawValue: Int16
    @NSManaged public var start: Date?
    @NSManaged public var title: String?
    @NSManaged public var conversation: ZMConversation?
    @NSManaged public var creator: ZMUser?

}
