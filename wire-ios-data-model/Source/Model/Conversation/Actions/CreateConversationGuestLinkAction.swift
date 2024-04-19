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

public enum CreateConversationGuestLinkError: Error, Equatable {

    case noCode
    case invalidResponse
    case invalidOperation
    case guestLinksDisabled
    case noConversation
    case unknown

    public init?(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (403, "invalid-op"?): self = .invalidOperation
        case (404, "no-conversation-code"?): self = .noCode
        case (404, "no-conversation"?): self = .noConversation
        case (409, "guest-links-disabled"?): self = .guestLinksDisabled
        case (400..<499, _): self = .unknown
        default: return nil
        }
    }
}

public struct CreateConversationGuestLinkParameters {
    public let password: String?
    public let conversationID: UUID

    public init(password: String?, conversationID: UUID) {
        self.password = password
        self.conversationID = conversationID
    }
}

public struct CreateConversationGuestLinkAction: EntityAction {

    public typealias Result = String
    public typealias Failure = CreateConversationGuestLinkError

    public var resultHandler: ResultHandler?

    public var parameters: CreateConversationGuestLinkParameters

    public init(
        parameters: CreateConversationGuestLinkParameters,
        resultHandler: ResultHandler? = nil
    ) {
        self.parameters = parameters
        self.resultHandler = resultHandler
    }
}
