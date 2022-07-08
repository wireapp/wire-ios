//
// Wire
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

public class UploadSelfMLSKeyPackagesAction: EntityAction {

    // MARK: - Types

    public typealias Result = Void

    public enum Failure: LocalizedError, Equatable {

        case emptyParameters
        case endpointUnavailable
        case mlsProtocolError
        case invalidBody
        case identityMismatch
        case clientNotFound
        case unknown(status: Int)

        public var errorDescription: String? {
            switch self {
            case .emptyParameters:
                return "Empty parameter(s)."
            case .endpointUnavailable:
                return "Endpoint unavailable."
            case .mlsProtocolError:
                return "MLS protocol error."
            case .invalidBody:
                return "Invalid body."
            case .identityMismatch:
                return "Prekey credential does not match qualified client ID."
            case .clientNotFound:
                return "Client not found."
            case .unknown(let status):
                return "Unknown error (response status: \(status))"
            }
        }
    }

    // MARK: - Properties

    public let clientID: String
    public let keyPackages: [String]
    public var resultHandler: ResultHandler?

    init(clientID: String, keyPackages: [String], resultHandler: ResultHandler? = nil) {
        self.clientID = clientID
        self.keyPackages = keyPackages
        self.resultHandler = resultHandler
    }
}
