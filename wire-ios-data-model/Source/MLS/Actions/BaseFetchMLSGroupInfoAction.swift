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

public class BaseFetchMLSGroupInfoAction: EntityAction {
    // MARK: Lifecycle

    init(resultHandler: ResultHandler? = nil) {
        self.resultHandler = resultHandler
    }

    // MARK: Public

    public typealias Result = Data

    public enum Failure: Error, Equatable {
        case endpointUnavailable
        case noConversation
        case missingGroupInfo
        case conversationIdOrDomainNotFound
        case malformedResponse
        case emptyParameters
        case invalidParameters
        case mlsNotEnabled
        case unknown(status: Int, label: String, message: String)

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                "Endpoint unavailable."
            case .noConversation:
                "Conversation not found"
            case .missingGroupInfo:
                "The conversation has no group information"
            case .conversationIdOrDomainNotFound:
                "Conversation ID or domain not found."
            case .malformedResponse:
                "Malformed response"
            case .emptyParameters:
                "Empty parameters."
            case .invalidParameters:
                "Invalid conversation ID or domain"
            case .mlsNotEnabled:
                "MLS is not configured on this backend"
            case let .unknown(status, label, message):
                "Unknown error (response status: \(status), label: \(label), message: \(message))"
            }
        }
    }

    public var resultHandler: ResultHandler?
}
