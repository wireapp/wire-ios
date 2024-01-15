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

public final class MockValidE2eIdentityProvider: E2eIdentityProviding {

    public let certificate: E2eIdentityCertificate = .mockValid
    public let isE2EIdentityEnabled: Bool = false
    public let shouldUpdateCertificate = false

    public init() {}

    public func isE2EIdentityEnabled() async throws -> Bool {
        return isE2EIdentityEnabled
    }

    public func fetchCertificates(clientIds: [Data]) async throws -> [E2eIdentityCertificate] {
        [certificate]
    }

    public func fetchCertificates(userIds: [String]) async throws -> [String: [E2eIdentityCertificate]] {
        var result = [String: [E2eIdentityCertificate]]()
        userIds.forEach({ result[$0] = [certificate] })
        return result
    }

    public func shouldUpdateCertificate(for certificate: E2eIdentityCertificate) -> Bool {
        return shouldUpdateCertificate
    }
}
