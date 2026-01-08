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

public struct WireDriveConversation {
    public var id: QualifiedID
    public var cellName: String
    public var name: String

    public init?(
        uuid: UUID,
        domain: String?,
        cellName: String?,
        name: String?
    ) {
        guard let domain else { return nil }
        guard let cellName else { return nil }
        guard let name else { return nil }

        self.id = QualifiedID(
            id: uuid,
            domain: domain
        )
        self.cellName = cellName
        self.name = name
    }
}

public enum WireDriveConversationDAOError: Error {
    case cellNameNotFound
    case conversationNotFound
    case genericError(any Error)
    case storageFailure
}

public protocol WireDriveConversationDAO {

    func getCellName(conversationID: QualifiedID) async throws(WireDriveConversationDAOError) -> String
    func setWireCell(
        conversationID: QualifiedID,
        cellName: String
    ) async throws(WireCellsConversationDAOError)
    func getAllConversations() async throws(WireDriveConversationDAOError) -> [WireDriveConversation]
}
