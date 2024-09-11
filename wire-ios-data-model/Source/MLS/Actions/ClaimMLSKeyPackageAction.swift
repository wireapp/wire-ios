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

public class ClaimMLSKeyPackageAction: EntityAction {
    // MARK: - Types

    // Until we know what type is best for the result, we'll use [KeyPackage]
    public typealias Result = [KeyPackage]

    public enum Failure: LocalizedError, Equatable {
        case missingDomain
        case endpointUnavailable
        case malformedResponse
        case invalidSelfClientId
        case userOrDomainNotFound
        case emptyKeyPackages
        case unknown(status: Int)

        public var errorDescription: String? {
            switch self {
            case .missingDomain:
                "Missing domain."
            case .endpointUnavailable:
                "Endpoint unavailable."
            case .malformedResponse:
                "Malformed response."
            case .invalidSelfClientId:
                "Invalid self client id for parameter: skip own."
            case .userOrDomainNotFound:
                "User domain or user not found."
            case .emptyKeyPackages:
                "The list of key packages is empty"
            case let .unknown(status):
                "Unknown error (response status: \(status))"
            }
        }
    }

    // MARK: - Properties

    /// the self client id to provide if we wish to avoid claiming the key package for that client
    public let excludedSelfClientId: String?
    public let domain: String?
    public let userId: UUID
    public let ciphersuite: MLSCipherSuite
    public var resultHandler: ResultHandler?

    public init(
        domain: String?,
        userId: UUID,
        ciphersuite: MLSCipherSuite,
        excludedSelfClientId: String? = nil,
        resultHandler: ResultHandler? = nil
    ) {
        self.domain = domain
        self.userId = userId
        self.ciphersuite = ciphersuite
        self.excludedSelfClientId = excludedSelfClientId
        self.resultHandler = resultHandler
    }
}

// Temporary solution until we know what we need from the result. Once we do, this should move to the action handler
// extension.
public struct KeyPackage: Codable, Equatable {
    public let client: String
    public let domain: String
    public let keyPackage: String
    public let keyPackageRef: String
    public let userID: UUID

    enum CodingKeys: String, CodingKey {
        case client
        case domain
        case keyPackage = "key_package"
        case keyPackageRef = "key_package_ref"
        case userID = "user"
    }

    public init(
        client: String,
        domain: String,
        keyPackage: String,
        keyPackageRef: String,
        userID: UUID
    ) {
        self.client = client
        self.domain = domain
        self.keyPackage = keyPackage
        self.keyPackageRef = keyPackageRef
        self.userID = userID
    }
}
