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

    public init(isE2EIdentityEnabled: Bool = false) {
        self.isE2EIdentityEnabled = isE2EIdentityEnabled
    }

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        throw E2eIdentityCertificateError.badCertificate
    }
}

// MARK: - Mock Provider for Development
public final class MockValidE2eIdentityProvider: E2eIdentityProviding {
    public var isE2EIdentityEnabled: Bool = UserDefaults.standard.bool(forKey: "isE2eIdentityViewEnabled")

    public init() {}

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        return E2eIdentityCertificate(
            certificateDetails: .random(length: 450),
            expiryDate: Date.now.addingTimeInterval(36000),
            certificateStatus: "Valid",
            serialNumber: .random(length: 60)
        )
    }
}

public final class MockRevokedE2eIdentityProvider: E2eIdentityProviding {
    public var isE2EIdentityEnabled: Bool = UserDefaults.standard.bool(forKey: "isE2eIdentityViewEnabled")

    public init() {}

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        return E2eIdentityCertificate(
            certificateDetails: .random(length: 450),
            expiryDate: Date.now.addingTimeInterval(36000),
            certificateStatus: "Revoked",
            serialNumber: .random(length: 60)
        )
    }
}

public final class MockExpiredE2eIdentityProvider: E2eIdentityProviding {
    public var isE2EIdentityEnabled: Bool = UserDefaults.standard.bool(forKey: "isE2eIdentityViewEnabled")

    public init() {}

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        return E2eIdentityCertificate(
            certificateDetails: .random(length: 450),
            expiryDate: Date.now.addingTimeInterval(36000),
            certificateStatus: "Expired",
            serialNumber: .random(length: 60)
        )
    }
}

public final class MockNotActivatedE2eIdentityProvider: E2eIdentityProviding {
    public var isE2EIdentityEnabled: Bool = UserDefaults.standard.bool(forKey: "isE2eIdentityViewEnabled")

    public init() {}

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        return E2eIdentityCertificate(
            certificateDetails: "",
            expiryDate: Date.now.addingTimeInterval(36000),
            certificateStatus: "Not activated",
            serialNumber: ""
        )
    }
}
