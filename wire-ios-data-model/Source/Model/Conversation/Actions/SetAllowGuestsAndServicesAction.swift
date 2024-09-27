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

public struct SetAllowGuestsAndServicesAction: EntityAction {
    // MARK: Lifecycle

    public init(
        allowGuests: Bool,
        allowServices: Bool,
        conversationID: NSManagedObjectID,
        resultHandler: ResultHandler? = nil
    ) {
        self.allowGuests = allowGuests
        self.allowServices = allowServices
        self.conversationID = conversationID
        self.resultHandler = resultHandler
    }

    // MARK: Public

    public typealias Result = Void

    public enum Failure: Error, Equatable {
        case domainUnavailable
        case failToDecodeResponsePayload
        case failedToRetrieveConversation
        case unknown
    }

    public let allowGuests: Bool
    public let allowServices: Bool
    public let conversationID: NSManagedObjectID

    public var resultHandler: ResultHandler?
}
