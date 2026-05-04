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

import WireDataModel

public struct ConnectionInfo: Equatable, Sendable {
    public let senderID: UUID?
    public let receiverID: UUID?
    public let receiverQualifiedID: WireDataModel.QualifiedID?
    public let conversationID: UUID?
    public let qualifiedConversationID: WireDataModel.QualifiedID?
    public let lastUpdate: Date
    public let status: WireDataModel.ZMConnectionStatus
}
