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
import WireCoreCrypto

public final class MockExpiredE2eIdentityProvider: E2eIdentityProviding {

    public init() {}

    public func isE2EIdentityEnabled() async throws -> Bool {
        return true
    }

    public func fetchCertificates(clientIds: [Data]) async throws -> [E2eIdentityCertificate] {
        [.mockExpired]
    }

    public func fetchCertificates(userIds: [String]) async throws -> [String: [E2eIdentityCertificate]] {
        var result = [String: [E2eIdentityCertificate]]()
        userIds.forEach({ result[$0] = [E2eIdentityCertificate.mockExpired] })
        return result
    }

    public func shouldUpdateCertificate(for certificate: E2eIdentityCertificate) -> Bool {
        return true
    }
}

extension E2eIdentityCertificate {

    static let  dateFormatter = DateFormatter()

    static var mockRevoked: E2eIdentityCertificate {
        E2eIdentityCertificate(
            certificateDetails: .mockCertificate(),
            mlsThumbprint: "AB CD EF GH IJ KL MN OP QR ST UV WX",
            notValidBefore: dateFormatter.date(from: "15.10.2023") ?? Date.now,
            expiryDate: dateFormatter.date(from: "15.10.2023") ?? Date.now,
            certificateStatus: .revoked,
            serialNumber: .mockSerialNumber()
        )
    }

    static var mockValid: E2eIdentityCertificate {
        E2eIdentityCertificate(
            certificateDetails: .mockCertificate(),
            mlsThumbprint: "AB CD EF GH IJ KL MN OP QR ST UV WX",
            notValidBefore: dateFormatter.date(from: "15.09.2023") ?? Date.now,
            expiryDate: dateFormatter.date(from: "15.10.2024") ?? Date.now,
            certificateStatus: .valid,
            serialNumber: .mockSerialNumber()
        )
    }

    static var mockExpired: E2eIdentityCertificate {
        E2eIdentityCertificate(
            certificateDetails: .mockCertificate(),
            mlsThumbprint: "AB CD EF GH IJ KL MN OP QR ST UV WX",
            notValidBefore: dateFormatter.date(from: "15.09.2023") ?? Date.now,
            expiryDate: dateFormatter.date(from: "15.10.2023") ?? Date.now,
            certificateStatus: .expired,
            serialNumber: .mockSerialNumber()
        )
    }

}
