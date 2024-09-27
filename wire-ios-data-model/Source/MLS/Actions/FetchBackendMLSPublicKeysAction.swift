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

public class FetchBackendMLSPublicKeysAction: EntityAction {
    // MARK: Lifecycle

    public init(resultHandler: ResultHandler? = nil) {
        self.resultHandler = resultHandler
    }

    // MARK: Public

    // MARK: - Types

    public typealias Result = BackendMLSPublicKeys

    public enum Failure: LocalizedError, Equatable {
        case endpointUnavailable
        case malformedResponse
        case mlsNotEnabled
        case unknown(status: Int, label: String, message: String)

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                "Endpoint unavailable"

            case .malformedResponse:
                "Malformed response"

            case .mlsNotEnabled:
                "MLS not enabled"

            case let .unknown(status, label, message):
                "Unknown error response status: \(status), label: \(label), message: \(message)"
            }
        }
    }

    // MARK: - Properties

    public var resultHandler: ResultHandler?
}
