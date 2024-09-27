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

// MARK: - SubgroupType

public enum SubgroupType: String, Hashable, Equatable, Codable {
    case conference
}

// MARK: - FetchSubgroupAction

public class FetchSubgroupAction: EntityAction {
    // MARK: Lifecycle

    // MARK: - Init

    public init(domain: String, conversationId: UUID, type: SubgroupType, resultHandler: ResultHandler? = nil) {
        self.domain = domain
        self.conversationId = conversationId
        self.type = type
        self.resultHandler = resultHandler
    }

    // MARK: Public

    public typealias Result = MLSSubgroup

    public enum Failure: Error, Equatable {
        case endpointUnavailable
        case emptyParameters
        case malformedResponse
        case invalidParameters
        case noConversation
        case conversationIdOrDomainNotFound
        case unsupportedConversationType
        case accessDenied
        case unknown(status: Int, label: String, message: String)
    }

    // MARK: - Properties

    public let domain: String
    public let conversationId: UUID
    public let type: SubgroupType
    public var resultHandler: ResultHandler?
}
