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

public final class MockRevokedE2eIdentityProvider: E2eIdentityProviding {

    lazy var dateFormatter = DateFormatter()

    public var certificate: E2eIdentityCertificate {
        E2eIdentityCertificate(
            certificateDetails: .mockCertificate(),
            mlsThumbprint: .mockThumbprint(),
            notValidBefore: dateFormatter.date(from: "10.10.2023") ?? Date.now - .oneYearFromNow,
            expiryDate: dateFormatter.date(from: "15.10.2023") ?? Date.now,
            status: .revoked,
            serialNumber: .mockSerialNumber()
        )
    }

    public init() {}

    public func isE2EIdentityEnabled() -> Bool {
        return true
    }

    public func fetchCertificates() async throws -> [E2eIdentityCertificate] {
        [certificate]
    }

    public func shouldUpdateCertificate(for certificate: E2eIdentityCertificate) -> Bool {
        return false
    }
}
