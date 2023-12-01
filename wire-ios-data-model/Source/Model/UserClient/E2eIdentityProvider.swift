//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public struct E2eIdentityCertificate {
    public var certificateDetails: String
    public var expiryDate: Date
    public var certificateStatus: String
    public var serialNumber: String

    public init(
        certificateDetails: String,
        expiryDate: Date,
        certificateStatus: String,
        serialNumber: String
    ) {
        self.certificateDetails = certificateDetails
        self.expiryDate = expiryDate
        self.certificateStatus = certificateStatus
        self.serialNumber = serialNumber
    }
}

public protocol E2eIdentityProviding {
    var isE2EIdentityEnabled: Bool { get }
    func fetchCertificate() async throws -> E2eIdentityCertificate
}

enum E2eIdentityCertificateError: Error {
    case badCertificate
}

public final class E2eIdentityProvider: E2eIdentityProviding {
    public var isE2EIdentityEnabled: Bool

    // TODO: Change this upon implementing business logic
    public init(isE2EIdentityEnabled: Bool = false) {
        self.isE2EIdentityEnabled = isE2EIdentityEnabled
    }

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        throw E2eIdentityCertificateError.badCertificate
    }
}
