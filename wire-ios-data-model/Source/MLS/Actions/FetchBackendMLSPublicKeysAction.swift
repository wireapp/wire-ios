
// Copyright (C) 2022 Wire Swiss GmbH
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

    // MARK: - Types

    public typealias Result = BackendMLSPublicKeys

    public enum Failure: LocalizedError, Equatable {

        case endpointUnavailable
        case malformedResponse
        case unknown(status: Int, label: String, message: String)

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                return "Endpoint unavailable"

            case .malformedResponse:
                return "Malformed response"

            case let .unknown(status, label, message):
                return "Unknown error response status: \(status), label: \(label), message: \(message)"
            }
        }
    }

    // MARK: - Properties

    public var resultHandler: ResultHandler?

    // MARK: - Life cycle

    public init(resultHandler: ResultHandler? = nil) {
        self.resultHandler = resultHandler
    }
    
}
