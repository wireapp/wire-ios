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

/// Represents the conversation's meta data and configuration.
public struct Conversation {
    public var access: [String]?
    public var accessRoles: [String]?
    public var cipherSuite: UInt16?
    public var creator: UUID?
    public var epoch: UInt?
    public var epochTimestamp: Date?
    public var id: UUID?
    public var lastEvent: String?
    public var lastEventTime: String?
    public var legacyAccessRole: String?
    public var members: Members?
    public var messageProtocol: String?
    public var messageTimer: TimeInterval?
    public var mlsGroupID: String?
    public var name: String?
    public var qualifiedID: QualifiedID?
    public var readReceiptMode: Int?
    public var teamID: UUID?
    public var type: Int?
}
