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

public class ReplaceSelfMLSKeyPackagesAction: EntityAction {
    // MARK: - Types

    public typealias Result = Void

    public enum Failure: Error, Equatable {

        case invalidParameters
        case invalidBodyOrCiphersuites
        case endpointUnavailable
        case mlsProtocolError
        case mlsIdentityMismatch
        case unknown(status: Int)

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                return "Endpoint not available"
            case .invalidParameters:
                return "Invalid client ID or key packages"
            case .invalidBodyOrCiphersuites:
                return "Invalid body or ciphersuites"
            case .mlsProtocolError:
                return "MLS protocol error"
            case .mlsIdentityMismatch:
                return "Key package credential does not match qualified client ID"
            case .unknown(let status):
                return "Unknown error (response status: \(status))"
            }
        }
    }

    // MARK: - Properties

    public var resultHandler: ResultHandler?
    public var clientID: String
    public var keyPackages: [String]
    public let ciphersuite: MLSCipherSuite

    // MARK: - Life cycle

    public init(
        clientID: String,
        keyPackages: [String],
        ciphersuite: MLSCipherSuite,
        resultHandler: ResultHandler? = nil
    ) {
        self.clientID = clientID
        self.keyPackages = keyPackages
        self.ciphersuite = ciphersuite
        self.resultHandler = resultHandler
    }
}
