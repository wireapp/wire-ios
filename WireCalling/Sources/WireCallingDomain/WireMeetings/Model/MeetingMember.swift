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

public import Foundation
public import WireFoundation

// TODO: [WPB-20278] Update the model
public struct MeetingMember: Hashable, Identifiable, Sendable {

    public let qualifiedID: QualifiedID
    public let name: String
    public let handle: String

    public var id: UUID {
        qualifiedID.id
    }

    public init(
        qualifiedID: QualifiedID,
        name: String,
        handle: String
    ) {
        self.qualifiedID = qualifiedID
        self.name = name
        self.handle = handle
    }

}
