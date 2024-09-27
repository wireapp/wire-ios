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

public final class CountSelfMLSKeyPackagesAction: EntityAction {
    // MARK: Lifecycle

    public init(
        clientID: String,
        resultHandler: ResultHandler? = nil
    ) {
        self.clientID = clientID
        self.resultHandler = resultHandler
    }

    // MARK: Public

    // MARK: - Types

    public typealias Result = Int

    public enum Failure: Error, Equatable {
        case clientNotFound
        case malformedResponse
        case invalidClientID
        case endpointUnavailable
        case unknown(status: Int)

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .clientNotFound:
                "Client not found"
            case .malformedResponse:
                "Malformed response"
            case .endpointUnavailable:
                "End point not available"
            case .invalidClientID:
                "Invalid clientID"
            case let .unknown(status):
                "Unknown error (response status: \(status))"
            }
        }
    }

    // MARK: - Properties

    public var resultHandler: ResultHandler?
    public var clientID: String
}
