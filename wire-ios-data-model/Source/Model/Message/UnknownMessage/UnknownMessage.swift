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

/// Temporarily stores raw data retrieved from an `ConversationMLSMessageAddEvent` or an
/// `ConversationProteusMessageAddEvent` which couldn't be parsed into a `GenericMessage` yet.

@objcMembers
public final class UnknownMessage: ZMOTRMessage {

    public override static func entityName() -> String {
        "UnknownMessage"
    }

    @nonobjc
    public static func fetchRequest() -> NSFetchRequest<UnknownMessage> {
        NSFetchRequest<UnknownMessage>(entityName: "UnknownMessage")
    }

    /// The data which can be deserialized into a ``GenericMessage``.

    @NSManaged public var payload: Data?

    /// The date/time the event was initially received.

    @NSManaged public var eventTimestamp: Date?

}
